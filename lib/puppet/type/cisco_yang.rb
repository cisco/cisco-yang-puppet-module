require File.expand_path('../../property/yang_json.rb', __FILE__)

Puppet::Type.newtype(:cisco_yang) do
  @doc = "IOS-XR configuration management via YANG.

  ~~~puppet
  cisco_yang { '<title>':
    ..attributes..
  }
  ~~~
  `<title>` is the title of the yang resource.
  Example:
  ~~~puppet
    cisco_yang { 'blue vrf':
      ensure => present,
      target => '{\"Cisco-IOS-XR-infra-rsi-cfg:vrfs\": [null]}',
      source => '{\"Cisco-IOS-XR-infra-rsi-cfg:vrfs\": {
            \"vrf\":[
              {
                  \"vrf-name\":\"blue\",
                  \"vpn-id\":{
                    \"vpn-oui\":875,
                    \"vpn-index\":3
                  },
                  \"create\":[null]
              }
            ]
        }
      }',
    }
  ~~~
  ~~~puppet
    cisco_yang { '{\"Cisco-IOS-XR-infra-rsi-cfg:vrfs\": [null]}':
      ensure => present,
      source => '{\"Cisco-IOS-XR-infra-rsi-cfg:vrfs\": {
            \"vrf\":[
              {
                  \"vrf-name\":\"red\",
                  \"vpn-id\":{
                    \"vpn-oui\":875,
                    \"vpn-index\":22
                  },
                  \"create\":[null]
              }
            ]
        }
      }',
    }
  ~~~
  ~~~puppet
    cisco_yang {  '{\"Cisco-IOS-XR-infra-rsi-cfg:vrfs\": [null]}':
      ensure => absent,
  ~~~
  "

  ensurable

  newparam(:target, parent: YangJson) do
    isnamevar
    desc 'String containing the model path of the target node in YANG JSON '\
         'format, or a reference to a local file containing the model path.'
  end

  newparam(:mode) do
    desc 'Determines the mode to use when setting configuration via '\
         "ensure=>present.  If 'replace' is specified, the current "\
         'configuration will be replaced by the configuration in the '\
         "'source' property.  If 'merge' is specified, the configuration "\
         "in the 'source' property will be merged into the current "\
         "configuration. Valid values are 'replace' and 'merge' (which "\
         'is the default.'
    munge(&:to_sym)
    newvalues(:replace, :merge)
  end

  newparam(:force) do
    desc 'If :true is specified, then the specified value of the source '\
         'property is set on the device, regardless of the current value. '\
         'If :false is specified (or no value is specified), the default '\
         'behavior is to only set the configuration if it is different '\
         'from the running configuration.'
    newvalues(:true, :false)
    munge do |force|
      force == true || force == 'true' || force == :true
    end
  end

  newproperty(:source, parent: YangJson) do
    desc 'The model data in YANG JSON format, or a reference to a local file '\
         'containing the model data.  This property is only used when '\
         'ensure=>present is used.'
  end

  #
  # VALIDATIONS
  #
  validate do
    fail("The 'target' parameter must be set in the manifest.") if self[:target].nil?
    if self[:source].nil? && self[:ensure] == :present
      self[:source] = self[:target]
    end
  end
end
