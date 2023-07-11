# vim: ft=sls

{#-
    Removes the configuration of the OpenSSH service, including
    AuthorizedPrincipalsFile, and has a dependency on
    `openssh.server.service.clean`_.
    Does not remove managed moduli.
#}

{%- set tplroot = tpldir.split("/")[0] %}
{%- set sls_service_clean = tplroot ~ ".server.service.clean" %}
{%- from tplroot ~ "/map.jinja" import mapdata as openssh with context %}

include:
  - {{ sls_service_clean }}

OpenSSH server configuration is absent:
  file.absent:
    - names:
{%- if openssh.server.config_override_default or not openssh.lookup.config.server_d %}
      - {{ openssh.lookup.config.server }}
{%- else %}
      - {{ openssh.lookup.config.server_d | path_join(openssh.lookup.config.server_d_filename) }}
{%- endif %}
{%- if openssh.server.config.get("AuthorizedPrincipalsFile", "none") != "none" and openssh.server.authorized_principals %}
{%-   set ppdir = openssh.server.config["AuthorizedPrincipalsFile"] | replace("%%", "%") %}
{%-   set requires_home = "%h" in ppdir %}
{%-   for user, principals in openssh.server.authorized_principals.items() %}
{%-     set user_info = salt["user.info"](user) if requires_home else none %}
{%-     set home = (user_info.home if user_info else "__slot__:salt:user.info('" ~ user ~ "').home ~ ") if requires_home else "" %}
      - {{ ppdir | replace("%h", home) | replace("%u", user) }}
{%-   endfor %}
{%- endif %}
    - require:
      - sls: {{ sls_service_clean }}
