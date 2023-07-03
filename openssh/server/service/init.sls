# vim: ft=sls

{#-
    Starts the OpenSSH service and enables it at boot time.
    Has a dependency on `openssh.server.config`_.
#}

include:
  - .running
