import logging
import time
import salt.daemons.masterapi
from salt.exceptions import CommandExecutionError, SaltInvocationError

try:
    import sshpki

    HAS_CRYPTOGRAPHY = True
except ImportError:
    HAS_CRYPTOGRAPHY = False


log = logging.getLogger(__name__)


def create_certificate(
    ca_server=None,
    signing_policy=None,
    path=None,
    overwrite=False,
    raw=False,
    **kwargs,
):
    """
    Create an OpenSSH certificate and return an encoded version of it.

    .. note::

        All parameters that take a public key or private key
        can be specified either as a string or a path to a
        local file encoded for OpenSSH.

    CLI Example:

    .. code-block:: bash

        salt '*' ssh_pki.create_certificate private_key=/root/.ssh/id_rsa signing_private_key='/etc/pki/ssh/myca.key'

    ca_server
        Request a remotely signed certificate from another minion acting as
        a CA server. For this to work, a ``signing_policy`` must be specified,
        and that same policy must be configured on the ca_server. See `Signing policies`_
        for details. Also, the Salt master must permit peers to call the
        ``sign_remote_certificate`` function, see `Peer communication`_.

    signing_policy
        The name of a configured signing policy. Parameters specified in there
        are hardcoded and cannot be overridden. This is required for remote signing,
        otherwise optional. See `Signing policies`_ for details.

    copypath
        Create a copy of the issued certificate in this directory.
        The file will be named ``<serial_number>.crt``.

    path
        Instead of returning the certificate, write it to this file path.

    overwrite
        If ``path`` is specified and the file exists, do not overwrite it.
        Defaults to false.

    raw
        Return the encoded raw bytes instead of a string. Defaults to false.

    cert_type
        The certificate type to generate. Either ``user`` or ``host``.
        Required if not specified in the signing policy.

    private_key
        The private key corresponding to the public key the certificate should
        be issued for. Either this or ``public_key`` is required.

    private_key_passphrase
        If ``private_key`` is specified and encrypted, the passphrase to decrypt it.

    public_key
        The public key the certificate should be issued for. Either this or
        ``private_key`` is required.

    signing_private_key
        The private key of the CA that should be used to sign the certificate. Required.

    signing_private_key_passphrase
        If ``signing_private_key`` is encrypted, the passphrase to decrypt it.

    serial_number
        A serial number to be embedded in the certificate. If unspecified, will
        autogenerate one. This should be an integer, either in decimal or
        hexadecimal notation.

    not_before
        Set a specific date the certificate should not be valid before.
        The format should follow ``%Y-%m-%d %H:%M:%S`` and will be interpreted as GMT/UTC.
        Defaults to the time of issuance.

    not_after
        Set a specific date the certificate should not be valid after.
        The format should follow ``%Y-%m-%d %H:%M:%S`` and will be interpreted as GMT/UTC.
        If unspecified, defaults to the current time plus ``ttl``.

    ttl
        If ``not_after`` is unspecified, a time string (like ``30d`` or ``12h``)
        or the number of seconds from the time of issuance the certificate
        should be valid for. Defaults to ``30d`` for host certificates
        and ``24h`` for client certificates.

    critical_options
        A mapping of critical option name to option value to set on the certificate.
        If an option does not take a value, specify it as ``true``.

    extensions
        A mapping of extension name to extension value to set on the certificate.
        If an extension does not take a value, specify it as ``true``.

    valid_principals
        A list of valid principals.

    all_principals
        Allow any principals. Defaults to false.

    key_id
        Specify a string-valued key ID for the signed public key.
        When the certificate is used for authentication, this value will be
        logged in plaintext.
    """
    kwargs = {k: v for k, v in kwargs.items() if not k.startswith("_")}

    if not ca_server:
        return _check_ret(
            __salt__["ssh_pki.create_certificate_ssh"](
                signing_policy=signing_policy,
                path=path,
                overwrite=overwrite,
                raw=raw,
                **kwargs,
            )
        )

    if path and not overwrite and __salt__["file.file_exists"](path):
        raise CommandExecutionError(
            f"The file at {path} exists and overwrite was set to false"
        )
    if signing_policy is None:
        raise SaltInvocationError(
            "signing_policy must be specified to request a certificate from "
            "a remote ca_server"
        )
    cert = _create_certificate_remote(ca_server, signing_policy, **kwargs)

    out = cert.public_bytes()

    if path is None:
        if raw:
            return out
        return out.decode()
    _check_ret(__salt__["file.write"](*out.decode().splitlines()))
    return f"Certificate written to {path}"


def _create_certificate_remote(
    ca_server, signing_policy, private_key=None, private_key_passphrase=None, **kwargs
):
    if private_key:
        kwargs["public_key"] = _check_ret(
            __salt__["ssh_pki.get_public_key"](
                private_key, passphrase=private_key_passphrase
            )
        )
    elif kwargs.get("public_key"):
        kwargs["public_key"] = _check_ret(
            __salt__["ssh_pki.get_public_key"](kwargs["public_key"])
        )

    result = _query_remote(ca_server, signing_policy, kwargs)
    try:
        return sshpki.load_cert(result)
    except (CommandExecutionError, SaltInvocationError) as err:
        raise CommandExecutionError(
            f"ca_server did not return a certificate: {result}"
        ) from err


def _query_remote(ca_server, signing_policy, kwargs, get_signing_policy_only=False):
    result = publish(
        ca_server,
        "ssh_pki.sign_remote_certificate",
        arg=[signing_policy, kwargs, get_signing_policy_only],
    )

    if not result:
        raise SaltInvocationError(
            "ca_server did not respond."
            " Salt master must permit peers to"
            " call the sign_remote_certificate function."
        )
    result = result[next(iter(result))]
    if not isinstance(result, dict) or "data" not in result:
        log.error(f"Received invalid return value from ca_server: {result}")
        raise CommandExecutionError(
            "Received invalid return value from ca_server. See minion log for details"
        )
    if result.get("errors"):
        raise CommandExecutionError(
            "ca_server reported errors:\n" + "\n".join(result["errors"])
        )
    return result["data"]


def _check_ret(ret):
    # Failing unwrapped calls to the minion always return a result dict
    # and do not throw exceptions currently.
    if isinstance(ret, dict) and ret.get("stderr"):
        raise CommandExecutionError(ret["stderr"])
    return ret


# The publish wrapper currently only publishes to SSH minions
# TODO: Add this to the wrapper - ssh_minions=[bool] and regular_minions=[bool]
def _publish(
    tgt,
    fun,
    arg=None,
    tgt_type="glob",
    returner="",
    timeout=5,
    form="clean",
    wait=False,
    via_master=None,
):
    masterapi = salt.daemons.masterapi.RemoteFuncs(__opts__["__master_opts__"])

    log.info("Publishing '%s'", fun)
    load = {
        "cmd": "minion_pub",
        "fun": fun,
        "arg": arg,
        "tgt": tgt,
        "tgt_type": tgt_type,
        "ret": returner,
        "tmo": timeout,
        "form": form,
        "id": __opts__["id"],
        "no_parse": __opts__.get("no_parse", []),
    }
    peer_data = masterapi.minion_pub(load)
    if not peer_data:
        return {}
    # CLI args are passed as strings, re-cast to keep time.sleep happy
    if wait:
        loop_interval = 0.3
        matched_minions = set(peer_data["minions"])
        returned_minions = set()
        loop_counter = 0
        while returned_minions ^ matched_minions:
            load = {
                "cmd": "pub_ret",
                "id": __opts__["id"],
                "jid": peer_data["jid"],
            }
            ret = masterapi.pub_ret(load)
            returned_minions = set(ret.keys())

            end_loop = False
            if returned_minions >= matched_minions:
                end_loop = True
            elif (loop_interval * loop_counter) > timeout:
                if not returned_minions:
                    return {}
                end_loop = True

            if end_loop:
                if form == "clean":
                    cret = {}
                    for host in ret:
                        cret[host] = ret[host]["ret"]
                    return cret
                else:
                    return ret
            loop_counter = loop_counter + 1
            time.sleep(loop_interval)
    else:
        time.sleep(float(timeout))
        load = {
            "cmd": "pub_ret",
            "id": __opts__["id"],
            "jid": peer_data["jid"],
        }
        ret = masterapi.pub_ret(load)
        if form == "clean":
            cret = {}
            for host in ret:
                cret[host] = ret[host]["ret"]
            return cret
        else:
            return ret
    return ret


def publish(
    tgt, fun, arg=None, tgt_type="glob", returner="", timeout=5, via_master=None
):
    """
    Publish a command from the minion out to other minions.

    Publications need to be enabled on the Salt master and the minion
    needs to have permission to publish the command. The Salt master
    will also prevent a recursive publication loop, this means that a
    minion cannot command another minion to command another minion as
    that would create an infinite command loop.

    The ``tgt_type`` argument is used to pass a target other than a glob into
    the execution, the available options are:

    - glob
    - pcre
    - grain
    - grain_pcre
    - pillar
    - pillar_pcre
    - ipcidr
    - range
    - compound

    .. versionchanged:: 2017.7.0
        The ``expr_form`` argument has been renamed to ``tgt_type``, earlier
        releases must use ``expr_form``.

    Note that for pillar matches must be exact, both in the pillar matcher
    and the compound matcher. No globbing is supported.

    The arguments sent to the minion publish function are separated with
    commas. This means that for a minion executing a command with multiple
    args it will look like this:

    .. code-block:: bash

        salt system.example.com publish.publish '*' user.add 'foo,1020,1020'
        salt system.example.com publish.publish 'os:Fedora' network.interfaces '' grain

    CLI Example:

    .. code-block:: bash

        salt system.example.com publish.publish '*' cmd.run 'ls -la /tmp'


    .. admonition:: Attention

        If you need to pass a value to a function argument and that value
        contains an equal sign, you **must** include the argument name.
        For example:

        .. code-block:: bash

            salt '*' publish.publish test.kwarg arg='cheese=spam'

        Multiple keyword arguments should be passed as a list.

        .. code-block:: bash

            salt '*' publish.publish test.kwarg arg="['cheese=spam','spam=cheese']"


    When running via salt-call, the `via_master` flag may be set to specific which
    master the publication should be sent to. Only one master may be specified. If
    unset, the publication will be sent only to the first master in minion configuration.
    """
    return _publish(
        tgt,
        fun,
        arg=arg,
        tgt_type=tgt_type,
        returner=returner,
        timeout=timeout,
        form="clean",
        wait=True,
        via_master=via_master,
    )
