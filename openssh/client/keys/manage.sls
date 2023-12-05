# vim: ft=sls

{%- set tplroot = tpldir.split("/")[0] %}
{%- set sls_package_install = tplroot ~ ".client.package.install" %}
{%- from tplroot ~ "/map.jinja" import mapdata as openssh with context %}
{%- from tplroot ~ "/libsaltcli.jinja" import cli with context %}

include:
  - {{ sls_package_install }}

{%- for user in openssh.client.user_keys %}
{%-   set user_info = salt["user.info"](user) %}
{%-   if not user_info and cli in ["ssh", "unknown"] %}
{%-     do salt["log.error"]("With salt-ssh, a user has to exist before managing keys. Missing: " ~ user) %}
{%-     continue %}
{%-   endif %}
{%-   set dir = (user_info.home | path_join(openssh.lookup.user_keys))
                if user_info else ("__slot__:salt:user.info('" ~ user ~ "').home ~ /" ~ openssh.lookup.user_keys) %}
{%-   set primary_group = salt["user.primary_group"](user) if user_info else ("__slot__:salt:user.primary_group('" ~  user ~ "')") %}
{%-   for key_name, config in openssh.client.user_keys[user].items() %}
{%-     set key_dir = config.get("dir", dir) %}
{%-     set filename = key_dir ~ "/" ~ key_name %}
{%-     set group = config.get("group", primary_group) %}

{%-     if not config.get("present", True) %}

OpenSSH user '{{ user }}' key '{{ key_name }}' is absent:
  file.absent:
    - names:
      - {{ filename }}
      - {{ filename }}.pub
      - {{ filename }}.crt
{%-       continue %}
{%-     endif %}
{%-     set algo_type = config.get("algo", "rsa") if config.get("algo", "rsa") != "ecdsa" else "ec" %}
{%-     set pk_params = {
          "name": filename,
          "algo": algo_type,
          "keysize": config.get("key_size"),
          "user": user,
          "group": group,
          "mode": "0600",
          "new": config.get("cert") and config.get("new") | to_bool
        }
%}
{%-     if cli in ["ssh", "unknown"] and config.get("cert") and config.get("ca_server", openssh.client.cert_params.ca_server) %}
{%-       set cert_params = {} %}
{%-       for param, val in openssh.client.cert_params.items() %}
{%-         if param not in ["ca_server", "backend", "backend_args", "signing_policy"] %}
{%-           if param in config %}
{%-             do cert_params.update({param: config[param]}) %}
{%-           else %}
{%-             do cert_params.update({param: val}) %}
{%-           endif %}
{%-         endif %}
{%-       endfor %}
{%-       do cert_params.update({
            "cert_type": "user",
            "user": user,
            "group": group
          })
%}

{{
    salt["ssh_pki.certificate_managed_wrapper"](
        filename ~ ".crt",
        ca_server=config.get("ca_server", openssh.client.cert_params.ca_server),
        signing_policy=config.get("signing_policy", openssh.client.cert_params.signing_policy),
        backend=config.get("backend", openssh.client.cert_params.backend),
        backend_args=config.get("backend_args", openssh.client.cert_params.backend_args),
        private_key_managed=pk_params,
        certificate_managed=cert_params,
        test=opts.get("test")
    ) | yaml(false)
}}
{%-     else %}

OpenSSH user '{{ user }}' key '{{ key_name }}' is present:
  ssh_pki.private_key_managed:
    {{ pk_params | dict_to_sls_yaml_params | indent(4) }}
{%-       if config.get("cert") %}
{%-         if salt["file.file_exists"](filename) is true %}
    # prereq_in complains about "Cannot extend ID"
    - prereq:
      - ssh_pki: {{ filename }}.crt
{%-         endif %}

OpenSSH user '{{ user }}' certificate '{{ key_name }}' is present:
  ssh_pki.certificate_managed:
    - name: {{ filename }}.crt
    - cert_type: user
    - private_key: {{ filename }}
    - user: {{ user }}
    - group: {{ group }}
{%-         for param, val in openssh.client.cert_params.items() %}
{%-           if param in config %}
    - {{ param }}: {{ config[param] | json }}
{%-           else %}
    - {{ param }}: {{ val | json }}
{%-           endif %}
{%-         endfor %}
{%-         if salt["file.file_exists"](filename) is false %}
    - require:
      - ssh_pki: {{ filename }}
{%-         endif %}
{%-       endif %}

OpenSSH user '{{ user }}' pubkey '{{ key_name }}' is present:
  ssh_pki.public_key_managed:
    - name: {{ filename }}.pub
    - public_key_source: {{ filename }}
    - user: {{ user }}
    - group: {{ group }}
    - require:
      - ssh_pki: {{ filename }}
{%-     endif %}
{%-   endfor %}
{%- endfor %}
