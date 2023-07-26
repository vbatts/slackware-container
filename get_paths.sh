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
    echo "${1}" | cut -d - -f 1 | sed 's/armedslack/slackware/;s/slackwarearm/slackware/;s/slackwareaarch64/slackware/'
}

_fetch_file_list() {
    local mirror="${1}"
    local release="${2}"
    local directory="${3}"
    local ret

    curl -sSL "${mirror}/${release}/${directory}/FILE_LIST"
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

    while getopts ":hm:r:tpe" opts ; do
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
            p)
                fetch_patches=1
                ;;
            e)
                fetch_extra=1
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
    if [ -n "${fetch_patches}" ] ; then
        _fetch_file_list "${mirror}" "${release}" "patches" >> "${tmp_file_list}"
        ret=$?
        if [ $ret -ne 0 ] ; then
            echo "ERROR fetching FILE_LIST" >&2
            exit $ret
        fi
    elif [ -n "${fetch_extra}" ] ; then
        _fetch_file_list "${mirror}" "${release}" "extra" >> "${tmp_file_list}"
        ret=$?
        if [ $ret -ne 0 ] ; then
            echo "ERROR fetching FILE_LIST" >&2
            exit $ret
        fi
    else
        _fetch_file_list "${mirror}" "${release}" "$(_release_base "${release}")" > "${tmp_file_list}"
        ret=$?
        if [ $ret -ne 0 ] ; then
            echo "ERROR fetching FILE_LIST" >&2
            exit $ret
        fi
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

    grep '\.t.z$' "${tmp_file_list}" | awk '{ print $(NF) }' | sed -e 's|\./\(.*\.t.z\)$|\1|g'
}

_is_sourced || main "${@}"

# vim:set shiftwidth=4 softtabstop=4 expandtab:
