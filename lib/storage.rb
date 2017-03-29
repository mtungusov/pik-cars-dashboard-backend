module Storage; end

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

  def select_zone_by_rule(connection, rule_id)
    sql = "SELECT zone_id FROM rules WHERE id = ? LIMIT 1"
    Storage::Commands.select_by(connection, sql, [rule_id], 'zone_id')
  end

  def update_trackers_state(connection, table, array_value)
    state = array_value.first
    items = array_value.last
    # changed_at = Time.now.to_i
    sql = "INSERT or REPLACE INTO #{table} (id, movement_status, changed_at, connection_status) VALUES (?, ?, ?, ?)"
    items.each do |(id, changed_at, connection_status)|
      Storage::Commands.upsert(connection, sql, [id, state, changed_at, connection_status])
    end
  end

  def delete_by(connection, table, item_key)
    sql = "DELETE FROM #{table} WHERE tracker_id = ?"
    Storage::Commands.upsert(connection, sql, [item_key])
  end

  def trackers_info(connection, ids=[])
    param_ids = ids.empty? ? select_ids($conn_read_api, 'trackers_info') : ids
    sql = "SELECT * FROM trackers_info WHERE id IN (#{param_ids.join(',')})"
    Storage::Commands.select_trackers_info(connection, sql)
  end

  def zones(connection)
    sql = "SELECT * FROM zones ORDER BY label"
    fields = [[:id, :long], [:label, :string]]
    Storage::Commands.select_all(connection, sql, fields)
  end
end
