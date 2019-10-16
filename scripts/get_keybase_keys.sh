#!/usr/bin/env bash
set -u
set -e
set -o pipefail

: ${KEYSERVER:='do.random.io'}

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

Import keys from recipients file.
Usage: $0 [flags] /path/to/recipients.file

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
      if [[ -n "${recipients_file:-}" ]]; then
        error "Only one file arguments supported, exiting.."
      fi
      recipients_file="$1"
      shift 1
    ;;
  esac
done

check_bin() {
  if ! which "$1" >/dev/null; then
    error "$1 binary not found, exiting.."
  fi
}

check_bin "gpg"

if [[ -z "${recipients_file:-}" ]]; then
  error "Need recipients file to process.." -
  usage
  exit 1
fi
debug "Recipients file: ${recipients_file}"
if [[ ! -r "${recipients_file}" ]]; then
  error "Unable to read recipients file \"${recipients_file}\", exiting.."
fi

recipients="$(for recipient in $(cut -d' ' -f1 ${recipients_file}); do echo -n " $recipient"; done)"

for key in $recipients; do
  debug "Importing $key"
  gpg --keyserver "${KEYSERVER}" --recv-keys "$key"
done
