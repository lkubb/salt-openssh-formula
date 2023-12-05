# vim: ft=sls

{%- set tplroot = tpldir.split("/")[0] %}
{%- from tplroot ~ "/map.jinja" import mapdata as openssh with context %}

OpenSSH server is installed:
  pkg.installed:
    - name: {{ openssh.lookup.pkg.server }}
    - version: {{ openssh.server.version | json }}
