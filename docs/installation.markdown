# Setting up the system

## System requirements

### Operating System

Currently Orb can run on either supported Fedora versions or Centos 7.

### CPU

Orb is currently supported on Intel's CPUs.
The CPU model should be `Sandy Bridge` or newer.

### Disk Space

Orb requires that you have at least 7GB of free space wherever you
are running it.

### Memory

Orb requires that your system will have at least 8GB of RAM.

## Installation

### Install Lago

[Lago installation manual]

### Install Lago oVirt plugin

[Lago oVirt plugin installation manual]

**NOTE:** This step is not needed if you installed Lago with the install script.

### Install oVirt-engine Python SDK v4

TBD

### Download and extract Orb

Download the required version of [Orb]. Make sure to also download the md5 file.

Verify the download file with md5sum:

```bash
md5sum -c [Orb version].tar.xz.md5
```

You should see the following message on screen:

```bash
[Orb version].tar.xz: OK
```

If you don't see this message, please try again to download Orb.

Extract Orb:

```bash
xz --decompress --stdout [Orb version].tar.xz | tar -xv
```

You are now ready to [run] Orb !

[Lago installation manual]: http://lago.readthedocs.io/en/latest/Installation.html
[Lago oVirt plugin installation manual]: http://lago-ost-plugin.readthedocs.io/en/latest/Installation.html
[Orb]: http://templates.ovirt.org/bundles/ovirt-demo-tool/
[run]: run.markdown
[oVirt supported CPU list]: https://www.ovirt.org/documentation/install-guide/chap-System_Requirements/#hypervisor-requirements
