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

  def select_history_tracker(connection, sql, values)
    result = []
    pstmt = connection.prepareStatement(sql)
    _set_params(pstmt, values)
    rs = pstmt.executeQuery
    while rs.next
      result << _history_tracker(rs)
    end
    return result
  ensure
    rs.close if (rs and !rs.closed?)
    pstmt.close unless pstmt.closed?
  end

  def _history_tracker(rs)
    {
      event: rs.getString('event'),
      time: rs.getString('time'),
      tracker_id: rs.getLong('tracker_id'),
      rule_id: rs.getLong('rule_id')
    }
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

  def select_all(connection, sql, fields)
    # fields -> [[:name, :type], ...]
    result = []
    stmt = connection.createStatement
    rs = stmt.executeQuery(sql)
    while rs.next
      result << _process_fields(rs, fields)
    end
    return result
  ensure
    rs.close if (rs and !rs.closed?)
    stmt.close unless stmt.closed?
  end

  def _process_fields(rs, fields)
    # fields -> [[:name, :type], ...]
    fields.inject({}) do |acc, (field_name, field_type)|
      acc[field_name] = case field_type
                        when :long
                          rs.getLong(field_name.to_s)
                        else
                          rs.getString(field_name.to_s)
      end
      acc
    end
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
        changed_at: rs.getLong('status_changed_at'),
        connection: rs.getString('status_connection')
      },
      zone: {
        id: rs.getLong('zone_id'),
        label: rs.getString('zone_label'),
        event_type: rs.getString('event_type'),
        changed_at: rs.getLong('zone_changed_at'),
        time_diff: rs.getLong('zone_time_diff')
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
