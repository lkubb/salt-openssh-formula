# vim: ft=yaml
---
openssh:
  lookup:
    master: template-master
    # Just for testing purposes
    winner: lookup
    added_in_lookup: lookup_value
    service:
      name: sshd
    config:
      client: /etc/ssh/ssh_config
      client_d: /etc/ssh/ssh_config.d
      client_d_filename: 10-salt.conf
      server: /etc/ssh/sshd_config
      server_d: /etc/ssh/sshd_config.d
      server_d_filename: 10-salt.conf
    pkg:
      client: openssh
      server: openssh
    user_keys: .ssh
  client:
    cert_params:
      all_principals: false
      backend: null
      backend_args: null
      ca_server: null
      signing_policy: null
      ttl: null
      ttl_remaining: null
      valid_principals: null
    config: {}
    config_override_default: false
    trusted_host_cas: []
    user_keys: {}
    version: latest
  server:
    authorized_keys: {}
    cert_params:
      all_principals: false
      backend: null
      backend_args: null
      ca_server: null
      signing_policy: null
      ttl: null
      ttl_remaining: null
      valid_principals: null
    config: {}
    config_override_default: false
    keys:
      dsa:
        manage: true
        present: false
      ecdsa:
        manage: true
        present: true
      ed25519:
        manage: true
        present: true
      rsa:
        manage: true
        present: true
    moduli: false
    running: true
    trusted_user_ca_keys: []
    version: latest

  tofs:
    # The files_switch key serves as a selector for alternative
    # directories under the formula files directory. See TOFS pattern
    # doc for more info.
    # Note: Any value not evaluated by `config.get` will be used literally.
    # This can be used to set custom paths, as many levels deep as required.
    files_switch:
      - any/path/can/be/used/here
      - id
      - roles
      - osfinger
      - os
      - os_family
    # All aspects of path/file resolution are customisable using the options below.
    # This is unnecessary in most cases; there are sensible defaults.
    # Default path: salt://< path_prefix >/< dirs.files >/< dirs.default >
    #         I.e.: salt://openssh/files/default
    # path_prefix: template_alt
    # dirs:
    #   files: files_alt
    #   default: default_alt
    # The entries under `source_files` are prepended to the default source files
    # given for the state
    # source_files:
    #   openssh-config-file-file-managed:
    #     - 'example_alt.tmpl'
    #     - 'example_alt.tmpl.jinja'

    # For testing purposes
    source_files:
      openssh-config-file-file-managed:
        - 'example.tmpl.jinja'

  # Just for testing purposes
  winner: pillar
  added_in_pillar: pillar_value
