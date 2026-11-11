#
# Cookbook Name:: fb_sysctl
# Recipe:: default
#
# Copyright (c) 2016-present, Facebook, Inc.
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

template '/etc/sysctl.conf' do
  mode '0644'
  owner node.root_user
  group node.root_group
  source 'sysctl.conf.erb'
end

# Debian and Ubuntu used to ship /etc/sysctl.d/99-sysctl.conf, a symlink to
# /etc/sysctl.conf, because systemd-sysctl no longer reads /etc/sysctl.conf
# natively. Newer releases (e.g. Ubuntu 26.04, procps >= 2:4.0.4-5) dropped it,
# so without it nothing applies /etc/sysctl.conf at boot. Provide it ourselves.
# The target matches the one procps shipped, so this is a no-op where the
# package already provides the link.
link '/etc/sysctl.d/99-sysctl.conf' do
  to '../sysctl.conf'
  only_if { node.linux? && !node.container? && ::Dir.exist?('/etc/sysctl.d') }
end

fb_sysctl 'doit' do
  not_if { node.container? }
  action :apply
end
