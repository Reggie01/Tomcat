# Author:: Bryan W. Berry (<bryan.berry@gmail.com>)
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Author:: Joshua Timberman (<joshua@opscode.com>)
#
# Cookbook Name:: java
# Recipe:: openjdk
#
# Copyright 2010-2013, Opscode, Inc.
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

include_recipe "apt"

package 'openjdk-6-jre-headless'

unless node.recipe?('java::default')
  Chef::Log.warn("Using java::default instead is recommended.")

  # Even if this recipe is included by itself, a safety check is nice...
  [ node['java']['openjdk_packages'], node['java']['java_home'] ].each do |v|
    if v.nil? or v.empty?
      include_recipe "java::set_attributes_from_version"
    end
  end
end

jdk = Opscode::OpenJDK.new(node)

if platform_requires_license_acceptance?
  file "/opt/local/.dlj_license_accepted" do
    owner "root"
    group "root"
    mode "0400"
    action :create
    only_if { node['java']['accept_license_agreement'] }
  end
end

node['java']['openjdk_packages'].each do |pkg|
  package pkg
end

if platform_family?('debian', 'rhel', 'fedora')
  java_alternatives 'set-java-alternatives' do
    java_location jdk.java_home
    default node['java']['set_default']
    priority jdk.alternatives_priority
    case node['java']['jdk_version'].to_s
    when "6"
      bin_cmds node['java']['jdk']['6']['bin_cmds']
    when "7"
      bin_cmds node['java']['jdk']['7']['bin_cmds']
    end
    action :set
  end
end

if platform_family?('debian')
  link '/usr/lib/jvm/default-java' do
    to node['java']['java_home']
    not_if { node['java']['java_home'] == '/usr/lib/jvm/default-java' }
  end
end

# We must include this recipe AFTER updating the alternatives or else JAVA_HOME
# will not point to the correct java.
include_recipe 'java::set_java_home'
