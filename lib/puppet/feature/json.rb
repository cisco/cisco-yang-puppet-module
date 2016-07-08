require 'puppet/util/feature'

# custom feature for json
Puppet.features.add(:json, libs: ['json'])
