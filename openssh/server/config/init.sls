# vim: ft=sls

{#-
    Manages the OpenSSH service configuration, including
    AuthorizedPrincipalsFile and moduli if ``openssh:server:moduli``
    was set to true.
    Has a dependency on `openssh.server.package`_.
#}

include:
  - .file
