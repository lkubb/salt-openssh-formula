"""
Automatic SSH certificates for Salt-SSH
=======================================
This roster module allows to automatically fetch valid SSH certificates
when needed. You can thus avoid writing long-lived certificates with
wide permissions to the filesystem.

It has the same syntax as the ``flat`` roster. In addition, it provides
a ``cert`` parameter. If it is unset, the roster entry will be returned
as-is, unless you force this roster's activation in the master config.

When active, this roster adds additional logic on top, which essentially runs a
``ssh_pki.private_key_managed`` + ``ssh_pki.certificate_managed`` and
sets the necessary roster configuration for SSH certificate authentication.

.. code-block:: yaml

    # /etc/salt/roster
    target_host_id:
      user: root
      host: target.host.example.org
      # If unset, priv will be set automatically to
      # <pki_dir>/ssh/autocert/<target_host_id>
      # If a relative path is specified, it will be made absolute
      # relative to `<pki_dir>/ssh/autocert`.
      # The certificate will be written next to the private key
      # with a `.crt` extension.
      cert:
        cert_args:
          backend: vault_ssh
          ca_server: ssh
          signing_policy: salt_master
          valid_principals:
            - root

You can define default values for each roster entry in your master configuration
under the key ``autocert_roster:default``:

.. code-block:: yaml

    # /etc/salt/master.d/ssh.conf
    autocert_roster:
      default:
        user: root
        cert:
          cert_args:
            backend: vault_ssh
            ca_server: ssh
            signing_policy: salt_master
            valid_principals:
              - root

Which allows you to strip down the roster to:

.. code-block:: yaml

    target_host_id:
      host: target.host.example.org
      # This is necessary to enable autocert behavior, unless
      # forcing activation in the master config.
      cert: {}

All configuration values with defaults:

.. code-block:: yaml

    autocert_roster:

      # Do not require `cert` parameter in roster entry to activate
      force: false

      # Default values for single roster entries
      default:

        # ... all general roster parameters

        # Configuration specific to this module
        cert:
          private_key:
            algo: ed25519
            keysize: null  # default depends on algo
          cert_args:
            # ... all parameters to ssh_pki.certificate_managed

.. note::

    Currently, private keys are not rotated when a new certificate is issued
    for performance reasons. You can force their regeneration by deleting
    the files.
"""

# TODO: Add key rotation behavior, maybe by using mtime or writing the
#       last rotation time to cache. It could be implemented using test=true,
#       check its performance to determine if the tradeoff is worth it.

import copy
import logging
from pathlib import Path

import salt.config
import salt.loader
import salt.minion
import salt.utils.dictupdate as dup
import salt.utils.json
from salt.exceptions import CommandExecutionError
from salt.roster import get_roster_file
from salt.template import compile_template


log = logging.getLogger(__name__)

__virtualname__ = "autocert_flat"


def __virtual__():
    return __virtualname__


def targets(tgt, tgt_type="glob", **kwargs):
    """
    Return the targets from the flat yaml file, checks opts for location but
    defaults to /etc/salt/roster
    """
    template = get_roster_file(__opts__)

    rend = salt.loader.render(__opts__, {})
    raw = compile_template(
        template,
        rend,
        __opts__["renderer"],
        __opts__["renderer_blacklist"],
        __opts__["renderer_whitelist"],
        mask_value="*passw*",
        **kwargs,
    )
    conditioned_raw = {}
    for minion in raw:
        conditioned_raw[str(minion)] = salt.config.apply_sdb(raw[minion])
    matches = __utils__["roster_matcher.targets"](
        conditioned_raw, tgt, tgt_type, "ipv4"
    )
    res = {}
    roster_config = __opts__.get("autocert_roster", {})
    forced = roster_config.get("force", False)
    basedir = Path(__opts__["pki_dir"]) / "ssh" / "autocert"
    for host, config in matches.items():
        try:
            if "cert" not in config:
                if not forced:
                    res[host] = config
                    continue
                config["cert"] = {}
            final_config = dup.merge(roster_config.get("default", {}), config)
            if "priv" not in final_config:
                final_config["priv"] = basedir / host
            priv = Path(final_config["priv"])
            if not priv.is_absolute():
                priv = basedir / priv
                final_config["priv"] = str(priv)
            if not priv.exists():
                keysize = None
                algo = (
                    final_config["cert"]
                    .get("private_key", {})
                    .get("algo", "ed25519")
                )
                if algo in ["rsa", "ec"]:
                    keysize = final_config["cert"].get(
                        "keysize", 2048 if algo == "rsa" else 256
                    )
                _check_ret(
                    _manage(
                        "ssh_pki.private_key_managed",
                        name=str(priv),
                        makedirs=True,
                        mode="0600",
                        dir_mode="0700",
                        algo=algo,
                        keysize=keysize,
                        overwrite=True,
                    )
                )
            cert = priv.with_suffix(".crt")
            _check_ret(
                _manage(
                    "ssh_pki.certificate_managed",
                    name=str(cert),
                    **final_config["cert"].get("cert_args", {}),
                    cert_type="user",
                    mode="0644",
                    dir_mode="0700",
                    private_key=str(priv),
                )
            )
            if "ssh_options" not in final_config:
                final_config["ssh_options"] = []
            else:
                final_config["ssh_options"] = [
                    x
                    for x in final_config["ssh_options"]
                    if "CertificateFile" not in x
                ]
            final_config["ssh_options"].append(f"CertificateFile={cert}")
            res[host] = final_config
        except CommandExecutionError as err:
            log.error(f"Autocert roster failed for host '{host}': {err}")
    return res


def _check_ret(ret):
    if not isinstance(ret, dict) or not ret:
        raise CommandExecutionError(f"Invalid return: {salt.utils.json.dumps(ret)}")
    host_ret = ret[next(iter(ret))]
    if not isinstance(host_ret, dict) or not host_ret:
        raise CommandExecutionError(
            f"Invalid host return: {salt.utils.json.dumps(ret)}"
        )
    res = host_ret[next(iter(host_ret))]
    if (
        not isinstance(res, dict)
        or not res
        or "result" not in res
        or "comment" not in res
    ):
        raise CommandExecutionError(
            f"Invalid state return: {salt.utils.json.dumps(ret)}"
        )
    if not res["result"]:
        raise CommandExecutionError(res["comment"])


def _manage(fun, name, **kwargs):
    """
    Stripped down variant of runners.state.orchestrate_single -
    it tries to access __jid_event__, which is unset when called
    from here and patching it in is hacky and does not work reliably.
    """
    opts = copy.deepcopy(__opts__)
    opts["file_client"] = "local"
    minion = salt.minion.MasterMinion(opts)
    running = minion.functions["state.single"](
        fun, name, test=None, queue=False, **kwargs
    )
    ret = {minion.opts["id"]: running}
    return ret
