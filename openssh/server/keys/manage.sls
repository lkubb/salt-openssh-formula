# vim: ft=sls

{%- set tplroot = tpldir.split("/")[0] %}
{%- set sls_package_install = tplroot ~ ".server.package.install" %}
{%- from tplroot ~ "/map.jinja" import mapdata as openssh with context %}

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

{%-   else %}
{%-     set algo_type = key_type if key_type != "ecdsa" else "ec" %}

OpenSSH {{ key_type }} host key is present:
  ssh_pki.private_key_managed:
    - name: {{ filename }}
    - algo: {{ algo_type }}
    - keysize: {{ config.get("key_size") | json }}
    - user: root
    - group: {{ openssh.lookup.get("ssh_keys_group") or openssh.lookup.rootgroup }}
    - mode: {{ "'0600'" if not openssh.lookup.get("ssh_keys_group") else "'0640'" }}
{%-     if config.get("cert") %}
    - new: true
{%-       if salt["file.file_exists"](filename) %}
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
{%-       if not salt["file.file_exists"](filename) %}
    - require:
      - ssh_pki: {{ filename }}
{%-       endif %}
{%-     endif %}

OpenSSH {{ key_type }} host pubkey is present:
  ssh_pki.public_key_managed:
    - name: {{ filename }}.pub
    - public_key_source: {{ filename }}
    - user: root
    - group: {{ openssh.lookup.rootgroup }}
    - require:
      - ssh_pki: {{ filename }}
{%-   endif %}
{%- endfor %}
