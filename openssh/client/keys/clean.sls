# vim: ft=sls

{#-
    Removes managed OpenSSH user private/public keys and certificates.
#}

{%- set tplroot = tpldir.split("/")[0] %}
{%- from tplroot ~ "/map.jinja" import mapdata as openssh with context %}

{%- if openssh.client.user_keys %}

Managed OpenSSH user keys are absent:
  file.absent:
    - names:
{%-   for user in openssh.client.user_keys %}
{%-     set user_info = salt["user.info"](user) %}
{%-     set dir = (user_info.home | path_join(openssh.lookup.user_keys))
                if user_info else ("__slot__:salt:user.info('" ~ user ~ "').home ~ /" ~ openssh.lookup.user_keys) %}
{%-     for key_name, config in openssh.client.user_keys[user].items() %}
{%-       set filename = config.get("dir", dir) ~ "/" ~ key_name %}
      - {{ filename }}
      - {{ filename }}.pub
      - {{ filename }}.crt
{%-     endfor %}
{%-   endfor %}
{%- endif %}
