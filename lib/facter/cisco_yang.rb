require 'facter'
require File.expand_path('../../util/environment', __FILE__)
# require File.expand_path('../../util/platform', __FILE__)

Facter.add(:cisco_yang) do
  confine operatingsystem: [:ios_xr]

  setcode do
    hash = {}

    hash['configured_envs'] = Cisco::Environment.environment_names

    # don't do this, for now.  It's slow, so wait until we need it
    # Platform = Cisco::Platform
    # hash['system'] = Platform.system
    # hash['system_time'] = Platform.system_time
    # hash['host_name'] = Platform.host_name
    # hash['product_id'] = Platform.product_id

    hash
  end
end
