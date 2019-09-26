#!/bin/bash

# _is_sourced tests whether this script is being source, or executed directly
_is_sourced() {
  # https://unix.stackexchange.com/a/215279
  # thanks @tianon
  [ "${FUNCNAME[${#FUNCNAME[@]} - 1]}" == 'source' ]
}

_usage() {
    echo "... just read the code"
}

_release_base() {
    echo "${1}" | cut -d - -f 1
}

_fetch_file_list() {
    local mirror="${1}"
    local release="${2}"
    local ret

    curl -sSL "${mirror}/${release}/$(_release_base "${release}")/FILE_LIST"
    ret=$?
    if [ $ret -ne 0 ] ; then
        return $ret
    fi
}

_sections_from_file_list() {
    local file_list="${1}"
    local ret
    grep '/tagfile$' "${file_list}" | awk '{ print $8 }' | sed -e 's|./\([[:alpha:]]*\)/tagfile$|\1|g'
    ret=$?
    if [ $ret -ne 0 ] ; then
        return $ret
    fi
}

_fetch_tagfile() {
    local mirror="${1}"
    local release="${2}"
    local section="${3}"
    local ret

    curl -sSL "${mirror}/${release}/$(_release_base "${release}")/${section}/tagfile"
    ret=$?
    if [ $ret -ne 0 ] ; then
        return $ret
    fi
}

main() {
    local mirror
    local release
    local tmp_file_list
    local ret

    mirror="${MIRROR:-http://slackware.osuosl.org}"
    release="${RELEASE:-slackware64-current}"

    while getopts ":hm:r:t" opts ; do
        case "${opts}" in
            m)
                mirror="${OPTARG}"
                ;;
            r)
                release="${OPTARG}"
                ;;
            t)
                fetch_tagfiles=1
                ;;
            *)
                _usage
                exit 1
                ;;
        esac
    done
    shift $((OPTIND-1))
    
    tmp_dir="$(mktemp -d)"
    tmp_file_list="${tmp_dir}/FILE_LIST"
    _fetch_file_list "${mirror}" "${release}" > "${tmp_file_list}"
    ret=$?
    if [ $ret -ne 0 ] ; then
        echo "ERROR fetching FILE_LIST" >&2
        exit $ret
    fi
    
    if [ -n "${fetch_tagfiles}" ] ; then
        for section in $(_sections_from_file_list "${tmp_file_list}") ; do
            mkdir -p "${tmp_dir}/${section}"
            _fetch_tagfile "${mirror}" "${release}" "${section}" > "${tmp_dir}/${section}/tagfile"
            if [ $ret -ne 0 ] ; then
                echo "ERROR fetching ${section}/tagfile" >&2
                exit $ret
            fi
        done
    fi
    
    grep '\.t.z$' "${tmp_file_list}" | awk '{ print $8 }' | sed -e 's|\./\(.*\.t.z\)$|\1|g'
}

_is_sourced || main "${@}"

# vim:set shiftwidth=4 softtabstop=4 expandtab:
