require 'puppet/node_utils/feature'

# custom feature for json
Puppet.features.add(:json, libs: ['json'])
