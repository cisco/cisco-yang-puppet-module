# June 2016, Chris Frisz
#
# Copyright (c) 2015-2016 Cisco and/or its affiliates.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require_relative '../../yang'
require 'rexml/document'

module Cisco
  # Cisco module
  module Netconf
    # Netconf module performs conversion of REXML documents into
    # a format with types that are comparable to the output of
    # JSON.parse
    NC_BASE_1_0_NS = 'urn:ietf:params:xml:ns:netconf:base:1.0'

    def self.empty?(nc)
      !nc || nc.empty?
    end

    def self.convert_xml(xml)
      fail "#{xml} is not an XML document" unless xml.is_a?(REXML::Document)
      convert_xml_node(xml.root)
    end

    def self.convert_xml_node(node)
      fail "#{node} is not an XML node" unless node.is_a?(REXML::Element)
      out_hash = {}
      children = node.to_a
      if children.length == 1 && node.has_text?
        out_hash[node.name] = [children[0].value.strip]
      elsif !node.has_elements?
        out_hash[node.name] = []
      else
        out_hash[node.name] = children.map { |child| convert_xml_node(child) }
      end
      # Looking for operation=delete in the netconf:base:1.0 namespace
      if node.attributes.get_attribute_ns(NC_BASE_1_0_NS,
                                          'operation').to_s == 'delete'
        out_hash[:delete] = :delete
      end
      out_hash
    end

    def self.convert_rexml_from_string(input)
      if empty?(input)
        out = {}
      else
        if @iw.nil?
          @iw = {}
          @iw[:ignore_whitespace_nodes] = :all
        end
        out = convert_xml(REXML::Document.new(input, @iw))
      end
      out
    end

    def self.insync_for_merge(target, current)
      !Yang.needs_something?(:merge,
                             convert_rexml_from_string(target),
                             convert_rexml_from_string(current))
    end

    def self.insync_for_replace(target, current)
      !Yang.needs_something?(:replace,
                             convert_rexml_from_string(target),
                             convert_rexml_from_string(current))
    end
  end # Netconf
end # Cisco
