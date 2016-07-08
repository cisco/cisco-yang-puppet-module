require 'puppet/node/feature'

# custom feature for json
Puppet.features.add(:json, libs: ['json'])
