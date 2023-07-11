Available states
----------------

The following states are found in this formula:

.. contents::
   :local:


``openssh``
^^^^^^^^^^^
*Meta-state*.

This includes everything from the `openssh.server`_ and
`openssh.client`_ meta states.


``openssh.server``
^^^^^^^^^^^^^^^^^^
*Meta-state*.

This installs the OpenSSH server package,
manages its global configuration plus host keys/certificates
as well as per-user authorized keys and trusted user CA keys.
Will also manage (start/stop) the service, depending on the value in
``openssh:server:running``.


``openssh.server.authorized_keys``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Manages OpenSSH authorized keys.
If ``TrustedUserCAKeys`` has been specified in the server
configuration (``openssh:server:config``), all CA keys from
``openssh:server:trusted_user_ca_keys`` will be serialized
into the corresponding file as well.
Has a dependency on `openssh.server.package`_.


``openssh.server.config``
^^^^^^^^^^^^^^^^^^^^^^^^^
Manages the OpenSSH service configuration, including
AuthorizedPrincipalsFile and moduli if ``openssh:server:moduli``
was set to true.
Has a dependency on `openssh.server.package`_.


``openssh.server.keys``
^^^^^^^^^^^^^^^^^^^^^^^
Manages OpenSSH host private/public keys and certificates.
Has a dependency on `openssh.server.package`_.


``openssh.server.package``
^^^^^^^^^^^^^^^^^^^^^^^^^^
Installs the OpenSSH server package only.


``openssh.server.service``
^^^^^^^^^^^^^^^^^^^^^^^^^^
Starts the OpenSSH service and enables it at boot time.
Has a dependency on `openssh.server.config`_.


``openssh.client``
^^^^^^^^^^^^^^^^^^
*Meta-state*.

This installs the OpenSSH client package,
manages its global configuration plus globally
trusted host certificate authorities and
manages per-user client keys and certificates.


``openssh.client.config``
^^^^^^^^^^^^^^^^^^^^^^^^^
Manages the OpenSSH client configuration.
Has a dependency on `openssh.client.package`_.


``openssh.client.keys``
^^^^^^^^^^^^^^^^^^^^^^^
Manages OpenSSH user private/public keys and certificates.
Has a dependency on `openssh.client.package`_.


``openssh.client.package``
^^^^^^^^^^^^^^^^^^^^^^^^^^
Installs the OpenSSH client package only.


``openssh.client.trusted_cas``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Manages **globally** trusted OpenSSH certificate authorities for host certificates.
Has a dependency on `openssh.client.package`_.


``openssh.clean``
^^^^^^^^^^^^^^^^^
*Meta-state*.

Undoes everything performed in the `openssh.server`_ and
`openssh.client`_ meta states.


``openssh.server.clean``
^^^^^^^^^^^^^^^^^^^^^^^^
*Meta-state*.

Undoes everything performed in the ``openssh.server`` meta-state
in reverse order, i.e.
stops the OpenSSH server,
removes host keys and certificates,
removes per-user authorized keys,
removes trusted client certificate authorities,
removes the global OpenSSH server configuration file and then
uninstalls the package.


``openssh.server.authorized_keys.clean``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Removes managed OpenSSH authorized keys and trusted user CA keys.


``openssh.server.config.clean``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Removes the configuration of the OpenSSH service, including
AuthorizedPrincipalsFile, and has a dependency on
`openssh.server.service.clean`_.
Does not remove managed moduli.


``openssh.server.keys.clean``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Removes managed OpenSSH host private/public keys and certificates.
Has a dependency on `openssh.server.service.clean`_.


``openssh.server.package.clean``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Removes the OpenSSH server package.
Has a dependency on `openssh.server.config.clean`_.


``openssh.server.service.clean``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Stops the OpenSSH service and disables it at boot time.


``openssh.client.clean``
^^^^^^^^^^^^^^^^^^^^^^^^
*Meta-state*.

Undoes everything performed in the ``openssh.client`` meta-state
in reverse order, i.e.
**removes per-user client keys** and certificates,
removes globally trusted host certificate authorities,
removes the global OpenSSH client configuration file and then
uninstalls the package.


``openssh.client.config.clean``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Removes the configuration of the OpenSSH client.


``openssh.client.keys.clean``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Removes managed OpenSSH user private/public keys and certificates.


``openssh.client.package.clean``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Removes the OpenSSH client package.
Has a dependency on `openssh.client.config.clean`_.


``openssh.client.trusted_cas.clean``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Removes globally trusted OpenSSH certificate authorities for host certificates.


