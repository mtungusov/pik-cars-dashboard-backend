module Storage::Commands
  module_function

  def upsert(connection, sql, values)
    pstmt = connection.prepareStatement(sql)
    values.each_with_index do |item, index|
      item.is_a?(Fixnum) ? pstmt.setLong(index.next, item) : pstmt.setString(index.next, item.to_s)
    end
    pstmt.executeUpdate
  ensure
    pstmt.close unless pstmt.closed?
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