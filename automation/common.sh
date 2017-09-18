env_cleanup() {

    local res=0
    local uuid
    local PREFIX=".lago"


    echo "Cleaning up"
    if [[ -e "$PREFIX" ]]; then
        echo "Cleaning with lago"
        lago --workdir-path "$PREFIX" destroy --yes --all-prefixes \
        || res=$?
        echo "Cleaning with lago done"
    elif [[ -e "$PREFIX/uuid" ]]; then
        uid="$(cat "$PREFIX/uuid")"
        uid="${uid:0:4}"
        res=1
    else
        echo "No uuid found, cleaning up any lago-generated vms"
        res=1
    fi
    if [[ "$res" != "0" ]]; then
        echo "Lago cleanup did not work (that is ok), forcing libvirt"
        env_libvirt_cleanup "basic-suite-4-1" "$uid"
    fi
    echo "Cleanup done"
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
            | egrep "[[:alnum:]]{4}-.*" \
            | egrep -v "vdsm-ovirtmgmt" \
            | awk '{print $1;}' \
        ))
    fi
    echo "Cleaning with libvirt"
    for domain in "${domains[@]}"; do
        virsh -c qemu:///system destroy "$domain"
    done
    for net in "${nets[@]}"; do
        virsh -c qemu:///system net-destroy "$net"
    done
    echo "Cleaning with libvirt Done"
}
