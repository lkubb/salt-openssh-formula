.. _readme:

OpenSSH Formula
===============

|img_sr| |img_pc|

.. |img_sr| image:: https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg
   :alt: Semantic Release
   :scale: 100%
   :target: https://github.com/semantic-release/semantic-release
.. |img_pc| image:: https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white
   :alt: pre-commit
   :scale: 100%
   :target: https://github.com/pre-commit/pre-commit

Manage OpenSSH with Salt. Includes modules to create and use a private SSH CA, very similar to ``x509_v2``.

.. contents:: **Table of Contents**
   :depth: 1

General notes
-------------

See the full `SaltStack Formulas installation and usage instructions
<https://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html>`_.

If you are interested in writing or contributing to formulas, please pay attention to the `Writing Formula Section
<https://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html#writing-formulas>`_.

If you want to use this formula, please pay attention to the ``FORMULA`` file and/or ``git tag``,
which contains the currently released version. This formula is versioned according to `Semantic Versioning <http://semver.org/>`_.

See `Formula Versioning Section <https://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html#versioning>`_ for more details.

If you need (non-default) configuration, please refer to:

- `how to configure the formula with map.jinja <map.jinja.rst>`_
- the ``pillar.example`` file
- the `Special notes`_ section

Special notes
-------------
* This formula includes custom modules that apply the principle of the official ``x509_v2`` modules to OpenSSH certificates.

Configuration
-------------
An example pillar is provided, please see `pillar.example`. Note that you do not need to specify everything by pillar. Often, it's much easier and less resource-heavy to use the ``parameters/<grain>/<value>.yaml`` files for non-sensitive settings. The underlying logic is explained in `map.jinja`.


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
Manages the OpenSSH service configuration, including moduli
if ``openssh:server:moduli`` was set to true.
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
Removes the configuration of the OpenSSH service and has a
dependency on `openssh.server.service.clean`_.
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



Contributing to this repo
-------------------------

Commit messages
^^^^^^^^^^^^^^^

**Commit message formatting is significant!**

Please see `How to contribute <https://github.com/saltstack-formulas/.github/blob/master/CONTRIBUTING.rst>`_ for more details.

pre-commit
^^^^^^^^^^

`pre-commit <https://pre-commit.com/>`_ is configured for this formula, which you may optionally use to ease the steps involved in submitting your changes.
First install  the ``pre-commit`` package manager using the appropriate `method <https://pre-commit.com/#installation>`_, then run ``bin/install-hooks`` and
now ``pre-commit`` will run automatically on each ``git commit``. ::

  $ bin/install-hooks
  pre-commit installed at .git/hooks/pre-commit
  pre-commit installed at .git/hooks/commit-msg

State documentation
~~~~~~~~~~~~~~~~~~~
There is a script that semi-autodocuments available states: ``bin/slsdoc``.

If a ``.sls`` file begins with a Jinja comment, it will dump that into the docs. It can be configured differently depending on the formula. See the script source code for details currently.

This means if you feel a state should be documented, make sure to write a comment explaining it.

Testing
-------

Linux testing is done with ``kitchen-salt``.

Requirements
^^^^^^^^^^^^

* Ruby
* Docker

.. code-block:: bash

   $ gem install bundler
   $ bundle install
   $ bin/kitchen test [platform]

Where ``[platform]`` is the platform name defined in ``kitchen.yml``,
e.g. ``debian-9-2019-2-py3``.

``bin/kitchen converge``
^^^^^^^^^^^^^^^^^^^^^^^^

Creates the docker instance and runs the ``openssh`` main state, ready for testing.

``bin/kitchen verify``
^^^^^^^^^^^^^^^^^^^^^^

Runs the ``inspec`` tests on the actual instance.

``bin/kitchen destroy``
^^^^^^^^^^^^^^^^^^^^^^^

Removes the docker instance.

``bin/kitchen test``
^^^^^^^^^^^^^^^^^^^^

Runs all of the stages above in one go: i.e. ``destroy`` + ``converge`` + ``verify`` + ``destroy``.

``bin/kitchen login``
^^^^^^^^^^^^^^^^^^^^^

Gives you SSH access to the instance for manual testing.

References
----------
* https://infosec.mozilla.org/guidelines/openssh
* https://stribika.github.io/2015/01/04/secure-secure-shell.html
* https://ssh-comparison.quendi.de/
* https://www.linode.com/docs/guides/advanced-ssh-server-security/
* https://smallstep.com/blog/clever-uses-of-ssh-certificate-templates/
