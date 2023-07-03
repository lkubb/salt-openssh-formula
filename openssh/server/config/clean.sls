# vim: ft=sls

{#-
    Removes the configuration of the OpenSSH service and has a
    dependency on `openssh.server.service.clean`_.
    Does not remove managed moduli.
#}

{%- set tplroot = tpldir.split("/")[0] %}
{%- set sls_service_clean = tplroot ~ ".server.service.clean" %}
{%- from tplroot ~ "/map.jinja" import mapdata as openssh with context %}

include:
  - {{ sls_service_clean }}

OpenSSH server configuration is absent:
  file.absent:
{%- if openssh.server.config_override_default or not openssh.lookup.config.server_d %}
    - name: {{ openssh.lookup.config.server }}
{%- else %}
    - name: {{ openssh.lookup.config.server_d | path_join(openssh.lookup.config.server_d_filename) }}
{%- endif %}
    - require:
      - sls: {{ sls_service_clean }}
