#!/bin/bash -xe
source "${0%/*}/common.sh"

cleanup() {
    env_cleanup
    exit
}

# needed to run lago inside chroot
export LIBGUESTFS_BACKEND=direct
# ensure /dev/kvm exists, otherwise it will still use
# direct backend, but without KVM(much slower).
! [[ -c "/dev/kvm" ]] && mknod /dev/kvm c 10 232
# uncomment the next lines for extra verbose output
export LIBGUESTFS_DEBUG=1 LIBGUESTFS_TRACE=1

trap 'cleanup "$run_path"' SIGTERM SIGINT SIGQUIT EXIT

suite_path="$(realpath deploy)"
# For testing outside of jenkins
export BUILD_NUMBER="${BUILD_NUMBER:-1}"

if [[ ${0##*/} == check-patch.sh ]]; then
    skip_tags="deploy-to-repo"
fi

ANSIBLE_CONFIG=ansible.cfg \
    ansible-playbook \
        -i inventory \
        -u root \
        --skip-tags="$skip_tags" \
        -e "repo_root=${PWD} suite_path=${suite_path}" \
        -v \
        create-env-playbook.yaml
