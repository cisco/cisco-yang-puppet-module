require 'puppet/util/feature'

# custom feature for cisco_node_utils
Puppet.features.add(:cisco_node_utils, libs: ['cisco_node_utils'])
