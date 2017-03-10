module Storage; end

require_relative 'storage/sqlite'

module Storage
  module_function

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
