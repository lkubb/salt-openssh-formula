# vim: ft=sls

{#-
    *Meta-state*.

    This installs the OpenSSH client package,
    manages its global configuration plus globally
    trusted host certificate authorities and
    manages per-user client keys and certificates.
#}

include:
  - .package
  - .config
  - .keys
  - .trusted_cas
