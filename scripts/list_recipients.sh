#!/usr/bin/env bash
# outputs recipients of encrypted file
set -u
set -e
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

usage() {
cat <<EOM

List recipients of encrypted file.
Usage: $0 [flags] /path/to/encrypted.file

  FLAGS:
    -h|--help|--usage   displays usage
    -v|--debug          display debug output
    -t|--timestamp      include timestamp in debug output
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
    -*)
      error "Unexpected option \"$1\"" -
      usage
      exit 1
    ;;
    *)
      if [[ -n "${secrets_file:-}" ]]; then
        error "Only one file arguments supported, exiting.."
      fi
      secrets_file="$1"
      shift 1
    ;;
  esac
done

check_bin() {
  if ! which "$1" >/dev/null; then
    error "$1 binary not found, exiting.."
  fi
}
check_bin gpg
if [[ -z "${secrets_file:-}" ]]; then
  error "Need secrets file to decrypt.." -
  usage
  exit 1
fi
debug "Secrets file: ${secrets_file}"
if [[ ! -r "${secrets_file}" ]]; then
  error "Unable to read secrets file \"${secrets_file}\", exiting.."
fi

gpg --list-only --no-default-keyring --secret-keyring /dev/null ${secrets_file} 2>&1 | grep -A1 "encrypted with"
