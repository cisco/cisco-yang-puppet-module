require 'puppet/util/feature'

# custom feature for node_util
path = File.expand_path('../../../util/node_util', __FILE__)
Puppet.features.add(:node_util, libs: [path])
