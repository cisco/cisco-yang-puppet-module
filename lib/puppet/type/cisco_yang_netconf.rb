require File.expand_path('../../property/yang_netconf.rb', __FILE__)

Puppet::Type.newtype(:cisco_yang_netconf) do
  @doc = "IOS-XR configuration management via YANG."


  newparam(:target, :parent => YangNetconf) do
    isnamevar
    desc 'String conntaining the model path of the target node in YANG JSON '\
         'format, or a reference to a local file containing the model path.'
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
    desc 'The model data in YANG JSON format, or a reference to a local file '\
         'containing the model data.'
  end

  #
  # VALIDATIONS
  #
  validate do
    fail("The 'target' parameter must be set in the manifest.") if self[:target].nil?
    if self[:source].nil?
      self[:source] = self[:target]
      puts "NOTE: using target as source"
    end
  end
end
