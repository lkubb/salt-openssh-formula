# vim: ft=sls

{%- set tplroot = tpldir.split("/")[0] %}
{%- set sls_package_install = tplroot ~ ".client.package.install" %}
{%- from tplroot ~ "/map.jinja" import mapdata as openssh with context %}
{%- from tplroot ~ "/libtofsstack.jinja" import files_switch with context %}

include:
  - {{ sls_package_install }}

OpenSSH client configuration is managed:
  file.managed:
{%- if openssh.client.config_override_default or not openssh.lookup.config.client_d %}
    - name: {{ openssh.lookup.config.client }}
{%- else %}
    - name: {{ openssh.lookup.config.client_d | path_join(openssh.lookup.config.client_d_filename) }}
{%- endif %}
    - source: {{ files_switch(
                    ["ssh_config", "ssh_config.j2"],
                    config=openssh,
                    lookup="OpenSSH client configuration is managed",
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
