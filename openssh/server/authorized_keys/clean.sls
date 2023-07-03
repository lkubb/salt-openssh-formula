# vim: ft=sls

{#-
    Removes managed OpenSSH authorized keys and trusted user CA keys.
#}

{%- set tplroot = tpldir.split("/")[0] %}
{%- from tplroot ~ "/map.jinja" import mapdata as openssh with context %}

{%- for user, config in openssh.server.authorized_keys.items() %}
{%-   set sync = config.get("sync", openssh.server.authorized_keys_sync) %}
{%-   if sync %}

Wanted authorized keys for user {{ user }} are absent:
  ssh_auth.manage:
    - user: {{ user }}
    - ssh_keys: []
{%-     if openssh.server.config.get("AuthorizedKeysFile") %}
    - config: '{{ openssh.server.config["AuthorizedKeysFile"] }}'
{%-     endif %}
{%-   else %}

Authorized keys for user {{ user }} are present:
  ssh_auth.absent:
    - names: {{ config.get("keys", []) | json }}
    - user: {{ user }}
    - options: {{ config.get("options", []) | json }}
    - comment: {{ config.get("comment") | json }}
{%-     if openssh.server.config.get("AuthorizedKeysFile") %}
    - config: '{{ openssh.server.config["AuthorizedKeysFile"] }}'
{%-     endif %}
{%-   endif %}
{%- endfor %}

{%- if openssh.server.config.get("TrustedUserCAKeys") %}

Trusted user CA keys are absent:
  file.absent:
    - name: openssh.server.config["TrustedUserCAKeys"]
{%- endif %}
