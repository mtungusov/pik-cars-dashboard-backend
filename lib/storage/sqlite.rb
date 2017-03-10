module Storage
  class Sqlite
    attr_reader :connection

    def initialize(db_file: '')
      @url = db_file.empty? ? 'jdbc:sqlite::memory' : "jdbc:sqlite:#{db_file}"
      @connection = _connection
    end

    def close
      @connection.close if (@connection and !@connection.closed?)
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


# ### SELECT
# sql = 'SELECT id, label FROM zones'
#
# stmt = conn.createStatement
# rs = stmt.executeQuery(sql)
#
# while rs.next
#   puts "id: #{rs.getLong('id')}, label: #{rs.getString('label')}"
# end
# rs.close unless rs.closed?
# stmt.close unless stmt.closed?

# ### UPDATE
# sql = 'INSERT or REPLACE INTO zones (id, label) VALUES (?, ?)'
#
# pstmt = conn.prepareStatement(sql)
# pstmt.setLong(1, 111)
# pstmt.setString(2, 'ZoneTest')
# pstmt.executeUpdate
#
# pstmt.close unless pstmt.closed?
#
