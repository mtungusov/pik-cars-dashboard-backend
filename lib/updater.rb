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
    connection.setAutoCommit(false)
    _trackers_state(connection)
    # _tracker_zone(connection)
  end

  def _trackers_state(connection)
    ids = _tracker_ids(connection)
    # get states from API
    states = ExtService::Navixy.tracker_states(ids)
    # generate only changed states
    changed_states = _changed_states(connection, states)
    # update ids with changed state
    begin
      changed_states.each do |item|
        Storage.update_trackers_state(connection, 'tracker_states', item)
      end
      connection.commit
    rescue => e
      connection.rollback
      puts e.to_s
    end
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
