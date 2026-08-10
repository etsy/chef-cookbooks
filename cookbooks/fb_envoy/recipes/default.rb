#
# Cookbook:: fb_envoy
# Recipe:: default
#
# Copyright (c) 2026-present, Etsy, Inc.
# All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

unless node.debian? || node.ubuntu?
  fail 'fb_envoy: Used on unsupported platform!'
end

package 'envoy' do
  only_if { node['fb_envoy']['manage_packages'] }
  action :upgrade
  notifies :restart, 'service[envoy]'
end

directory '/etc/envoy' do
  owner node.root_user
  group node.root_group
  mode '0755'
end

template '/etc/envoy/envoy.yaml' do
  owner node.root_user
  group node.root_group
  mode '0644'
  notifies :restart, 'service[envoy]'
end

cookbook_file '/etc/systemd/system/envoy.service' do
  source 'envoy.service'
  owner node.root_user
  group node.root_group
  mode '0644'
  notifies :run, 'fb_systemd_reload[system instance]', :immediately
  notifies :restart, 'service[envoy]'
end

service 'envoy' do
  only_if { node['fb_envoy']['enable'] }
  action [:enable, :start]
end

service 'disable envoy' do
  not_if { node['fb_envoy']['enable'] }
  service_name 'envoy'
  action [:stop, :disable]
end
