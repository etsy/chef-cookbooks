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

default['fb_envoy'] = {
  'enable' => false,
  'manage_packages' => true,
  # Hash of listener_name => listener config (without the 'name' key).
  # Each entry becomes an element of static_resources.listeners in envoy.yaml.
  'listeners' => {},
  # Hash of cluster_name => cluster config (without the 'name' key).
  # Each entry becomes an element of static_resources.clusters in envoy.yaml.
  'clusters' => {},
  # Admin API config.
  'admin' => {
    'address' => {
      'socket_address' => {
        'address' => '127.0.0.1',
        'port_value' => 9901,
      },
    },
  },
}
