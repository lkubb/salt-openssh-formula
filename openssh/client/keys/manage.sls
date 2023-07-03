# vim: ft=sls

{%- set tplroot = tpldir.split("/")[0] %}
{%- set sls_package_install = tplroot ~ ".client.package.install" %}
{%- from tplroot ~ "/map.jinja" import mapdata as openssh with context %}

include:
  - {{ sls_package_install }}

{%- for user in openssh.client.user_keys %}
{%-   set user_info = salt["user.info"](user) %}
{%-   set dir = (user_info.home | path_join(openssh.lookup.user_keys))
                if user_info else ("__slot__:salt:user.info('" ~ user ~ "').home ~ /" ~ openssh.lookup.user_keys) %}
{%-   set primary_group = salt["user.primary_group"](user) if user_info else ("__slot__:salt:user.primary_group('" ~  user ~ "')") %}
{%-   for key_name, config in openssh.client.user_keys[user].items() %}
{%-     set key_dir = config.get("dir", dir) %}
{%-     set filename = key_dir ~ "/" ~ key_name %}
{%-     set group = config.get("group", primary_group) %}

{%-     if not config.get("present", True) %}

OpenSSH {{ key_name }} host key is absent:
  file.absent:
    - names:
      - {{ filename }}
      - {{ filename }}.pub
      - {{ filename }}.crt

{%-     else %}
{%-       set algo_type = config.get("algo", "rsa") if config.get("algo", "rsa") != "ecdsa" else "ec" %}

OpenSSH {{ key_name }} is present:
  ssh_pki.private_key_managed:
    - name: {{ filename }}
    - algo: {{ algo_type }}
    - keysize: {{ config.get("key_size") | json }}
    - user: {{ user }}
    - group: {{ group }}
{%-       if config.get("cert") %}
    - new: {{ config.get("new") | to_bool }}
{%-         if salt["file.file_exists"](filename) %}
    # prereq_in complains about "Cannot extend ID"
    - prereq:
      - ssh_pki: {{ filename }}.crt
{%-         endif %}

OpenSSH {{ key_name }} certificate is present:
  ssh_pki.certificate_managed:
    - name: {{ filename }}.crt
    - cert_type: client
    - private_key: {{ filename }}
    - user: {{ user }}
    - group: {{ group }}
{%-         for param, val in openssh.client.cert_params.items() %}
{%-           if param in config %}
    - {{ param }}: {{ config[param] | json }}
{%-           else %}
    - {{ param }}: {{ val | json }}
{%-           endif %}
{%-       endfor %}
{%-         if not salt["file.file_exists"](filename) %}
    - require:
      - OpenSSH {{ key_name }} is present
{%-         endif %}
{%-       endif %}

OpenSSH {{ key_name }} pubkey is present:
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
