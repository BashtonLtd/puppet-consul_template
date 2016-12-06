# == Class consul_template::config
#
# This class is called from consul_template for service config.
#
class consul_template::config (
  $consul_host,
  $consul_port,
  $consul_token,
  $consul_retry,
  $purge = true,
) {

  concat::fragment { 'header':
    target  => 'consul-template/config.json',
    content => inline_template("consul = \"<%= @consul_host %>:<%= @consul_port %>\"\nretry = \"<%= @consul_retry %>\"\n\n"),
    order   => '00',
  }
  # Set wait param if specified
  if $::consul_token {
    concat::fragment { 'consul_wait':
      target  => 'consul-template/config.json',
      content => inline_template("token = \"<%= @consul_token %>\"\n\n"),
      order   => '01',
    }
  }
  # Set the log level
  concat::fragment { 'log_level':
    target  => 'consul-template/config.json',
    content => inline_template("log_level = \"${::consul_template::log_level}\"\n"),
    order   => '02'
  }

  # Set wait param if specified
  if $::consul_template::consul_wait {
    concat::fragment { 'consul_wait':
      target  => 'consul-template/config.json',
      content => inline_template("wait = \"${::consul_template::consul_wait}\"\n\n"),
      order   => '03',
    }
  }

  # Set max_stale param if specified
  if $::consul_template::consul_max_stale {
    concat::fragment { 'consul_max_stale':
      target  => 'consul-template/config.json',
      content => inline_template("max_stale = \"${::consul_template::consul_max_stale}\"\n\n"),
      order   => '04',
    }
  }

  if $::consul_template::deduplicate {
    concat::fragment { 'dedup-base':
      target  => 'consul-template/config.json',
      content => inline_template("deduplicate {\n  enabled = true\n"),
      order   => '05',
    }

    if $::consul_template::deduplicate_prefix {
      concat::fragment { 'dedup-prefix':
        target  => 'consul-template/config.json',
        content => inline_template("  prefix = \"${::consul_template::deduplicate_prefix}\"\n"),
        order   => '06',
      }
    }

    concat::fragment { 'dedup-close':
      target  => 'consul-template/config.json',
      content => inline_template("}\n"),
      order   => '07',
    }
  }

  if $::consul_template::vault_enabled {
    concat::fragment { 'vault-base':
      target  => 'consul-template/config.json',
      content => inline_template("vault {\n  address = \"${::consul_template::vault_address}\"\n"),
      order   => '08',
    }
    if $::consul_template::vault_token {
      concat::fragment { 'vault-token':
        target  => 'consul-template/config.json',
        content => inline_template("  token = \"${::consul_template::vault_token}\"\n"),
        order   => '09',
      }
    }
    if $::consul_template::vault_ssl {
      concat::fragment { 'vault-ssl1':
        target  => 'consul-template/config.json',
        content => inline_template("  ssl {\n    enabled = true\n    verify = ${::consul_template::vault_ssl_verify}\n"),
        order   => '10',
      }
      concat::fragment { 'vault-ssl2':
        target  => 'consul-template/config.json',
        content => inline_template("    cert = \"${::consul_template::vault_ssl_cert}\"\n    ca_cert = \"${::consul_template::vault_ssl_ca_cert}\"\n  }\n"),
        order   => '11',
      }
    }
    concat::fragment { 'vault-baseclose':
      target  => 'consul-template/config.json',
      content => "}\n\n",
      order   => '12',
    }
  }

  file { [$consul_template::config_dir, "${consul_template::config_dir}/config"]:
    ensure  => 'directory',
    purge   => $purge,
    recurse => $purge,
    owner   => $consul_template::user,
    group   => $consul_template::group,
    mode    => '0755',
  } ->
  concat { 'consul-template/config.json':
    path   => "${consul_template::config_dir}/config/config.json",
    owner  => $consul_template::user,
    group  => $consul_template::group,
    mode   => $consul_template::config_mode,
    notify => Service['consul-template'],
  }

}
