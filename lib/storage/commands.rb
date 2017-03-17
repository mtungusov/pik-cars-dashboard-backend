module Storage::Commands
  module_function

  def upsert(connection, sql, values)
    pstmt = connection.prepareStatement(sql)
    _set_params(pstmt, values)
    pstmt.executeUpdate
  ensure
    pstmt.close unless pstmt.closed?
  end

  def select_ids(connection, sql)
    result = []
    stmt = connection.createStatement
    rs = stmt.executeQuery(sql)
    while rs.next
      result << rs.getLong('id')
    end
    return result
  ensure
    rs.close if (rs and !rs.closed?)
    stmt.close unless stmt.closed?
  end

  def select_by(connection, sql, values, field_name = 'id')
    result = []
    pstmt = connection.prepareStatement(sql)
    _set_params(pstmt, values)
    rs = pstmt.executeQuery
    while rs.next
      result << rs.getLong(field_name)
    end
    return result
  ensure
    rs.close if (rs and !rs.closed?)
    pstmt.close unless pstmt.closed?
  end

  def select_trackers_info(connection, sql)
    result = []
    stmt = connection.createStatement
    rs = stmt.executeQuery(sql)
    while rs.next
      result << _tracker_info(rs)
    end
    return result
  ensure
    rs.close if (rs and !rs.closed?)
    stmt.close unless stmt.closed?
  end

  def _tracker_info(rs)
    {
      id: rs.getLong('id'),
      label: rs.getString('label'),
      group: {
        id: rs.getLong('group_id'),
        title: rs.getString('group_title')
      },
      status: {
        label: rs.getString('status'),
        changed_at: rs.getLong('status_changed_at')
      },
      zone: {
        id: rs.getLong('zone_id'),
        label: rs.getString('zone_label'),
        changed_at: rs.getLong('zone_changed_at')
      }
    }
  end

  def _set_param(pstmt, index, value)
    case value.class
    when Fixnum
      pstmt.setLong(index, value)
    else
      pstmt.setString(index, value.to_s)
    end
  end

  def _set_params(pstmt, values)
    values.each_with_index do |item, index|
      _set_param(pstmt, index.next, item)
    end
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
