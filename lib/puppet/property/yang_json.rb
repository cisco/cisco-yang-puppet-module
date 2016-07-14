require_relative 'yang_property'

# This subclass of {YangProperty} manages YANG JSON content.
#
class YangJson < YangProperty
  # Determine if the specified value is inline YANG or a file path
  def inline_yang?(yang_or_file)
    !/^{/.match(yang_or_file).nil?
  end
end
