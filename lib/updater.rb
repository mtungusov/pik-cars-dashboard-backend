module Updater
  module_function

  def update_nsi(connection)
    connection.setAutoCommit(false)
    _trackers(connection)
    _groups(connection)
    _rules(connection)
    _zones(connection)
    connection.commit
  rescue => e
    connection.rollback
    puts e.to_s
  end

  def update_live(connection)
    ids = _tracker_ids(connection)
    _trackers_state(connection, ids)
    _tracker_zone(connection, ids)
  end

  def _trackers_state(connection, tracker_ids)
    # get states from API
    states = ExtService::Navixy.tracker_states(tracker_ids)
    # { state1:[ [id, changed_at],... ], ... }
    #
    # generate only changed states
    changed_states = _changed_states(connection, states)
    # update ids with changed state
    begin
      connection.setAutoCommit(false)
      changed_states.each do |item|
        Storage.update_trackers_state(connection, 'tracker_states', item)
      end
      connection.commit
    rescue => e
      connection.rollback
      puts e.to_s
    end
  end

  def _tracker_zone(connection, tracker_ids)
    events = ExtService::Navixy.events(tracker_ids)
    begin
      connection.setAutoCommit(false)
      events.each { |event| _process_event(connection, event) }
      connection.commit
    rescue => e
      connection.rollback
      puts e.to_s
    end
  end

  def _process_event(connection, event)
    case event['event']
    when 'inzone'
      _add_tracker_zone(connection, event)
    when 'outzone'
      _del_tracker_zone(connection, event)
    end
  end

  def _del_tracker_zone(connection, event)
    Storage.delete_by(connection, 'tracker_zone', event['tracker_id'])
  end

  def _add_tracker_zone(connection, event)
    changed_at = parse_change_at(event['time'])
    item = {
      'tracker_id' => event['tracker_id'],
      'zone_id' => _zone_by_rule(connection, event['rule_id']),
      'changed_at' => changed_at
    }
    Storage.upsert_into(connection, 'tracker_zone', item)
  end

  def parse_change_at(time_str)
    begin
      r = Time.parse(time_str).to_i
    rescue
      r = Time.now.to_i
    end
    r
  end

  def _zone_by_rule(connection, rule_id)
    Storage.select_zone_by_rule(connection, rule_id).first
  end

  def _changed_states(connection, new_states)
    # new_states = { state1:[ [id, changed_at],... ], ... }
    result = {}
    new_states.each do |state, items|
      old_ids = Storage.select_trackers_by_state(connection, state)
      changed_ids = items.inject([]) do |acc, (id, changed_at)|
        acc << [id, parse_change_at(changed_at)] unless old_ids.include?(id)
        acc
      end
      result[state] = changed_ids unless changed_ids.empty?
    end
    result
  end

  def _tracker_ids(connection)
    # code here
    Storage.select_ids(connection, 'trackers')
  end

  def _groups(connection)
    ExtService::Navixy.groups.each { |item| Storage.upsert_into(connection, 'groups', item) }
  end

  def _rules(connection)
    ExtService::Navixy.rules.each { |item| Storage.upsert_into(connection, 'rules', item) }
  end

  def _zones(connection)
    ExtService::Navixy.zones.each { |item| Storage.upsert_into(connection, 'zones', item) }
  end

  def _trackers(connection)
    ExtService::Navixy.trackers.each { |item| Storage.upsert_into(connection, 'trackers', item) }
  end
end
