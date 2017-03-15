module Storage;

end

require_relative 'storage/sqlite'
require_relative 'storage/commands'

module Storage
  module_function

  def upsert_into(connection, table, hash_values)
    fields = hash_values.keys.join(',')
    values = hash_values.values.map(&->(v){'?'}).join(',')
    sql = "INSERT or REPLACE INTO #{table} (#{fields}) VALUES (#{values})"
    Storage::Commands.upsert(connection, sql, hash_values.values)
  end

  def select_ids(connection, table)
    sql = "SELECT id FROM #{table}"
    Storage::Commands.select_ids(connection, sql)
  end

  def select_trackers_by_state(connection, state)
    sql = "SELECT id FROM tracker_states WHERE movement_status = ?"
    Storage::Commands.select_by(connection, sql, [state])
  end

  def update_trackers_state(connection, table, array_value)
    state = array_value.first
    ids = array_value.last
    changed_at = Time.now.to_i
    sql = "INSERT or REPLACE INTO #{table} (id, movement_status, changed_at) VALUES (?, ?, ?)"
    ids.each { |id| Storage::Commands.upsert(connection, sql, [id, state, changed_at]) }
  end

  # Save NSI data
  def save_nsi
    # groups
    # rules
    # zones
    # trackers
  end

  # Save Work data
  def save
    # tracker states
    # tracker in Zone
    # Last Time Events check -> Atom(DateTime)
  end
end
