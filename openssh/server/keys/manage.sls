# vim: ft=sls

{%- set tplroot = tpldir.split("/")[0] %}
{%- set sls_package_install = tplroot ~ ".server.package.install" %}
{%- from tplroot ~ "/map.jinja" import mapdata as openssh with context %}
{%- from tplroot ~ "/libsaltcli.jinja" import cli with context %}

include:
  - {{ sls_package_install }}

{%- for key_type, config in openssh.server["keys"].items() %}
{%-   if not config.get("manage", True) %}
{%-     continue %}
{%-   endif %}
{%-   set filename = salt["file.dirname"](openssh.lookup.config.server) | path_join("ssh_host_" ~ key_type ~ "_key") %}
{%-   if not config.get("present", True) %}

OpenSSH {{ key_type }} host key is absent:
  file.absent:
    - names:
      - {{ filename }}
      - {{ filename }}.pub
      - {{ filename }}.crt
{%-     continue %}
{%-   endif %}
{%-   set algo_type = key_type if key_type != "ecdsa" else "ec" %}
{%-   set pk_params = {
        "name": filename,
        "algo": algo_type,
        "keysize": config.get("key_size"),
        "user": "root",
        "group": "root",
        "mode": "0600",
        "new": config.get("cert") | to_bool
      }
%}
{%-   if cli in ["ssh", "unknown"] and config.get("cert") and openssh.server.cert_params.ca_server %}
{%-     set cert_params = {} %}
{%-     for param, val in openssh.server.cert_params.items() %}
{%-       if param not in ["ca_server", "backend", "backend_args", "signing_policy"] %}
{%-         do cert_params.update({param: val}) %}
{%-       endif %}
{%-     endfor %}
{%-     do cert_params.update({
          "cert_type": "host",
          "user": "root",
          "group": "root"
        })
%}

{{
    salt["ssh_pki.certificate_managed_wrapper"](
        filename ~ ".crt",
        ca_server=openssh.server.cert_params.ca_server,
        signing_policy=openssh.server.cert_params.signing_policy,
        backend=openssh.server.cert_params.backend,
        backend_args=openssh.server.cert_params.backend_args,
        private_key_managed=pk_params,
        certificate_managed=cert_params,
        test=opts.get("test")
    ) | yaml(false)
}}
{%-   else %}

OpenSSH {{ key_type }} host key is present:
  ssh_pki.private_key_managed:
    {{ pk_params | dict_to_sls_yaml_params | indent(4) }}
{%-     if config.get("cert") %}
{%-       if salt["file.file_exists"](filename) is true %}
    # prereq_in complains about "Cannot extend ID"
    - prereq:
      - ssh_pki: {{ filename }}.crt
{%-       endif %}

OpenSSH {{ key_type }} host certificate is present:
  ssh_pki.certificate_managed:
    - name: {{ filename }}.crt
    - cert_type: host
    - user: root
    - private_key: {{ filename }}
    - group: {{ openssh.lookup.rootgroup }}
{%-       for param, val in openssh.server.cert_params.items() %}
    - {{ param }}: {{ val | json }}
{%-       endfor %}
{%-       if salt["file.file_exists"](filename) is false %}
    - require:
      - ssh_pki: {{ filename }}
{%-       endif %}
{%-     endif %}
{%-   endif %}

OpenSSH {{ key_type }} host pubkey is present:
  ssh_pki.public_key_managed:
    - name: {{ filename }}.pub
    - public_key_source: {{ filename }}
    - user: root
    - group: {{ openssh.lookup.rootgroup }}
    - require:
      - ssh_pki: {{ filename }}
{%- endfor %}
