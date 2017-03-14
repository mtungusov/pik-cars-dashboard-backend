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
