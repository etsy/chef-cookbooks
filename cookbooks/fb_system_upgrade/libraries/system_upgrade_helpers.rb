# Copyright (c) 2021-present, Facebook, Inc.
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

module FB
  class SystemUpgrade
    extend Chef::Mixin::Which

    def self._get_base_command(node)
      package_manager = node.default_package_manager
      unless ['yum', 'dnf', 'apt'].include?(package_manager)
        fail "fb_system_upgrade: default package manager #{package_manager} " +
             'is not supported'
      end
      if package_manager == 'apt'
        package_manager = 'apt-get'
      end

      bin = which(package_manager)
      wrapper = node['fb_system_upgrade']['wrapper']
      if wrapper
        bin = "#{wrapper} #{bin}"
      end
      config = node['fb_system_upgrade']['config']
      if config
        bin = "#{bin} -c #{config}"
      end

      repos_cmd = ''
      repos = node['fb_system_upgrade']['repos']
      unless repos.empty?
        repos_cmd = "--disablerepo=* --enablerepo=#{repos.join(',')}"
      end

      cmd = "#{bin} #{repos_cmd} -y"

      cmd
    end

    def self.get_swap_command(node, old, new)
      base_cmd = FB::SystemUpgrade._get_base_command(node)

      cmd = "#{base_cmd} swap #{old} #{new}"

      cmd
    end

    def self.get_upgrade_command(node)
      base_cmd = FB::SystemUpgrade._get_base_command(node)

      exclude_cmd = ''
      mark_hold_cmd = ''
      exclude_pkgs = node['fb_system_upgrade']['exclude_packages']

      unless exclude_pkgs.empty?
        if ['yum', 'dnf'].include?(node.default_package_manager)
          exclude_cmd << "-x #{exclude_pkgs.join(' -x ')}"
        else
          mark_hold_cmd = "apt-mark hold #{exclude_pkgs.join(' ')}"
        end
      end

      if node['fb_system_upgrade']['allow_downgrades']
        dnf_cmd = 'distro-sync --allowerasing'
      else
        dnf_cmd = 'upgrade'
      end
      upgrade_cmd = "#{base_cmd} #{dnf_cmd} #{exclude_cmd}"
      log = node['fb_system_upgrade']['log']
      cmd = "date &>> #{log}; #{base_cmd} update ; #{mark_hold_cmd} &>> #{log} ; #{upgrade_cmd} &>> #{log}"

      cmd
    end
  end
end
