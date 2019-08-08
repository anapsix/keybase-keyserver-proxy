#!/usr/bin/env bash
set -e
set -u
set -o pipefail

: ${DECRYPT_WITH:="gpg"}

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

Decrypts PGP encrypted message with GPG or Keybase.
Usage: $0 [flags] /path/to/encrypted.file

  FLAGS:
    -h|--help|--usage   displays usage
    -v|--debug          display debug output
    -t|--timestamp      include timestamp in debug output
    -g|--gpg            use GPG for decryption, used by default
    -k|--keybase        use Keybase for decryption
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
    -g|--gpg)
      DECRYPT_WITH="gpg"
      shift 1
    ;;
    -k|--keybase)
      DECRYPT_WITH="keybase"
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
      secrets_file_decrypted="${secrets_file%.*}"
      shift 1
    ;;
  esac
done

check_bin() {
  if ! which "$1" >/dev/null; then
    error "$1 binary not found, exiting.."
  fi
}

if [[ -z "${secrets_file:-}" ]]; then
  error "Need secrets file to decrypt.." -
  usage
  exit 1
fi
debug "Using: ${DECRYPT_WITH}"
debug "Secrets file: ${secrets_file}"
if [[ ! -r "${secrets_file}" ]]; then
  error "Unable to read secrets file \"${secrets_file}\", exiting.."
fi

case "${DECRYPT_WITH}" in
  keybase)
    check_bin "${DECRYPT_WITH}"
    keybase pgp decrypt -i "${secrets_file}" # -o ${secrets_file_decrypted}
  ;;
  gpg)
    check_bin "${DECRYPT_WITH}"
    gpg -d "${secrets_file}" 2>/dev/null # 1>${secrets_file_decrypted}
  ;;
  *)
    error "don't know how to decrypt with \"${DECRYPT_WITH}\", exiting.."
  ;;
esac

# info "Decrypted \"${secrets_file}\" as \"${secrets_file_decrypted}\""
