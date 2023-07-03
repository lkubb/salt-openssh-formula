# vim: ft=sls

{#-
    Removes the configuration of the OpenSSH client.
#}

{%- set tplroot = tpldir.split("/")[0] %}
{%- from tplroot ~ "/map.jinja" import mapdata as openssh with context %}

OpenSSH client configuration is absent:
  file.absent:
{%- if openssh.client.config_override_default or not openssh.lookup.config.client_d %}
    - name: {{ openssh.lookup.config.client }}
{%- else %}
    - name: {{ openssh.lookup.config.client_d | path_join(openssh.lookup.config.client_d_filename) }}
{%- endif %}

