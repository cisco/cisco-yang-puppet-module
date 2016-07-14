require File.expand_path('../../property/yang_netconf.rb', __FILE__)

Puppet::Type.newtype(:cisco_yang_netconf) do
  @doc = "IOS-XR configuration management via YANG Netconf.

  ~~~puppet
  cisco_yang_netconf { '<title>':
    ..attributes..
  }
  ~~~
  `<title>` is the title of the yang resource.
  This example demonstrates changing the VRF table to contain only the vrf with name \"blue\".
  ~~~puppet
    cisco_yang_netconf { 'blue vrf':
      target => '<vrfs xmlns=\"http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg\"/>',
      source => '<vrfs xmlns=\"http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg\">
                   <vrf>
                     <vrf-name>blue</vrf-name>
                     <create/>
                     <vpn-id>
                       <vpn-oui>875</vpn-oui>
                       <vpn-index>3</vpn-index>
                     </vpn-id>
                   </vrf>
                </vrfs>',
      mode => replace
    }
  ~~~
  This example demonstrates inserting the vrf with name \"blue\" into the table, with the values provided.
  ~~~puppet
    cisco_yang_netconf { '<vrfs xmlns=\"http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg\"/>':
      source => '<vrfs xmlns=\"http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg\">
                   <vrf>
                     <vrf-name>blue</vrf-name>
                     <create/>
                     <vpn-id>
                       <vpn-oui>875</vpn-oui>
                       <vpn-index>3</vpn-index>
                     </vpn-id>
                   </vrf>
                </vrfs>'
    }
  ~~~
  This example demonstrates removing the vrf with name \"red\" from the vrf table.
  ~~~puppet
    cisco_yang_netconf { '<vrfs xmlns=\"http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg\"/>':
      source => '<vrfs xmlns=\"http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg\">
                   <vrf xmlns:xc=\"urn:ietf:params:xml:ns:netconf:base:1.0\" xc:operation=\"delete\">
                     <vrf-name>red</vrf-name>
                     <create/>
                   </vrf>
                 </vrfs>'
    }
  ~~~
  "

  newparam(:target, :parent => YangNetconf) do
    isnamevar
    desc 'XML formatted string or file location of an XML formatted string ' \
         'that contains the filter text used in a netconf query.'
  end

  newparam(:mode) do
    desc 'Determines the mode to use when setting configuration.'\
         "If 'replace' is specified, the current "\
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

  newproperty(:source, :parent => YangNetconf) do
    desc 'The model data in YANG XML Netconf format, or a reference to a local file '\
         'containing the model data.'
  end

  #
  # VALIDATIONS
  #
  validate do
    fail("The 'target' parameter must be set in the manifest.") if self[:target].nil?
    fail("The 'source' property must be set in the manifest.") if self[:source].nil?
  end
end
