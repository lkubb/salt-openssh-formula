# vim: ft=sls

{%- set tplroot = tpldir.split("/")[0] %}
{%- set sls_package_install = tplroot ~ ".client.package.install" %}
{%- from tplroot ~ "/map.jinja" import mapdata as openssh with context %}
{%- from tplroot ~ "/libtofsstack.jinja" import files_switch with context %}

include:
  - {{ sls_package_install }}

OpenSSH global known hosts are managed:
  file.managed:
    - name: {{ salt["file.dirname"](openssh.lookup.config.client) | path_join("ssh_known_hosts") }}
    - source: {{ files_switch(
                    ["ssh_known_hosts", "ssh_known_hosts.j2"],
                    config=openssh,
                    lookup="OpenSSH global known hosts are managed",
                 )
              }}
    - mode: '0644'
    - user: root
    - group: {{ openssh.lookup.rootgroup }}
    - makedirs: true
    - template: jinja
    - require:
      - sls: {{ sls_package_install }}
    - context:
        openssh: {{ openssh | json }}
