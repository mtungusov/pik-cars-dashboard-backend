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
    sql = "SELECT id from #{table}"
    Storage::Commands.select_ids(connection, sql)
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
