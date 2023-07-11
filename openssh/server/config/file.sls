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

{%- if openssh.server.config.get("AuthorizedPrincipalsFile", "none") != "none" and openssh.server.authorized_principals %}
{%-   set pfile = openssh.server.config["AuthorizedPrincipalsFile"] %}
{%-   set requires_home = "%h" in pfile %}

OpenSSH authorized principals are managed:
  file.managed:
    - names:
{%-   for user, principals in openssh.server.authorized_principals.items() %}
{%-     set user_info = salt["user.info"](user) if requires_home else none %}
{%-     set home = (user_info.home if user_info else "__slot__:salt:user.info('" ~ user ~ "').home ~ ") if requires_home else "" %}
{%-     set primary_group = (salt["user.primary_group"](user) if user_info else ("__slot__:salt:user.primary_group('" ~  user ~ "')"))
                            if requires_home else openssh.lookup.rootgroup %}

        - {{ pfile | replace("%h", home) | replace("%u", user) | replace("%%", "%") }}:
          - context:
              principals: {{ principals | json }}
          - user: {{ user if requires_home else "root" }}
          - group: {{ primary_group }}
{%-   endfor %}
    - source: {{ files_switch(
                    ["principals.j2"],
                    config=openssh,
                    lookup="OpenSSH authorized principals are managed",
                 )
              }}
    - mode: '0600'
    - makedirs: true
    - template: jinja
    - require:
      - sls: {{ sls_package_install }}
    - defaults:
        openssh: {{ openssh | json }}
{%- endif %}
