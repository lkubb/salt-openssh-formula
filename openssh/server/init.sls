# vim: ft=sls

{#-
    *Meta-state*.

    This installs the OpenSSH server package,
    manages its global configuration plus host keys/certificates
    as well as per-user authorized keys and trusted user CA keys.
    Will also manage (start/stop) the service, depending on the value in
    ``openssh:server:running``.
#}

include:
  - .package
  - .config
  - .keys
  - .authorized_keys
  - .service
