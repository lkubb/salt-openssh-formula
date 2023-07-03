# vim: ft=sls

{#-
    Removes globally trusted OpenSSH certificate authorities for host certificates.
#}

{%- set tplroot = tpldir.split("/")[0] %}
{%- from tplroot ~ "/map.jinja" import mapdata as openssh with context %}

OpenSSH global known hosts file is absent:
  file.absent:
    - name: {{ salt["file.dirname"](openssh.lookup.config.client) | path_join("known_hosts") }}
