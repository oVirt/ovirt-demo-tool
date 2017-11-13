#!/bin/bash -xe

cleanup() {
    ./create_env.sh --cleanup
    exit
}

# needed to run lago inside chroot
export LIBGUESTFS_BACKEND=direct
# ensure /dev/kvm exists, otherwise it will still use
# direct backend, but without KVM(much slower).
! [[ -c "/dev/kvm" ]] && mknod /dev/kvm c 10 232
# uncomment the next lines for extra verbose output
export LIBGUESTFS_DEBUG=1 LIBGUESTFS_TRACE=1
extra_args=()

trap 'cleanup' SIGTERM SIGINT SIGQUIT EXIT SIGHUP

if [[ ${0##*/} == check-merged.sh ]]; then
    extra_args+=("--copy-to-remote")
fi

./create_env.sh "${extra_args[@]}"
