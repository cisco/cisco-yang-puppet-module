require 'util/node_util'
require 'rubygems'


Puppet::Type.type(:cisco_yang_netconf).provide(:cisco) do
  desc "IOS-XR configuration management via YANG."
  defaultfor operatingsystem: [:ios_xr]

  def initialize(value={})
    super(value)
    activate
    @node = Cisco::Node.instance
  end

  def create
    setyang(@resource[:source])
  end

  def destroy
    @source = nil   # clear the cached value
    src = @resource[:source] || @resource[:target]
    debug '**************** REMOVING CONFIG ****************'
    debug '**************** Delete is not available. ****************'
    debug src
    #@node.delete_yang(src)
    debug '**************** REMOVE SUCCESSFUL ****************'
  end

  def resource_mode
    @resource && @resource[:mode] == :replace ? :replace : :merge
  end

  def resource_force
    @resource && @resource[:force] ? true : false
  end

  # Return the current source YANG
  def source
    return @source if @source   # return the cached value, if it's there

    if resource_force
      # If instructed to force the configuration, then there is no reason
      # to query the current configuration; just return :unknown.
      source_yang = :unknown
    else
      source_yang = @node.get_netconf(@resource[:target])

      debug '**************** CURRENT CONFIG ****************'
      debug source_yang

      # somewhere someone reads source_yang as a string. This is a workaround.
      #source_yang = :absent if !source_yang || source_yang.empty?
    end

    @source = source_yang
  end

  # Set the source YANG.
  def source=(value)
    setyang(value)
  end

  def setyang(value)
    @source = nil   # clear the cached value
    debug '**************** SETTING CONFIG ****************'
    debug "Value: #{value}"
    debug "Resource Mode #{resource_mode}"
    if resource_mode == :replace
      @node.replace_netconf(value)
    else
      @node.merge_netconf(value)
    end
    debug '**************** SET SUCCESSFUL ****************'
  end

  def self.instances
    []
  end

  def activate
    @active = true
  end

  def active?
    !!@active
  end

end
