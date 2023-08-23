#!/bin/bash

# Calculator for maths
calc () { awk "BEGIN{ print $* }" ;}

# Setup a timestamp for prefixing all commands
__datetime=$(date -u +%F_%H-%M-%S-UTC)

### BASH HELPER FUNCTIONS ###
# Stolen from https://github.com/kvz/bash3boilerplate"

if [[ ${_arg_dry_run} == "on" || ${_arg_debug} == "on" ]]; then
  LOG_LEVEL=7
else
  LOG_LEVEL=6
fi

function __b3bp_log() {
  local log_level="${1}"
  shift

  # shellcheck disable=SC2034
  local color_debug="\\x1b[35m" #]
  # shellcheck disable=SC2034
  local color_info="\\x1b[32m" #]
  # shellcheck disable=SC2034
  local color_notice="\\x1b[34m" #]
  # shellcheck disable=SC2034
  local color_warning="\\x1b[33m" #]
  # shellcheck disable=SC2034
  local color_error="\\x1b[31m" #]
  # shellcheck disable=SC2034
  local color_critical="\\x1b[1;31m" #]
  # shellcheck disable=SC2034
  local color_alert="\\x1b[1;37;41m" #]
  # shellcheck disable=SC2034
  local color_failure="\\x1b[1;4;5;37;41m" #]

  local colorvar="color_${log_level}"

  local color="${!colorvar:-${color_error}}"
  local color_reset="\\x1b[0m" #]

  if [[ "${NO_COLOR:-}" = "true" ]] || { [[ "${TERM:-}" != "xterm"* ]] && [[ "${TERM:-}" != "screen"* ]]; } || [[ ! -t 2 ]]; then
    if [[ "${NO_COLOR:-}" != "false" ]]; then
      # Don't use colors on pipes or non-recognized terminals
      color=""
      color_reset=""
    fi
  fi

  # all remaining arguments are to be printed
  local log_line=""

  while IFS=$'\n' read -r log_line; do
    echo -e "$(date -u +"%Y-%m-%d %H:%M:%S UTC") ${color}$(printf "[%9s]" "${log_level}")${color_reset} $(echo ${log_line} | tr -s "[:blank:]")" 1>&2
  done <<<"${@:-}"
}

function failure() {
  __b3bp_log failure "${@}"
  exit 1
}
function alert() {
  [[ "${LOG_LEVEL:-0}" -ge 1 ]] && __b3bp_log alert "${@}"
  true
}
function critical() {
  [[ "${LOG_LEVEL:-0}" -ge 2 ]] && __b3bp_log critical "${@}"
  true
}
function error() {
  [[ "${LOG_LEVEL:-0}" -ge 3 ]] && __b3bp_log error "${@}"
  true
}
function warning() {
  [[ "${LOG_LEVEL:-0}" -ge 4 ]] && __b3bp_log warning "${@}"
  true
}
function notice() {
  [[ "${LOG_LEVEL:-0}" -ge 5 ]] && __b3bp_log notice "${@}"
  true
}
function info() {
  [[ "${LOG_LEVEL:-0}" -ge 6 ]] && __b3bp_log info "${@}"
  true
}
function debug() {
  [[ "${LOG_LEVEL:-0}" -ge 7 ]] && __b3bp_log debug "${@}"
  true
}

# Add handler for failure to show where things went wrong
failure_handler() {
  local lineno=$2
  local fn=$3
  local exitstatus=$4
  local msg_orig=$5
  local msg_expanded=$(eval echo \"$5\")
  local lineno_fns=${1% 0}
  if [[ "$lineno_fns" != "0" ]] ; then
    lineno="${lineno} ${lineno_fns}"
  fi
  failure "${BASH_SOURCE[1]}:${fn}[${lineno}] Failed with status ${exitstatus}: \n\t${msg_orig}\n\t${msg_expanded}"
}
trap 'failure_handler "${BASH_LINENO[*]}" "$LINENO" "${FUNCNAME[*]:-script}" "$?" "$BASH_COMMAND"' ERR

#This function is used to cleanly exit any script. It does this displaying a
# given error message, and exiting with an error code.
function error_exit {
    failure "$@"
}
#Trap the killer signals so that we can exit with a good message.
trap "error_exit 'Exiting: Received signal SIGHUP'" SIGHUP
trap "error_exit 'Exiting: Received signal SIGINT'" SIGINT
trap "error_exit 'Exiting: Received signal SIGTERM'" SIGTERM

function run_smart {
  # Function runs the command it wraps if the file does not exist
  if [[ ! -s "$1" ]]; then
    "$2"
  fi
}

function extension_strip()
{
  sed -r 's/(.nii$|.nii.gz|.nrrd|.mnc|.mnc.gz)$//'
}

__dir="$(cd "$(dirname "${BASH_SOURCE[${__b3bp_tmp_source_idx:-0}]}")" && pwd)"
export PATH=${__dir}/minc-toolkit-extras:${PATH}