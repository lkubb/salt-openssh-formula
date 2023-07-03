# vim: ft=sls

{#-
    Removes the OpenSSH server package.
    Has a dependency on `openssh.server.config.clean`_.
#}

{%- set tplroot = tpldir.split("/")[0] %}
{%- set sls_config_clean = tplroot ~ ".server.config.clean" %}
{%- from tplroot ~ "/map.jinja" import mapdata as openssh with context %}

include:
  - {{ sls_config_clean }}

OpenSSH server is removed:
  pkg.removed:
    - name: {{ openssh.lookup.pkg.server }}
    - require:
      - sls: {{ sls_config_clean }}
