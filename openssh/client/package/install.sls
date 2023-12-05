# vim: ft=sls

{%- set tplroot = tpldir.split("/")[0] %}
{%- from tplroot ~ "/map.jinja" import mapdata as openssh with context %}

OpenSSH client is installed:
  pkg.installed:
    - name: {{ openssh.lookup.pkg.client }}
    - version: {{ openssh.client.version | json }}
