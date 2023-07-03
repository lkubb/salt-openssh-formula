# vim: ft=sls

{#-
    *Meta-state*.

    Undoes everything performed in the ``openssh.server`` meta-state
    in reverse order, i.e.
    stops the OpenSSH server,
    removes host keys and certificates,
    removes per-user authorized keys,
    removes trusted client certificate authorities,
    removes the global OpenSSH server configuration file and then
    uninstalls the package.
#}

include:
  - .service.clean
  - .authorized_keys.clean
  - .keys.clean
  - .config.clean
  - .package.clean
