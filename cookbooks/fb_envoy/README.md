fb_envoy Cookbook
=================

Installs and configures [Envoy](https://www.envoyproxy.io/) as a systemd
service using the `envoy` Debian package.

The package ships only the binary (`/usr/bin/envoy`). This cookbook manages
the config file (`/etc/envoy/envoy.yaml`) and the systemd unit.

Requirements
------------

- Ubuntu / Debian only
- `envoy` package available in the apt repo
- `fb_helpers`, `fb_systemd`

Attributes
----------

| Attribute | Default | Description |
|---|---|---|
| `node['fb_envoy']['enable']` | `false` | Enable and start the service |
| `node['fb_envoy']['manage_packages']` | `true` | Install/upgrade the envoy package |
| `node['fb_envoy']['listeners']` | `{}` | Hash of listener name → config |
| `node['fb_envoy']['clusters']` | `{}` | Hash of cluster name → config |
| `node['fb_envoy']['admin']` | `{ address: { socket_address: { address: 127.0.0.1, port_value: 9901 } } }` | Admin API config |

Usage
-----

Listeners and clusters are expressed as hashes keyed by name. Each value is the
Envoy config for that object **without** the `name` field (the cookbook injects
it). The resulting `envoy.yaml` contains a `static_resources` block with
`listeners` and `clusters` arrays, plus the `admin` section.

Example — TCP proxy with TLS origination:

```ruby
node.default['fb_envoy']['enable'] = true

node.default['fb_envoy']['listeners']['mmx_recsys_thrift'] = {
  'address' => {
    'socket_address' => {
      'address' => '127.0.0.1',
      'port_value' => 8912,
    },
  },
  'filter_chains' => [
    {
      'filters' => [
        {
          'name' => 'envoy.filters.network.tcp_proxy',
          'typed_config' => {
            '@type' => 'type.googleapis.com/envoy.extensions.filters.network.tcp_proxy.v3.TcpProxy',
            'stat_prefix' => 'mmx_recsys_thrift',
            'cluster' => 'mmx_recsys_thrift_tls',
          },
        },
      ],
    },
  ],
}

node.default['fb_envoy']['clusters']['mmx_recsys_thrift_tls'] = {
  'type' => 'STRICT_DNS',
  'dns_lookup_family' => 'V4_ONLY',
  'connect_timeout' => '2s',
  'lb_policy' => 'ROUND_ROBIN',
  'load_assignment' => {
    'cluster_name' => 'mmx_recsys_thrift_tls',
    'endpoints' => [
      {
        'lb_endpoints' => [
          {
            'endpoint' => {
              'address' => {
                'socket_address' => {
                  'address' => 'your-upstream.example.com',
                  'port_value' => 443,
                },
              },
            },
          },
        ],
      },
    ],
  },
  'upstream_connection_options' => {
    'tcp_keepalive' => {
      'keepalive_time' => 60,
      'keepalive_interval' => 10,
      'keepalive_probes' => 3,
    },
  },
  'transport_socket' => {
    'name' => 'envoy.transport_sockets.tls',
    'typed_config' => {
      '@type' => 'type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.UpstreamTlsContext',
      'sni' => 'your-upstream.example.com',
      'common_tls_context' => {
        'validation_context' => {
          'trusted_ca' => {
            'filename' => '/etc/ssl/certs/ca-certificates.crt',
          },
        },
        'tls_params' => {
          'tls_minimum_protocol_version' => 'TLSv1_2',
        },
      },
    },
  },
}
```
