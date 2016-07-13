require_relative 'yang_netconf_property'

# This subclass of {YangProperty} manages YANG XML Netconf content.
#
class YangNetconf < YangNetconfProperty

  # Determine if the specified value is inline YANG or a file path
  def inline_yang?(yang_or_file)
    !!/^</.match(yang_or_file)
  end

end
