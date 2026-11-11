# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
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

require './spec/spec_helper'

# rubocop:disable Style/MultilineBlockChain

recipe 'fb_sysctl::default' do |tc|
  context 'render /etc/sysctl.conf' do
    let(:chef_run) do
      tc.chef_run do |node|
        node.default['shard_seed'] = 12345
        # Pretend to be a container to skip apply.
        node.default['virtualization']['role'] = 'guest'
        node.default['virtualization']['system'] = 'lxc'
      end
    end

    it 'with empty attributes' do
      chef_run.converge(described_recipe)

      expect(chef_run).to render_file('/etc/sysctl.conf').
        with_content(tc.fixture('sysctl.conf_empty'))
    end

    it 'with attributes set' do
      chef_run.converge(described_recipe) do |node|
        node.default['fb_sysctl']['this.is.a.setting'] = 0
        node.default['fb_sysctl']['this.is.also.a.setting'] = 1
      end

      expect(chef_run).to render_file('/etc/sysctl.conf').
        with_content(tc.fixture('sysctl.conf'))
    end
  end

  context 'sysctl.d compatibility link' do
    let(:link_path) { '/etc/sysctl.d/99-sysctl.conf' }

    def stub_sysctl_d(exists)
      allow(::Dir).to receive(:exist?).and_call_original
      allow(::Dir).to receive(:exist?).with('/etc/sysctl.d').and_return(exists)
    end

    it 'links /etc/sysctl.d/99-sysctl.conf to ../sysctl.conf on non-container Linux' do
      stub_sysctl_d(true)
      chef_run = tc.chef_run
      chef_run.converge(described_recipe)

      if chef_run.node.linux?
        expect(chef_run).to create_link(link_path).with(:to => '../sysctl.conf')
      else
        expect(chef_run).not_to create_link(link_path)
      end
    end

    it 'does not create the link in a container' do
      stub_sysctl_d(true)
      chef_run = tc.chef_run do |node|
        node.default['virtualization']['role'] = 'guest'
        node.default['virtualization']['system'] = 'lxc'
      end
      chef_run.converge(described_recipe)

      expect(chef_run).not_to create_link(link_path)
    end

    it 'does not create the link when /etc/sysctl.d does not exist' do
      stub_sysctl_d(false)
      chef_run = tc.chef_run
      chef_run.converge(described_recipe)

      expect(chef_run).not_to create_link(link_path)
    end
  end
end
