# vim: ft=sls

{#-
    Removes managed OpenSSH host private/public keys and certificates.
    Has a dependency on `openssh.server.service.clean`_.
#}

{%- set tplroot = tpldir.split("/")[0] %}
{%- set sls_service_clean = tplroot ~ ".server.service.clean" %}
{%- from tplroot ~ "/map.jinja" import mapdata as openssh with context %}

include:
  - {{ sls_service_clean }}

Managed OpenSSH host keys are absent:
  file.absent:
    - names:
{%- for key_type, config in openssh.server["keys"].items() %}
{%-   if config.get("manage") %}
{%-     set filename = salt["file.dirname"](openssh.lookup.config.server) | path_join("ssh_host_" ~ key_type ~ "_key") %}
      - {{ filename }}
      - {{ filename }}.pub
      - {{ filename }}.crt
{%-   endif %}
{%- endfor %}
    - require:
      - sls: {{ sls_service_clean }}
