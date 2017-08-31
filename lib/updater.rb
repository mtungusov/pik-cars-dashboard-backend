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
    _update_trackers_info(connection, ids)
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
    begin
      connection.setAutoCommit(false)
      tracker_ids.each do |tracker_id|
        _tracker_events(connection, tracker_id).each do |event|
          _process_event(connection, event)
        end
      end
      connection.commit
    rescue => e
      connection.rollback
      puts e.to_s
    end
  end

  def _tracker_events(connection, tracker_id)
    from = _from_time_by_tracker(connection, tracker_id)
    to = Time.now.strftime(ExtService::Navixy::TIME_FMT)
    ExtService::Navixy.events_by(tracker_id, from, to)
  end

  def _from_time_by_tracker(connection, tracker_id)
    history = Storage.select_last_history_tracker(connection, tracker_id).first
    return history[:time] if history
    (Time.now - Settings::ALL.time_shift_first_events_update).strftime(ExtService::Navixy::TIME_FMT)
  end

  def _process_event(connection, event)
    return unless event
    _add_history_tracker(connection, event)
  end

  def _add_history_tracker(connection, event)
    item = {
      'id' => event['id'],
      'event' => event['event'],
      'time' => event['time'],
      'tracker_id' => event['tracker_id'],
      'rule_id' => event['rule_id'],
      'message' => event['message']
    }
    Storage.upsert_into(connection, 'history_tracker', item)
  end

  def _update_trackers_info(connection, tracker_ids)
    begin
      connection.setAutoCommit(false)
      tracker_ids.each do |tracker_id|
        last_event = Storage.select_last_history_tracker(connection, tracker_id).first
        _add_tracker_rule(connection, last_event) if last_event
      end
      connection.commit
    rescue => e
      connection.rollback
      puts e.to_s
    end
  end

  def _tracker_rule_parent_id(event)
    return unless event['event_type'] == 'outzone'
    _get_rule_parent_id(event['rule_id'])
  end

  RULE_TREE = { 206059 => 206049, 214848 => 206049 }.freeze
  def _get_rule_parent_id(rule_id)
    RULE_TREE[rule_id]
  end

  def _add_tracker_rule(connection, event)
    Storage.delete_by(connection, 'tracker_rule', event[:tracker_id])
    item = _tracker_rule(event)
    Storage.upsert_into(connection, 'tracker_rule', item)
  end

  def _tracker_rule(event)
    changed_at = parse_change_at(event[:time])
    item = {
      'tracker_id' => event[:tracker_id],
      'rule_id' => event[:rule_id],
      'event_type' => event[:event],
      'changed_at' => changed_at
    }
    # process nested zones
    _parent_rule_id = _tracker_rule_parent_id(item)
    return item unless _parent_rule_id
    item.merge('rule_id' => _parent_rule_id, 'event_type' => 'inzone')
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
