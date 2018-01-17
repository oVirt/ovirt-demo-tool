#!/bin/bash -ex

readonly DEPLOY="$(realpath "$(dirname $BASH_SOURCE)")"
source "${DEPLOY}/control_config.sh"

env_run_test () {
    local res=0
    cd $PREFIX
    lago ovirt runtest $1 || res=$?
    cd -
    return "$res"
}

env_run_tests () {
    local tests_dir="${1:?}"
    local stage="${2:?}"
    local test_scenarios=($(ls "${tests_dir}/"*.py | sort))
    local failed=false
    local logs_dir="${LOGS_DIR}/${stage}"
    export PYTHONPATH="${PYTHONPATH}:${DEPLOY}"

    for scenario in "${test_scenarios[@]}"; do
        echo "Running test scenario ${scenario##*/}"
        env_run_test "$scenario" || failed=true
        env_collect "${logs_dir}/post-${scenario##*/}"
        if $failed; then
            echo "@@@@ ERROR: Failed running $scenario"
            return 1
        fi
    done
}

run_sdk_deploy_scripts() {
    SUITE="$SUITE_NAME" \
    ENGINE_ANSWER_FILE="${DEPLOY}/engine-answer-file.conf" \
        env_run_tests \
            "${DEPLOY}/sdk_scripts/deploy" \
            "sdk_deploy"
}

run_sdk_test_scripts() {
    SUITE="$SUITE_NAME" \
        env_run_tests \
            "${DEPLOY}/sdk_scripts/test" \
            "sdk_test"
}

env_ovirt_start() {
    cd $PREFIX
    lago ovirt start
    cd -
}

env_ovirt_stop () {
    cd $PREFIX
    lago ovirt stop
    cd -
}

env_configure_extra_repos() {
    local repos_file="${DEPLOY}/extra_repos.repo"

    ! [[ -f "$repos_file" ]] && return 0

    cd "$PREFIX"
    for vm in $(env_list_running_vms); do
        lago copy-to-vm "$vm" "$repos_file" "/etc/yum.repos.d/"
    done
    cd -
}

control.deploy() {
    suite_name="$SUITE_NAME" \
    engine_template="$ENGINE_TEMPLATE" \
    host_template="$HOST_TEMPLATE" \
    host_count="$HOST_COUNT" \
        render_jinja_templates \
            "${DEPLOY}/LagoInitFile.in" \
            "${DEPLOY}/LagoInitFile" \
            "$SUITE_NAME"

    release_rpm="$RELEASE_RPM" \
        render_jinja_templates \
            "${DEPLOY}/shell_scripts/install_release_rpm.sh.in" \
            "${DEPLOY}/shell_scripts/install_release_rpm.sh"

    env_init "$TEMPLATE_REPO_PATH" "${DEPLOY}/LagoInitFile"
    env_start
    env_configure_extra_repos
    env_deploy
    run_sdk_deploy_scripts
    sleep 15
    env_ovirt_stop
}

control.test() {
    local archive="${1:?}"
    local test_dir="${REPO_ROOT}/test_env"
    local failed=false
    PREFIX="${test_dir}/.lago"

    mkdir "$test_dir"
    cd "$test_dir"
    xz --decompress --stdout "$archive" | tar -xv

    env_init "$TEMPLATE_REPO_PATH" "${test_dir}/LagoInitFile"
    env_ovirt_start || failed=true
    env_collect "${LOGS_DIR}/test_start_env"
    if "$failed"; then
        logger.error "Failed to start exported env"
        exit 1
    fi
    sleep 30
    run_sdk_test_scripts
    env_stop
    cd "$REPO_ROOT"
}
