# vim: ft=sls

{#-
    Manages OpenSSH authorized keys.
    If ``TrustedUserCAKeys`` has been specified in the server
    configuration (``openssh:server:config``), all CA keys from
    ``openssh:server:trusted_user_ca_keys`` will be serialized
    into the corresponding file as well.
    Has a dependency on `openssh.server.package`_.
#}

include:
  - .manage
