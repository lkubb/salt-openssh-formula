# vim: ft=sls

{#-
    *Meta-state*.

    Undoes everything performed in the `openssh.server`_ and
    `openssh.client`_ meta states.
#}

include:
  - .client.clean
  - .server.clean
