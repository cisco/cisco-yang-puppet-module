require 'puppet/property'
require_relative '../../util/node_util'

# This subclass of {Puppet::Property} manages YANG content.
#
class YangProperty < Puppet::Property

  # Determine if the specified value is inline YANG or a file path
  def inline_yang?(yang_or_file)
    false
  end

  def yang_content(yang_or_file)
    return '' if yang_or_file.nil?

    # If it's not inline YANG, then assume it's a file, so read it in.
    if !inline_yang?(yang_or_file)
#          begin
        content = File.read(yang_or_file)
        debug "-----> read YANG from file #{yang_or_file}:"
        debug content
#          rescue Exception => e
#            puts "**************** ERROR DETECTED WHILE READING YANG FILE #{yang_or_file} ****************"
#            puts e.message
#            content = nil
#          end
      content
    else
      debug "-----> value is inline YANG: #{yang_or_file}"
      yang_or_file
    end
  end

  def should
    return @should_yang if @should_yang

    result = super

    # need better way to determine life-cycle stage of provider
    if provider && provider.respond_to?(:active?) && provider.active?
      @should_yang = result = yang_content(result)
    end

    result
  end

  # Determine if the "is" value is the same as the "should" value
  # (has the value of this property changed?)
  def insync?(is)
    replace = @resource && @resource[:mode] == :replace

    should_yang = should

    if is == :unknown
      # if the current config is unknown, assume configs are not in-sync
      insync = false
    else
      insync = replace ?
          Cisco::Yang.insync_for_replace?(should_yang, is) :
          Cisco::Yang.insync_for_merge?(should_yang, is)
    end

    if insync
      debug '**************** IDEMPOTENT -- NO CHANGES DETECTED ****************'
    elsif
      debug '**************** IS vs SHOULD CHANGES DETECTED ****************'
    end

    insync
  end
end
