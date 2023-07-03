# vim: ft=sls

{#-
    *Meta-state*.

    This includes everything from the `openssh.server`_ and
    `openssh.client`_ meta states.
#}

include:
  - .server
  - .client
