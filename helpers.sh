#!/bin/bash

# Calculator for maths
calc () { awk "BEGIN{ print $* }" ;}

### BASH HELPER FUNCTIONS ###
# Stolen from https://github.com/kvz/bash3boilerplate

# Set magic variables for current file, directory, os, etc.
__dir="$(cd "$(dirname "${BASH_SOURCE[${__b3bp_tmp_source_idx:-0}]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[${__b3bp_tmp_source_idx:-0}]}")"
__base="$(basename "${__file}" .sh)"
# shellcheck disable=SC2034,SC2015
__invocation="$(printf %q "${__file}")$( (($#)) && printf ' %q' "$@" || true)"

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
  local lineno=${1}
  local msg=${2}
  failure "Failed at ${lineno}: ${msg}"
}
trap 'failure_handler ${LINENO} "$BASH_COMMAND"' ERR

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