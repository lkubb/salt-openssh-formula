# vim: ft=sls

{#-
    Stops the OpenSSH service and disables it at boot time.
#}

{%- set tplroot = tpldir.split("/")[0] %}
{%- from tplroot ~ "/map.jinja" import mapdata as openssh with context %}

OpenSSH is dead:
  service.dead:
    - name: {{ openssh.lookup.service.name }}
    - enable: false
