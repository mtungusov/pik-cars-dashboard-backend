module Storage
  class Sqlite
    def initialize(db_file: '')
      if db_file.empty?
        @url = 'jdbc:sqlite::memory'
        _create_db
      else
        @url = "jdbc:sqlite:#{db_file}"
      end
    end

    def open
      _connection
    end

    def close(connection)
      connection.close if (connection and !connection.closed?)
    end

    def _connection
      org.sqlite.JDBC.create_connection @url, java.util.Properties.new
    end

    def _create_db
      db_file = File.join(Settings::CUR_DIR, ':memory')
      File.delete(db_file) if File.exist?(db_file)
      conn = open
      stmt = conn.createStatement
      sql = 'CREATE TABLE trackers (
              id INTEGER PRIMARY KEY,
              label TEXT,
              group_id INTEGER
            );'
      stmt.execute(sql)
      sql = 'CREATE TABLE groups (
              id INTEGER PRIMARY KEY,
              title TEXT
            );'
      stmt.execute(sql)
      sql = 'CREATE TABLE rules (
              id INTEGER PRIMARY KEY,
              type TEXT,
              name TEXT,
              zone_id INTEGER
            );'
      stmt.execute(sql)
      sql = 'CREATE TABLE zones (
              id INTEGER PRIMARY KEY,
              label TEXT
            );'
      stmt.execute(sql)
      sql = 'CREATE TABLE tracker_states (
              id INTEGER PRIMARY KEY,
              movement_status TEXT,
              changed_at INTEGER,
              connection_status TEXT
            );'
      stmt.execute(sql)
      sql = 'CREATE TABLE tracker_rule (
              tracker_id INTEGER PRIMARY KEY,
              rule_id INTEGER,
              event_type TEXT,
              changed_at INTEGER
            )'
      stmt.execute(sql)
      sql = 'CREATE TABLE history_tracker (
              id INTEGER PRIMARY KEY,
              event TEXT,
              time TEXT,
              tracker_id INTEGER,
              rule_id INTEGER,
              message TEXT
            )'
      stmt.execute(sql)
      sql = 'CREATE INDEX idx_history_tracker_tracker_id
              ON history_tracker(tracker_id)'
      stmt.execute(sql)
      sql = 'CREATE INDEX idx_history_tracker_time
              ON history_tracker(time)'
      stmt.execute(sql)
      sql = "CREATE VIEW trackers_info AS
            SELECT trackers.id AS id, trackers.label AS label,
              groups.id AS group_id, groups.title AS group_title,
              tracker_states.movement_status AS status, tracker_states.changed_at AS status_changed_at,
              tracker_states.connection_status AS status_connection,
              zones.id AS zone_id, zones.label AS zone_label, tracker_rule.changed_at AS zone_changed_at,
              tracker_rule.event_type AS event_type,
              CAST(strftime('%s', datetime('now', strftime('-%s seconds', datetime(tracker_rule.changed_at, 'unixepoch')))) AS INTEGER) as zone_time_diff
            FROM trackers LEFT JOIN groups ON trackers.group_id = groups.id
              LEFT JOIN tracker_states ON trackers.id = tracker_states.id
              LEFT JOIN tracker_rule ON trackers.id = tracker_rule.tracker_id
              LEFT JOIN rules ON rules.id = tracker_rule.rule_id
              LEFT JOIN zones ON rules.zone_id = zones.id
            ORDER BY (CASE coalesce(zone_label, 'empty')
                      WHEN 'empty' THEN 2
                      ELSE 1
                      END ), event_type, zone_label, zone_time_diff DESC"
      stmt.execute(sql)
      stmt.close unless stmt.closed?
      conn.close unless conn.closed?
    end
  end

  module_function

  def client(params = {})
    @@sqlite_client ||= Sqlite.new(db_file: params[:db_file])
  end
end
