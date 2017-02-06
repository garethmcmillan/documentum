# == Define: contentserver
#
# Adds an Apache configuration file.
# http://stackoverflow.com/questions/19024134/calling-puppet-defined-resource-with-multiple-parameters-multiple-times
#
define documentum::contentserver::docbroker(
  $installer_location,
  $documentum,
  $dctm_owner,
  $dctm_group,
  $version,
  $docbroker_port,
  $docbroker_host,

  $docbroker_name = $name,
  $installer      = "${documentum}/product/${version}/install",
 ) {
  # template(<FILE REFERENCE>, [<ADDITIONAL FILES>, ...])
  file { 'docbroker-response':
    ensure    => file,
    path      => "${installer_location}/docbroker/docbroker.properties",
    owner     => $dctm_owner,
    group     => $dctm_group,
    content   => template('documentum/contentserver/docbroker.properties.erb'),
  }

  exec { "docbroker-create":
    command     => "${installer}/dm_launch_server_config_program.sh -f ${installer_location}/docbroker/docbroker.properties -r ${installer_location}/docbroker/response.properties -i Silent",
    cwd         => $installer,
    require     => [File["docbroker-response"],
                    User["${dctm_owner}"]],
    environment => ["HOME=/home/${dctm_owner}",
                    "DOCUMENTUM=${documentum}",
                    "DOCUMENTUM_SHARED=${documentum}/shared",
                    "DM_HOME=${documentum}/product/${version}",
                    ],
    creates     => "${documentum}/dba/dm_launch_${docbroker_name}",
    user        => $dctm_owner,
    group       => $dctm_group,
    logoutput   => true,
    timeout     => 3000
  }

# coppying the service file across
  file { 'docbroker-init.d':
    ensure    => file,
    path      => "/etc/init.d/${docbroker_name}",
    owner     => root,
    group     => root,
    mode      => 755,
    content   => template('documentum/services/docbroker.erb'),
  }

  exec {'chkconfig-docbroker':
    require     => [File["docbroker-init.d"],
                    Exec["docbroker-create"],
                  ],
    command  => "/sbin/chkconfig --add ${docbroker_name}; /sbin/chkconfig ${docbroker_name} on",
    onlyif    =>  "/usr/bin/test `/sbin/chkconfig --list | /bin/grep ${docbroker_name} | /usr/bin/wc -l` -eq 0",
  }
}
