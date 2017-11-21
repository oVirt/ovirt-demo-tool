#!/bin/bash -ex

readonly REPO_ROOT="$PWD"
readonly ARTIFACTS_DIR="${REPO_ROOT}/exported-artifacts"
readonly LOGS_DIR="${ARTIFACTS_DIR}/logs"
DO_CLEANUP=false
COPY_TO_REMOTE=false

# Add specific functions and variabels
source deploy/control.sh
source utils/logger.sh

env_cleanup() {

    local res=0
    local uuid

    logger.info "Cleaning up"
    if [[ -e "$PREFIX" ]]; then
        logger.info "Cleaning with lago"
        lago --workdir "$PREFIX" destroy --yes --all-prefixes \
        || res=$?
        logger.success "Cleaning with lago done"
    elif [[ -e "$PREFIX/uuid" ]]; then
        uid="$(cat "$PREFIX/uuid")"
        uid="${uid:0:4}"
        res=1
    else
        logger.info "No uuid found, cleaning up any lago-generated vms"
        res=1
    fi
    if [[ "$res" != "0" ]]; then
        logger.info "Lago cleanup did not work (that is ok), forcing libvirt"
        env_libvirt_cleanup "$SUITE_NAME" "$uid"
    fi
    logger.success "Cleanup done"
}


env_libvirt_cleanup() {
    local suite="${1?}"
    local uid="${2}"
    local domain
    local net
    if [[ "$uid" != "" ]]; then
        local domains=($( \
            virsh -c qemu:///system list --all --name \
            | egrep "$uid*" \
        ))
        local nets=($( \
            virsh -c qemu:///system net-list --all \
            | egrep "$uid*" \
            | awk '{print $1;}' \
        ))
    else
        local domains=($( \
            virsh -c qemu:///system list --all --name \
            | egrep "[[:alnum:]]*-lago-${suite}-" \
            | egrep -v "vdsm-ovirtmgmt" \
        ))
        local nets=($( \
            virsh -c qemu:///system net-list --all \
            | egrep -w "[[:alnum:]]{4}-.*" \
            | egrep -v "vdsm-ovirtmgmt" \
            | awk '{print $1;}' \
        ))
    fi
    logger.info "Cleaning with libvirt"
    for domain in "${domains[@]}"; do
        virsh -c qemu:///system destroy "$domain"
    done
    for net in "${nets[@]}"; do
        virsh -c qemu:///system net-destroy "$net"
    done
    logger.success "Cleaning with libvirt Done"
}

get_version() {
    : '
        The scheme is as follows:
        [oVirt_version]-[image_version].revision

        This function will modify the output of git describe
        to match the scheme above.

        example:
        4.2.0-0-1-g9577328 -> 4.2.0-0.1.g9577328
        4.2.0-1 -> 4.2.0-0.0
    '
    local version="$(git describe --tags)"
    local prefix="${version%%-*}"
    local suffix="${version#*-}"
    if [[ "$suffix" =~ ^[0-9]+$ ]]; then
        suffix="0.0"
    else
        suffix="${suffix//-/.}"
    fi

    echo "${prefix}-${suffix}"
}

env_init () {
    local template_repo="${1:?}"
    local initfile="${2:?}"

    lago init \
        "$PREFIX" \
        "$initfile" \
        --template-repo-path "$template_repo"
}

render_jinja_templates () {
    local in="${1:?}"
    local out="${2:?}"

    python \
        "${REPO_ROOT}/utils/render_jinja_templates.py" \
        "$in" > "$out"
    }

env_start() {
    cd "$PREFIX"
    lago start
    cd -
}

env_stop() {
    cd "$PREFIX"
    lago stop
    cd -
}

env_destroy() {
    lago --workdir "$PREFIX" destroy -y --all-prefixes
}

env_create_images() {
    local export_dir="${1:?}"
    local archive_name="${2:?}.tar.xz"
    local checksum_name="${archive_name}.md5"

    [[ -e "$export_dir" ]] || mkdir -p "$export_dir"

    cd "$PREFIX"
    lago --out-format yaml \
        export \
        --dst-dir "$export_dir" \
        --standalone
    cd -
    cd $export_dir
    python "${REPO_ROOT}/utils/modify_init.py" LagoInitFile
    local files=($(ls "$export_dir"))
    tar -cvS "${files[@]}" | xz -T 0 -v --stdout > "$archive_name"
    md5sum "$archive_name" > "$checksum_name"
    md5sum -c "$checksum_name"
    rm -f "${files[@]}"
    cd -
}

export_env() {
    local export_dir="${1:?}"
    local archive_name="${2:?}"
    local failed=false

    env_create_images "$export_dir" "$archive_name" || failed=true
    copy_lago_log "$LOGS_DIR/export"
    if $failed; then
        echo "Failed to export env"
        return 1
    fi
}

env_deploy () {
    cd "$PREFIX"
    lago deploy
    cd -
}

env_status () {
    cd "$PREFIX"
    lago status
    cd -
}

env_collect () {
    local tests_out_dir="${1?}"

    [[ -e "$tests_out_dir" ]] || mkdir -p "${tests_out_dir%/*}"

    cd "$PREFIX"
    lago collect --output "$tests_out_dir"
    mv_junit_xml "$tests_out_dir"
    copy_lago_log "$tests_out_dir/lago_logs"
    cd -
}

mv_junit_xml() {
    local dest="${1:?}"

    [[ -e "$dest" ]] || mkdir -p "$dest"

    find "${PREFIX}/current" \
        -name "*.junit.xml" \
        -exec mv {} "$dest" \;
}

copy_lago_log() {
    local dest="${1:?}"

    [[ -e "$dest" ]] || mkdir -p "$dest"

    cd "$PREFIX"
        cp -a "current/logs" "$dest"
    cd -
}

do_copy_to_remote() {
    # $SSH_KEY is injected by jenkins
    local src=${1:?}
    (
        set +x
        echo "$SSH_KEY" > key
    )
    chmod 600 key
    scp -i key -r -o 'StrictHostKeyChecking=no' \
    "$src" \
    "${SRV_USERNAME}@${SRV_HOSTNAME}:${SRV_PATH}"
}

main() {
    local version="$(get_version)"
    local export_dir="${REPO_ROOT}/${version}"
    local artifact_name="${SUITE_NAME}-${version}"

    logger.info "Building images"
    control.deploy
    export_env "$export_dir" "$artifact_name"
    env_destroy
    logger.info "Testing images"
    control.test "${export_dir}/${artifact_name}.tar.xz"

    if "$COPY_TO_REMOTE"; then
        logger.info Copy images to remote server
        do_copy_to_remote "$export_dir"
    fi
    logger.success 'Success :)'
}
options=$( \
    getopt \
        -o co: \
        --long cleanup,output:,copy-to-remote \
        -n 'create_env.sh' \
        -- "$@" \
)
if [[ "$?" != "0" ]]; then
    exit 1
fi
eval set -- "$options"

while true; do
    case $1 in
        -c|--cleanup)
            readonly DO_CLEANUP=true
            shift
            ;;
        -o|--output)
            PREFIX=$(realpath $2)
            shift 2
            ;;
        --copy-to-remote)
            readonly COPY_TO_REMOTE=true
            shift
            ;;
        --)
            shift
            break
            ;;
    esac
done

PREFIX="${PREFIX:-"${REPO_ROOT}/.lago"}"
if "$DO_CLEANUP"; then
    env_cleanup
    exit $?
fi

main
