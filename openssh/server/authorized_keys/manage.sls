# vim: ft=sls

{%- set tplroot = tpldir.split("/")[0] %}
{%- set sls_package_install = tplroot ~ ".server.package.install" %}
{%- from tplroot ~ "/map.jinja" import mapdata as openssh with context %}
{%- from tplroot ~ "/libtofsstack.jinja" import files_switch with context %}

include:
  - {{ sls_package_install }}

{%- for user, config in openssh.server.authorized_keys.items() %}
{%-   if config.get("sync") %}

Authorized keys for user {{ user }} are synced:
  ssh_auth.manage:
    - ssh_keys: {{ config.get("keys", []) | json }}
    - user: {{ user }}
    - options: {{ config.get("options", []) | json }}
    - comment: {{ config.get("comment") | json }}
{%-     if openssh.server.config.get("AuthorizedKeysFile") %}
    - config: '{{ openssh.server.config["AuthorizedKeysFile"] }}'
{%-     endif %}
    - require:
      - sls: {{ sls_package_install }}
{%-   else %}

Authorized keys for user {{ user }} are present:
  ssh_auth.present:
    - names: {{ config.get("keys", []) | json }}
    - user: {{ user }}
    - options: {{ config.get("options", []) | json }}
    - comment: {{ config.get("comment") | json }}
{%-     if openssh.server.config.get("AuthorizedKeysFile") %}
    - config: '{{ openssh.server.config["AuthorizedKeysFile"] }}'
{%-     endif %}
    - require:
      - sls: {{ sls_package_install }}

Unwanted authorized keys for user {{ user }} are absent:
  ssh_auth.absent:
    - names: {{ config.get("keys_absent", []) | json }}
    - user: {{ user }}
    - options: {{ config.get("options", []) | json }}
    - comment: {{ config.get("comment") | json }}
{%-     if openssh.server.config.get("AuthorizedKeysFile") %}
    - config: '{{ openssh.server.config["AuthorizedKeysFile"] }}'
{%-     endif %}
    - require:
      - sls: {{ sls_package_install }}
{%-   endif %}
{%- endfor %}

{%- if openssh.server.config.get("TrustedUserCAKeys") %}

Trusted user CA keys are managed:
  file.managed:
    - name: {{ openssh.server.config["TrustedUserCAKeys"] }}
    - source: {{ files_switch(
                    ["trusted_user_ca_keys.pem", "trusted_user_ca_keys.pem.j2"],
                    config=openssh,
                    lookup="Trusted user CA keys are managed",
                 )
              }}
    - mode: '0644'
    - user: root
    - group: {{ openssh.lookup.rootgroup }}
    - makedirs: true
    - template: jinja
    - require:
      - sls: {{ sls_package_install }}
    - context:
        openssh: {{ openssh | json }}
{%- endif %}
