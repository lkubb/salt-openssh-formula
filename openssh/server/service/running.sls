# vim: ft=sls

{%- set tplroot = tpldir.split("/")[0] %}
{%- set sls_config_file = tplroot ~ ".server.config.file" %}
{%- from tplroot ~ "/map.jinja" import mapdata as openssh with context %}

include:
  - {{ sls_config_file }}

OpenSSH is running:
  service.running:
    - name: {{ openssh.lookup.service.name }}
    - enable: true
    - watch:
      - sls: {{ sls_config_file }}
 # KEYS!
