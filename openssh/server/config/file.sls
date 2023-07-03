# vim: ft=sls

{%- set tplroot = tpldir.split("/")[0] %}
{%- set sls_package_install = tplroot ~ ".server.package.install" %}
{%- from tplroot ~ "/map.jinja" import mapdata as openssh with context %}
{%- from tplroot ~ "/libtofsstack.jinja" import files_switch with context %}

include:
  - {{ sls_package_install }}

OpenSSH server configuration is managed:
  file.managed:
{%- if openssh.server.config_override_default or not openssh.lookup.config.server_d %}
    - name: {{ openssh.lookup.config.server }}
{%- else %}
    - name: {{ openssh.lookup.config.server_d | path_join(openssh.lookup.config.server_d_filename) }}
{%- endif %}
    - source: {{ files_switch(
                    ["sshd_config", "sshd_config.j2"],
                    config=openssh,
                    lookup="OpenSSH server configuration is managed",
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


{%- if openssh.server.moduli %}

OpenSSH server moduli file is managed:
  file.managed:
    - name: {{ salt["file.dirname"](openssh.lookup.config.server) }}
    - source: {{ files_switch(
                    ["moduli"],
                    config=openssh,
                    lookup="OpenSSH server moduli file is managed",
                 )
              }}
    - mode: '0644'
    - user: root
    - group: {{ openssh.lookup.rootgroup }}
    - makedirs: true
    - require:
      - sls: {{ sls_package_install }}
{%- endif %}
