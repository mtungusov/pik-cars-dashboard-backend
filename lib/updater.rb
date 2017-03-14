module Updater
  module_function

  def update_nsi(connection)
    _groups(connection)
    # rules
    # zones
    # trackers
  end

  def _groups(connection)
    ExtService::Navixy.groups.each { |item| Storage.upsert_into(connection, 'groups', item) }
  end
end
