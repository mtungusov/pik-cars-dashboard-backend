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
    _trackers_events(connection, ids)
  end

  def _trackers_state(connection, tracker_ids)
    # get states from API
    states = ExtService::Navixy.tracker_states(tracker_ids)
    # { state1:[ [id, changed_at, connection_status],... ], ... }
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

  def _trackers_events(connection, tracker_ids)
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
    _add_tracker_rule(connection, event)
    _process_nested_tracker_rule(connection, event)
    # case event['event']
    # when 'inzone'
    #   _add_tracker_zone_in(connection, event)
    # when 'outzone'
    #   _add_tracker_zone_out(connection, event)
    # end
  end

  def _tracker_rule_parent_id(event)
    return unless event['event'] == 'outzone'
    _get_rule_parent_id(event['rule_id'])
  end

  RULE_TREE = { 162499 => 162723 }.freeze
  def _get_rule_parent_id(rule_id)
    RULE_TREE[rule_id]
  end

  # def _del_tracker_zone(connection, event)
  #   Storage.delete_by(connection, 'tracker_rule', event['tracker_id'])
  # end

  def _add_tracker_rule(connection, event)
    Storage.delete_by(connection, 'tracker_rule', event['tracker_id'])
    changed_at = parse_change_at(event['time'])
    item = {
      'tracker_id' => event['tracker_id'],
      'rule_id' => event['rule_id'],
      'event_type' => event['event'],
      'changed_at' => changed_at
    }
    Storage.upsert_into(connection, 'tracker_rule', item)
  end

  def _process_nested_tracker_rule(connection, event)
    _parent_rule_id = _tracker_rule_parent_id(event)
    return unless _parent_rule_id
    _event = { 'rule_id' => _parent_rule_id, 'event' => 'inzone' }
    _add_tracker_rule(connection, event.merge(_event))
  end

  # def _add_tracker_zone_out(connection, event)
  #   Storage.delete_by(connection, 'tracker_rule', event['tracker_id'])
  #   changed_at = parse_change_at(event['time'])
  #   item = {
  #     'tracker_id' => event['tracker_id'],
  #     'rule_id' => event['rule_id'],
  #     'event_type' => 'outzone',
  #     'changed_at' => changed_at
  #   }
  #   Storage.upsert_into(connection, 'tracker_rule', item)
  # end

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
    # new_states = { state1:[ [id, changed_at, connection_status],... ], ... }
    result = {}
    new_states.each do |state, items|
      old_ids = Storage.select_trackers_by_state(connection, state)
      changed_ids = items.inject([]) do |acc, (id, changed_at, connection_status)|
        acc << [id, parse_change_at(changed_at), connection_status] unless old_ids.include?(id)
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
