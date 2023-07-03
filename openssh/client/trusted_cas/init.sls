# vim: ft=sls

{#-
    Manages **globally** trusted OpenSSH certificate authorities for host certificates.
    Has a dependency on `openssh.client.package`_.
#}

include:
  - .manage
