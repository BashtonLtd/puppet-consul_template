# == Class: consul_template
#
# Installs, configures, and manages consul-template
#
# === Parameters
#
# [*version*]
#   Specify version of consul-template binary to download.
#
# [*install_method*]
#   Defaults to `url` but can be `package` if you want to install via a system package.
#
# [*package_name*]
#   Only valid when the install_method == package. Defaults to `consul-template`.
#
# [*package_ensure*]
#   Only valid when the install_method == package. Defaults to `latest`.
#
# [*extra_options*]
#   Extra arguments to be passed to the consul-template agent
#
# [*init_style*]
#   What style of init system your system uses.
#
# [*config_hash*]
#   Consul-template configuration options. See https://github.com/hashicorp/consul-template#options
#
# [*config_mode*]
#   Set config file mode
#
# [*purge_config_dir*]
#   Purge config files no longer generated by Puppet
#
# [*data_dir*]
#   Path to a directory to create to hold some data. Defaults to ''
#
# [*user*]
#   Name of a user to use for dir and file perms. Defaults to root.
#
# [*group*]
#   Name of a group to use for dir and file perms. Defaults to root.
#
# [*manage_user*]
#   User is managed by this module. Defaults to `false`.
#
# [*manage_group*]
#   Group is managed by this module. Defaults to `false`.
#
# [*watches*]
#   A hash of watches - allows greater Hiera integration. Defaults to `{}`.

class consul_template (
  $arch                  = $::consul_template::params::arch,
  $init_style            = $::consul_template::params::init_style,
  $os                    = $::consul_template::params::os,
  $bin_dir               = '/usr/local/bin',
  $config_hash           = {},
  $config_defaults       = {},
  $config_dir            = '/etc/consul-template',
  $config_mode           = '0660',
  $data_dir              = '',
  $download_url          = undef,
  $download_url_base     = 'https://releases.hashicorp.com/consul-template/',
  $download_extension    = 'zip',
  $extra_options         = '',
  $group                 = 'root',
  $install_method        = 'url',
  $logrotate_compress    = 'nocompress',
  $logrotate_files       = 4,
  $logrotate_on          = false,
  $logrotate_period      = 'daily',
  $manage_user           = false,
  $manage_group          = false,
  $package_name          = 'consul-template',
  $package_ensure        = 'latest',
  $pretty_config         = false,
  $pretty_config_indent  = 4,
  $purge_config_dir      = true,
  $service_enable        = true,
  $service_ensure        = 'running',
  $user                  = 'root',
  $version               = '0.19.4',
  $watches               = {},
) inherits consul_template::params {

  validate_bool($purge_config_dir)
  validate_string($user)
  validate_string($group)
  validate_bool($manage_user)
  validate_bool($manage_group)
  validate_hash($watches)
  validate_hash($config_hash)
  validate_hash($config_defaults)

  $real_download_url = pick($download_url, "${download_url_base}${version}/${package_name}_${version}_${os}_${arch}.${download_extension}")

  if $watches {
    create_resources('::consul_template::watch', $watches)
  }

  $config_base = {
    consul => 'localhost:8500',
  }
  $config_hash_real = deep_merge($config_base, $config_defaults, $config_hash)

  anchor { '::consul_template::begin': }

  class { '::consul_template::install':
    require => Anchor['::consul_template::begin'],
  }

  class { '::consul_template::config':
    config_hash => $config_hash_real,
    purge       => $purge_config_dir,
    require     => Class['::consul_template::install'],
  }

  class { '::consul_template::service':
    subscribe => Class['::consul_template::config'],
  }

  anchor { '::consul_template::end':
    require => Class['::consul_template::service'],
  }

  class { '::consul_template::logrotate':
    logrotate_compress => $logrotate_compress,
    logrotate_files    => $logrotate_files,
    logrotate_on       => $logrotate_on,
    logrotate_period   => $logrotate_period,
    require            => Anchor['::consul_template::begin'],
    before             => Anchor['::consul_template::end'],
  }
}
