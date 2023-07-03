# vim: ft=sls

{#-
    Removes the OpenSSH client package.
    Has a dependency on `openssh.client.config.clean`_.
#}

{%- set tplroot = tpldir.split("/")[0] %}
{%- set sls_config_clean = tplroot ~ ".client.config.clean" %}
{%- from tplroot ~ "/map.jinja" import mapdata as openssh with context %}

include:
  - {{ sls_config_clean }}

OpenSSH client is removed:
  pkg.removed:
    - name: {{ openssh.lookup.pkg.client }}
    - require:
      - sls: {{ sls_config_clean }}
