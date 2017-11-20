#!/bin/bash -xe
source utils/logger.sh

cleanup() {
    ./create_env.sh --cleanup
    exit
}

code_changed() {
    if ! [[ -d .git ]]; then
        echo "Not in a git dir, will run all the tests"
        return 0
    fi
    git diff-tree --no-commit-id --name-only -r HEAD..HEAD^ \
    | grep -qvE 'docs/|index\.html'
    return $?
}

run_create_docs() {
    local artifacts_dir=exported-artifacts

    logger.info "Creating Docs"
    [[ -d "$artifacts_dir" ]] || mkdir "$artifacts_dir"
    source "${0%/*}/create-docs.sh"
    create_docs.create_docs "${artifacts_dir}/docs-out"
    cp utils/index.html "$artifacts_dir"
}

# needed to run lago inside chroot
export LIBGUESTFS_BACKEND=direct
# ensure /dev/kvm exists, otherwise it will still use
# direct backend, but without KVM(much slower).
! [[ -c "/dev/kvm" ]] && mknod /dev/kvm c 10 232
# uncomment the next lines for extra verbose output
export LIBGUESTFS_DEBUG=1 LIBGUESTFS_TRACE=1
extra_args=()
create_docs=false

trap 'cleanup' SIGTERM SIGINT SIGQUIT EXIT SIGHUP

if [[ ${0##*/} == check-merged.sh ]]; then
    extra_args+=("--copy-to-remote")
else
    create_docs=true
fi

if code_changed; then
    ./create_env.sh "${extra_args[@]}"
else
    logger.info "No code changes has been made"
fi

if "$create_docs"; then
    run_create_docs
fi
