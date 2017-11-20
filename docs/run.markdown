# Running Orb

Make sure to first install Orb.
After installing Orb, you should have a directory similar to this:

```bash
gbenhaim ~/orb (master)
> ll
total 7797580
-rw-r--r--. 1 gbenhaim gbenhaim         3385 Nov 22 18:28 LagoInitFile
-rw-r--r--. 1 gbenhaim gbenhaim 108447924224 Nov 22 18:25 lago-ovirt-orb-master-engine_iscsi.raw
-rw-r--r--. 1 gbenhaim gbenhaim           40 Nov 22 18:28 lago-ovirt-orb-master-engine_iscsi.raw.hash
-rw-r--r--. 1 gbenhaim gbenhaim          149 Nov 22 18:28 lago-ovirt-orb-master-engine_iscsi.raw.metadata
-rw-r--r--. 1 gbenhaim gbenhaim 108447924224 Nov 22 18:25 lago-ovirt-orb-master-engine_nfs.raw
-rw-r--r--. 1 gbenhaim gbenhaim           40 Nov 22 18:28 lago-ovirt-orb-master-engine_nfs.raw.hash
-rw-r--r--. 1 gbenhaim gbenhaim          147 Nov 22 18:28 lago-ovirt-orb-master-engine_nfs.raw.metadata
-rw-r--r--. 1 gbenhaim gbenhaim   2489057280 Nov 22 18:25 lago-ovirt-orb-master-engine_root.qcow2
-rw-r--r--. 1 gbenhaim gbenhaim           40 Nov 22 18:26 lago-ovirt-orb-master-engine_root.qcow2.hash
-rw-r--r--. 1 gbenhaim gbenhaim          754 Nov 22 18:26 lago-ovirt-orb-master-engine_root.qcow2.metadata
-rw-r--r--. 1 gbenhaim gbenhaim   1837236224 Nov 22 18:25 lago-ovirt-orb-master-host-0_root.qcow2
-rw-r--r--. 1 gbenhaim gbenhaim           40 Nov 22 18:26 lago-ovirt-orb-master-host-0_root.qcow2.hash
-rw-r--r--. 1 gbenhaim gbenhaim          754 Nov 22 18:26 lago-ovirt-orb-master-host-0_root.qcow2.metadata
-rw-r--r--. 1 gbenhaim gbenhaim   1844838400 Nov 22 18:25 lago-ovirt-orb-master-host-1_root.qcow2
-rw-r--r--. 1 gbenhaim gbenhaim           40 Nov 22 18:26 lago-ovirt-orb-master-host-1_root.qcow2.hash
-rw-r--r--. 1 gbenhaim gbenhaim          754 Nov 22 18:26 lago-ovirt-orb-master-host-1_root.qcow2.metadata
-rw-rw-r--. 1 gbenhaim gbenhaim   1951817440 Nov 22 18:53 ovirt-orb-master-0.3.g339ad5e.tar.xz
-rw-rw-r--. 1 gbenhaim gbenhaim           71 Nov 22 18:53 ovirt-orb-master-0.3.g339ad5e.tar.xz.md5
```

All the following commands should be run inside this directory.

- Bootstrap Orb:

```bash
lago init
```

- Start Orb:

```bash
lago ovirt start
```

On the screen you should see oVirt engine's IP, username, and password.

You can enter to the web UI by entering the engine's IP in your browser.

- Stop Orb

```bash
lago ovirt stop
```

- If you want to recreate Orb, run the following and bootstrap Orb again.

```bash
lago destroy
```

[install]: installation.markdown
