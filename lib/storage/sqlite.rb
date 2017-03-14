module Storage
  class Sqlite
    def initialize(db_file: '')
      @url = db_file.empty? ? 'jdbc:sqlite::memory' : "jdbc:sqlite:#{db_file}"
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
  end

  module_function

  def client(params = {})
    @@sqlite_client ||= Sqlite.new(db_file: params[:db_file])
  end
end
