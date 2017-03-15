module Updater
  module_function

  def update_nsi(connection)
    connection.setAutoCommit(false)
    _groups(connection)
    _rules(connection)
    _zones(connection)
    _trackers(connection)
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
    item = {
      'tracker_id' => event['tracker_id'],
      'zone_id' => _zone_by_rule(connection, event['rule_id']),
      'changed_at' => Time.now.to_i
    }
    Storage.upsert_into(connection, 'tracker_zone', item)
  end

  def _zone_by_rule(connection, rule_id)
    Storage.select_zone_by_rule(connection, rule_id).first
  end

  def _changed_states(connection, new_states)
    result = {}
    new_states.each do |state, ids|
      old_ids = Storage.select_trackers_by_state(connection, state)
      changed_ids = ids - old_ids
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
