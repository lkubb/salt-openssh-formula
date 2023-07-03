# vim: ft=sls

{#-
    *Meta-state*.

    Undoes everything performed in the ``openssh.client`` meta-state
    in reverse order, i.e.
    **removes per-user client keys** and certificates,
    removes globally trusted host certificate authorities,
    removes the global OpenSSH client configuration file and then
    uninstalls the package.
#}

include:
  - .trusted_cas.clean
  - .keys.clean
  - .config.clean
  - .package.clean
