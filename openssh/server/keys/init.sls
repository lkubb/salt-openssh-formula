# vim: ft=sls

{#-
    Manages OpenSSH host private/public keys and certificates.
    Has a dependency on `openssh.server.package`_.
#}

include:
  - .manage
