#!/bin/bash

# Created by argbash-init v2.10.0
# ARG_HELP([Commonspace resampling post-processing for twolevel_modelbuild.sh from optimized_antsMultivariateTemplateConstruction])
# ARG_OPTIONAL_SINGLE([output-dir],[],[Output directory for modelbuild],[output])
# ARG_OPTIONAL_SINGLE([walltime],[],[Walltime for short running stages (averaging, resampling)],[00:15:00])
# ARG_OPTIONAL_SINGLE([resample-inputs],[],[Files to be resampled into common space, structured the same as the input to twolevel_modelbuild.sh],[])
# ARG_OPTIONAL_SINGLE([prepend-transforms],[],[Transform files which align resample-inputs to inputs, will be added to the transform stack, append with :1 to indicate applying the inverse, structured the same as input to twolevel_modelbuild.sh],[])
# ARG_OPTIONAL_BOOLEAN([debug],[],[Debug mode, print all commands to stdout],[])
# ARG_OPTIONAL_BOOLEAN([dry-run],[],[Dry run, don't run any commands, implies debug],[])
# ARG_POSITIONAL_SINGLE([inputs],[Input text files, one line per subject, comma separated scans per subject],[])
# ARG_LEFTOVERS([Arguments to be passed to commonspace_resample.sh without validation])
# ARGBASH_SET_INDENT([  ])
# ARGBASH_GO()
# needed because of Argbash --> m4_ignore([
### START OF CODE GENERATED BY Argbash v2.10.0 one line above ###
# Argbash is a bash code generator used to get arguments parsing right.
# Argbash is FREE SOFTWARE, see https://argbash.io for more info


die()
{
  local _ret="${2:-1}"
  test "${_PRINT_HELP:-no}" = yes && print_help >&2
  echo "$1" >&2
  exit "${_ret}"
}


begins_with_short_option()
{
  local first_option all_short_options='h'
  first_option="${1:0:1}"
  test "$all_short_options" = "${all_short_options/$first_option/}" && return 1 || return 0
}

# THE DEFAULTS INITIALIZATION - POSITIONALS
_positionals=()
_arg_leftovers=()
# THE DEFAULTS INITIALIZATION - OPTIONALS
_arg_output_dir="output"
_arg_walltime="00:15:00"
_arg_resample_inputs=
_arg_prepend_transforms=
_arg_debug="off"
_arg_dry_run="off"


print_help()
{
  printf '%s\n' "Commonspace resampling post-processing for twolevel_modelbuild.sh from optimized_antsMultivariateTemplateConstruction"
  printf 'Usage: %s [-h|--help] [--output-dir <arg>] [--walltime <arg>] [--resample-inputs <arg>] [--prepend-transforms <arg>] [--(no-)debug] [--(no-)dry-run] <inputs> ... \n' "$0"
  printf '\t%s\n' "<inputs>: Input text files, one line per subject, comma separated scans per subject"
  printf '\t%s\n' "... : Arguments to be passed to commonspace_resample.sh without validation"
  printf '\t%s\n' "-h, --help: Prints help"
  printf '\t%s\n' "--output-dir: Output directory for modelbuild (default: 'output')"
  printf '\t%s\n' "--walltime: Walltime for short running stages (averaging, resampling) (default: '00:15:00')"
  printf '\t%s\n' "--resample-inputs: Files to be resampled into common space, structured the same as the input to twolevel_modelbuild.sh (no default)"
  printf '\t%s\n' "--prepend-transforms: Transform files which align resample-inputs to inputs, will be added to the transform stack, append with :1 to indicate applying the inverse, structured the same as input to twolevel_modelbuild.sh (no default)"
  printf '\t%s\n' "--debug, --no-debug: Debug mode, print all commands to stdout (off by default)"
  printf '\t%s\n' "--dry-run, --no-dry-run: Dry run, don't run any commands, implies debug (off by default)"
}


parse_commandline()
{
  _positionals_count=0
  while test $# -gt 0
  do
    _key="$1"
    case "$_key" in
      -h|--help)
        print_help
        exit 0
        ;;
      -h*)
        print_help
        exit 0
        ;;
      --output-dir)
        test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
        _arg_output_dir="$2"
        shift
        ;;
      --output-dir=*)
        _arg_output_dir="${_key##--output-dir=}"
        ;;
      --walltime)
        test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
        _arg_walltime="$2"
        shift
        ;;
      --walltime=*)
        _arg_walltime="${_key##--walltime=}"
        ;;
      --resample-inputs)
        test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
        _arg_resample_inputs="$2"
        shift
        ;;
      --resample-inputs=*)
        _arg_resample_inputs="${_key##--resample-inputs=}"
        ;;
      --prepend-transforms)
        test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
        _arg_prepend_transforms="$2"
        shift
        ;;
      --prepend-transforms=*)
        _arg_prepend_transforms="${_key##--prepend-transforms=}"
        ;;
      --no-debug|--debug)
        _arg_debug="on"
        test "${1:0:5}" = "--no-" && _arg_debug="off"
        ;;
      --no-dry-run|--dry-run)
        _arg_dry_run="on"
        test "${1:0:5}" = "--no-" && _arg_dry_run="off"
        ;;
      *)
        _last_positional="$1"
        _positionals+=("$_last_positional")
        _positionals_count=$((_positionals_count + 1))
        ;;
    esac
    shift
  done
}


handle_passed_args_count()
{
  local _required_args_string="'inputs'"
  test "${_positionals_count}" -ge 1 || _PRINT_HELP=yes die "FATAL ERROR: Not enough positional arguments - we require at least 1 (namely: $_required_args_string), but got only ${_positionals_count}." 1
}


assign_positional_args()
{
  local _positional_name _shift_for=$1
  _positional_names="_arg_inputs "
  _our_args=$((${#_positionals[@]} - 1))
  for ((ii = 0; ii < _our_args; ii++))
  do
    _positional_names="$_positional_names _arg_leftovers[$((ii + 0))]"
  done

  shift "$_shift_for"
  for _positional_name in ${_positional_names}
  do
    test $# -gt 0 || break
    eval "$_positional_name=\${1}" || die "Error during argument parsing, possibly an Argbash bug." 1
    shift
  done
}

parse_commandline "$@"
handle_passed_args_count
assign_positional_args 1 "${_positionals[@]}"

# OTHER STUFF GENERATED BY Argbash

### END OF CODE GENERATED BY Argbash (sortof) ### ])
# [ <-- needed because of Argbash

set -uo pipefail
set -eE -o functrace

# shellcheck source=helpers.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/helpers.sh"

# Set magic variables for current file, directory, os, etc.
__file="${__dir}/$(basename "${BASH_SOURCE[${__b3bp_tmp_source_idx:-0}]}")"
__base="$(basename "${__file}" .sh)"
# shellcheck disable=SC2034,SC2015
__invocation="$(printf %q "${__file}")$( (($#)) && printf ' %q' "$@" || true)"

if [[ ${_arg_debug} == "off" ]]; then
  unset _arg_debug
fi

#set -x

# Setup a directory which contains all commands run
# for this invocation
mkdir -p ${_arg_output_dir}/secondlevel/jobs/${__datetime}

# Store the full command line for each run
echo ${__invocation} >${_arg_output_dir}/secondlevel/jobs/${__datetime}/invocation


mkdir -p ${_arg_output_dir}/secondlevel/commonspace-resampled

info "Processing Two-Level Common Resampling"
i=1
while read -r subject_scans; do

  mkdir -p ${_arg_output_dir}/secondlevel/commonspace-resampled/subject_${i}
  IFS=',' read -r -a scans <<<${subject_scans}
  if [[ -n ${_arg_prepend_transforms} ]]; then
    IFS=',' read -r -a transforms <<< $(sed "${i}q;d" ${_arg_prepend_transforms})
    prepend_transforms="--prepend-transforms ${_arg_output_dir}/secondlevel/commonspace-resampled/subject_${i}/prepend_transforms.txt"
    printf "%s\n" "${transforms[@]}" > ${_arg_output_dir}/secondlevel/commonspace-resampled/subject_${i}/prepend_transforms.txt
  else
    >${_arg_output_dir}/secondlevel/commonspace-resampled/subject_${i}/prepend_transforms.txt
    prepend_transforms=""
  fi
  IFS=',' read -r -a resample_inputs <<< $(sed "${i}q;d" ${_arg_resample_inputs})

  printf "%s\n" "${resample_inputs[@]}" > ${_arg_output_dir}/secondlevel/commonspace-resampled/subject_${i}/resample_inputs.txt

  info "Processing subject_${i}"

  if (( $(wc -l < ${_arg_output_dir}/firstlevel/subject_${i}/input_files.txt) > 1 )); then

  ${__dir}/commonspace_resample.sh ${_arg_debug:+--debug} ${_arg_leftovers[@]+"${_arg_leftovers[@]}"} \
                                         --target-space secondlevel \
                                         --output-dir ${_arg_output_dir}/firstlevel/subject_${i} \
                                         ${prepend_transforms} \
                                         --append-transforms "${_arg_output_dir}/secondlevel/final/transforms/subject_${i}_1Warp.nii.gz,${_arg_output_dir}/secondlevel/final/transforms/subject_${i}_0GenericAffine.mat" \
                                         --resample-inputs ${_arg_output_dir}/secondlevel/commonspace-resampled/subject_${i}/resample_inputs.txt \
                                        ${_arg_output_dir}/firstlevel/subject_${i}/input_files.txt
  fi

  ((++i))

done < ${_arg_inputs}

# ] <-- needed because of Argbash
