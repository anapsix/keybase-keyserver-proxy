#!/usr/bin/env bash
set -u
set -o pipefail

info() {
  if [[ ${TIMESTAMP:-0} -eq 1 ]]; then
    TIME="[$(date)]"
  fi
  echo >&2 -e "${TIME:-}[\e[92mINFO\e[0m] $@"
}

debug() {
  if [[ ${DEBUG:-0} -eq 1 ]]; then
    if [[ ${TIMESTAMP:-0} -eq 1 ]]; then
      TIME="[$(date)]"
    fi
    echo >&2 -e "${TIME:-}[\e[95mDEBUG\e[0m] $@"
  fi
}

error() {
  local msg="$1"
  local exit_code="${2:-1}"
  if [[ ${TIMESTAMP:-0} -eq 1 ]]; then
    TIME="[$(date)]"
  fi
  echo >&2 -e "${TIME:-}[\e[91mERROR\e[0m] $1"
  if [[ "${exit_code}" != "-" ]]; then
    exit ${exit_code}
  fi
}

getval() {
  local x="${1%%=*}"
  if [[ "$x" = "$1" ]]; then
    echo "${2}"
    return 2
  else
    echo "${1##*=}"
    return 1
  fi
}

usage() {
cat <<EOM

PGP encrypt file using GPG.
Usage: $0 [flags] /path/to/secrets.file

  FLAGS:
    -h|--help|--usage   displays usage
    -v|--debug          display debug output
    -t|--timestamp      include timestamp in debug output
    -a|--asc|--armor    create ASCII armored output, binary used by default
    -r|--recipients     recipients file
                        by default, searching for .recipients file in same
                        directory as "secrets.file"
EOM
}

## Get CLI arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help|--usage)
      usage
      exit 0
    ;;
    -v|--debug)
      DEBUG=1
      shift 1
    ;;
    -t|--timestamp)
      TIMESTAMP=1
      shift 1
    ;;
    -a|--asc|--armor)
      ARMOR="--armor"
      shift 1
    ;;
    -r|--recipients|--recipients=*)
      recipients_file="$(getval "$1" "${2:-}")"
      shift $?
    ;;
    -*)
      error "Unexpected option \"$1\"" -
      usage
      exit 1
    ;;
    *)
      if [[ -n "${secrets_file:-}" ]]; then
        error "Only one file argument supported, exiting.."
      fi
      secrets_file="$1"
      shift 1
    ;;
  esac
done

# start catching all error
set -e

check_bin() {
  if ! which "$1" >/dev/null; then
    error "$1 binary not found, exiting.."
  fi
}

check_bin "gpg"

if [[ -z "${secrets_file:-}" ]]; then
  error "Need secrets file to encrypt.." -
  usage
  exit 1
fi
debug "Secrets file: ${secrets_file}"
if [[ ! -r "${secrets_file}" ]]; then
  error "Unable to read secrets file \"${secrets_file}\", exiting.."
fi

if [[ -z "${recipients_file:-}" ]]; then
  debug "Recipients file not set, discovering.."
  if [ -e "${secrets_file}.recipients" ]; then
    debug "Found recipients file: ${secrets_file}.recipients"
    recipients_file="${secrets_file}.recipients"
  elif [ -e "${secrets_file%.*}.recipients" ]; then
    debug "Found recipients file: ${secrets_file%.*}.recipients"
    recipients_file="${secrets_file%.*}.recipients"
  elif [ -e "${secrets_file%%.*}.recipients" ]; then
    debug "Found recipients file: ${secrets_file%%.*}.recipients"
    recipients_file="${secrets_file%%.*}.recipients"
  else
    error "Cannot find recipients file (${secrets_file}.recipients or ${secrets_file%.*}.recipients), exiting.."
  fi
else
  debug "Recipients file: ${recipients_file}"
  if [[ ! -r "${recipients_file}" ]]; then
    error "Unable to read recipients file \"${recipients_file}\", exiting.."
  fi
fi


# build list of recipients
recipients="$(for recipient in $(cut -d' ' -f1 ${recipients_file}); do echo -n " -r $recipient"; done)"

case "${secrets_file##*.}" in
  gpg)
    if [[ -n "${ARMOR:-}" ]]; then
      secrets_output="${secrets_file/gpg/asc}"
    else
      secrets_output="${secrets_file}"
    fi
    recrypt=1
  ;;
  asc)
    if [[ -n "${ARMOR:-}" ]]; then
      secrets_output="${secrets_file}"
    else
      secrets_output="${secrets_file/asc/gpg}"
    fi
    recrypt=1
  ;;
  *)
    if [[ -n "${ARMOR:-}" ]]; then
      secrets_output="${secrets_file}.asc"
    else
      secrets_output="${secrets_file}.gpg"
    fi
    recrypt=0
  ;;
esac

debug "Secrets output file: ${secrets_output}"

if [[ -n "${ARMOR:-}" ]]; then
  debug "Output: ASCII armored"
  comment="check recipients: gpg --list-packets ${secrets_output}"
else
  debug "Output: binary"
fi

debug "Comments: ${comment:-no comments for binary output}"
# exit 1
if [[ ${recrypt:-0} -eq 1 ]]; then
  info "Encrypted file detected, re-encrypting \"${secrets_file}\" with recipients from \"${recipients_file}\""
  gpg -d ${secrets_file} | gpg ${ARMOR:-} ${recipients} ${comment:+--comment "${comment}"} --batch --yes --always-trust -o "${secrets_file}.new" -e
  mv "${secrets_file}.new" "${secrets_output}"
else
  info "Encrypting \"${secrets_file}\" with recipients from \"${recipients_file}\""
  gpg ${ARMOR:-} ${recipients} ${comment:+--comment "${comment}"} --batch --yes --always-trust  -o "${secrets_output}" -e "${secrets_file}"
fi

info "Encrypted output saved: ${secrets_output}"
