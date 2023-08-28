#!/bin/bash
# ARG_HELP([A qbatch enabled, optimal registration pyramid based re-implementaiton of antsMultivariateTemplateConstruction2.sh])
# ARG_OPTIONAL_SINGLE([output-dir],[],[Output directory for modelbuild],[output])
# ARG_OPTIONAL_SINGLE([gradient-step],[],[Gradient scaling step during template warping, can be a comma separated list same length as number of iterations],[0.25])
# ARG_OPTIONAL_SINGLE([starting-target],[],[Initial image used to start modelbuild, defines orientation and voxel space, if 'none' an average of all subjects is constructed as a starting target],[none])
# ARG_OPTIONAL_SINGLE([starting-target-mask],[],[Mask for starting target],[])
# ARG_OPTIONAL_BOOLEAN([com-initialize],[],[When a starting target is not provided, align all inputs using their center-of-mass before averaging],[on])
# ARG_OPTIONAL_SINGLE([starting-average-resolution],[],[If no starting target is provided, an average is constructed from all inputs, resample average to a target resolution MxNxO before modelbuild],[])
# ARG_OPTIONAL_SINGLE([iterations],[],[Number of iterations of model building per stage],[4])
# ARG_OPTIONAL_SINGLE([convergence],[],[Convergence limit during registration calls],[1e-7])

# ARG_OPTIONAL_SINGLE([syn-shrink-factors],[],[Shrink factors for Non-linear (SyN) stages, provide to override automatic generation, must be provided with sigmas and convergence],[])
# ARG_OPTIONAL_SINGLE([syn-smoothing-sigmas],[],[Smoothing sigmas for Non-linear (SyN) stages, provide to override automatic generation, must be provided with shrinks and convergence],[])
# ARG_OPTIONAL_SINGLE([syn-convergence],[],[Convergence levels for Non-linear (SyN) stages, provide to override automatic generation, must be provided with shrinks and sigmas],[])
# ARG_OPTIONAL_SINGLE([syn-control],[],[Non-linear (SyN) gradient and regularization parameters, not checked for correctness],[0.1,3,0])
# ARG_OPTIONAL_SINGLE([linear-shrink-factors],[],[Shrink factors for linear stages, provide to override automatic generation, must be provided with sigmas and convergence],[])
# ARG_OPTIONAL_SINGLE([linear-smoothing-sigmas],[],[Smoothing sigmas for linear stages, provide to override automatic generation, must be provided with shrinks and convergence],[])
# ARG_OPTIONAL_SINGLE([linear-convergence],[],[Convergence levels for linear stages, provide to override automatic generation, must be provided with shrinks and sigmas],[])

# ARG_OPTIONAL_BOOLEAN([float],[],[Use float instead of double for calculations (reduce memory requirements)],[])
# ARG_OPTIONAL_BOOLEAN([fast],[],[Run SyN registration with Mattes instead of CC],[])
# ARG_OPTIONAL_SINGLE([average-type],[],[Type of averaging to apply during modelbuild],[mean])
# ARG_OPTIONAL_SINGLE([average-prog],[],[Software to use for averaging images and transforms\n        python with SimpleITK needed for trimmed_mean, efficient_trimean, and huber],[ANTs])
# ARG_OPTIONAL_BOOLEAN([average-norm],[],[Normalize images by their mean before averaging],[on])
# ARG_OPTIONAL_BOOLEAN([nlin-shape-update],[],[Perform nlin shape update, disable to switch to a forward-only modelbuild],[on])
# ARG_OPTIONAL_BOOLEAN([affine-shape-update],[],[Scale template by inverse of average affine transforms during shape update step],[on])
# ARG_OPTIONAL_BOOLEAN([scale-affines],[],[Apply gradient step scaling factor to average affine during shape update step, requires python with VTK and SimpleITK],[])
# ARG_OPTIONAL_BOOLEAN([rigid-update],[],[Include rigid component of transform when performing shape update on template (disable if template drifts in translation or orientation)],[])
# ARG_TYPE_GROUP_SET([averagetype],[AVERAGE],[average-type],[mean,median,trimmed_mean,efficient_trimean,huber])
# ARG_TYPE_GROUP_SET([averageprogtype],[PROG],[average-prog],[ANTs,python])
# ARG_OPTIONAL_SINGLE([sharpen-type],[],[Type of sharpening applied to average during modelbuild],[unsharp])
# ARG_TYPE_GROUP_SET([sharptypetype],[SHARPEN],[sharpen-type],[none,laplacian,unsharp])
# ARG_OPTIONAL_SINGLE([masks],[],[File containing mask filenames, one file per line],[])
# ARG_OPTIONAL_BOOLEAN([mask-extract],[],[Use masks to extract images before registration],[])
# ARG_OPTIONAL_SINGLE([mask-merge-threshold],[],[Threshold to combine masks during averaging],[0.5])

# ARG_OPTIONAL_SINGLE([stages],[],[Stages of modelbuild used (comma separated options: 'rigid' 'similarity' 'affine' 'nlin' 'nlin-only','volgenmodel-nlin'), append a number in brackets 'rigid[n]' to override global iteration setting],[rigid,similarity,affine,nlin])
# ARG_OPTIONAL_BOOLEAN([reuse-affines],[],[Reuse affines from previous stage/iteration to initialize next stage],[off])
# ARG_OPTIONAL_SINGLE([final-target],[],[Perform a final registration between the average and final target, used in postprocessing],[none])
# ARG_OPTIONAL_SINGLE([final-target-mask],[],[Mask for the final target used in postprocessing],[none])

# ARG_OPTIONAL_SINGLE([walltime-short],[],[Walltime for short running stages (averaging, resampling)],[00:30:00])
# ARG_OPTIONAL_SINGLE([walltime-linear],[],[Walltime for linear registration stages],[0:45:00])
# ARG_OPTIONAL_SINGLE([walltime-nonlinear],[],[Walltime for nonlinear registration stages],[4:30:00])
# ARG_OPTIONAL_SINGLE([jobname-prefix],[],[Prefix to add to front of job names, used by twolevel wrapper],[])
# ARG_OPTIONAL_SINGLE([job-predepend],[],[Job name dependency pattern to prepend to all jobs, used by twolevel wrapper],[])
# ARG_OPTIONAL_BOOLEAN([skip-file-checks],[],[Skip preflight checking of existence of files, used by twolevel wrapper],[])
# ARG_OPTIONAL_BOOLEAN([block],[],[For SGE, PBS and SLURM, blocks execution until jobs are finished.],[])
# ARG_OPTIONAL_BOOLEAN([debug],[],[Debug mode, print all commands to stdout],[])
# ARG_OPTIONAL_BOOLEAN([dry-run],[],[Dry run, don't run any commands, implies debug],[])
# ARG_POSITIONAL_INF([inputs],[Input text file, one line per input],[1])
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

# validators

averagetype()
{
	local _allowed=("mean" "median" "trimmed_mean" "efficient_trimean" "huber") _seeking="$1"
	for element in "${_allowed[@]}"
	do
		test "$element" = "$_seeking" && echo "$element" && return 0
	done
	die "Value '$_seeking' (of argument '$2') doesn't match the list of allowed values: 'mean', 'median', 'trimmed_mean', 'efficient_trimean' and 'huber'" 4
}


averageprogtype()
{
	local _allowed=("ANTs" "python") _seeking="$1"
	for element in "${_allowed[@]}"
	do
		test "$element" = "$_seeking" && echo "$element" && return 0
	done
	die "Value '$_seeking' (of argument '$2') doesn't match the list of allowed values: 'ANTs' and 'python'" 4
}


sharptypetype()
{
	local _allowed=("none" "laplacian" "unsharp") _seeking="$1"
	for element in "${_allowed[@]}"
	do
		test "$element" = "$_seeking" && echo "$element" && return 0
	done
	die "Value '$_seeking' (of argument '$2') doesn't match the list of allowed values: 'none', 'laplacian' and 'unsharp'" 4
}


begins_with_short_option()
{
  local first_option all_short_options='h'
  first_option="${1:0:1}"
  test "$all_short_options" = "${all_short_options/$first_option/}" && return 1 || return 0
}

# THE DEFAULTS INITIALIZATION - POSITIONALS
_positionals=()
_arg_inputs=('' )
# THE DEFAULTS INITIALIZATION - OPTIONALS
_arg_output_dir="output"
_arg_gradient_step="0.25"
_arg_starting_target="none"
_arg_starting_target_mask=
_arg_com_initialize="on"
_arg_starting_average_resolution=
_arg_iterations="4"
_arg_convergence="1e-7"
_arg_syn_shrink_factors=
_arg_syn_smoothing_sigmas=
_arg_syn_convergence=
_arg_syn_control="0.1,3,0"
_arg_linear_shrink_factors=
_arg_linear_smoothing_sigmas=
_arg_linear_convergence=
_arg_float="off"
_arg_fast="off"
_arg_average_type="mean"
_arg_average_prog="ANTs"
_arg_average_norm="on"
_arg_nlin_shape_update="on"
_arg_affine_shape_update="on"
_arg_scale_affines="off"
_arg_rigid_update="off"
_arg_sharpen_type="unsharp"
_arg_masks=
_arg_mask_extract="off"
_arg_mask_merge_threshold="0.5"
_arg_stages="rigid,similarity,affine,nlin"
_arg_reuse_affines="off"
_arg_final_target="none"
_arg_final_target_mask="none"
_arg_walltime_short="00:30:00"
_arg_walltime_linear="0:45:00"
_arg_walltime_nonlinear="4:30:00"
_arg_jobname_prefix=
_arg_job_predepend=
_arg_skip_file_checks="off"
_arg_block="off"
_arg_debug="off"
_arg_dry_run="off"


print_help()
{
  printf '%s\n' "A qbatch enabled, optimal registration pyramid based re-implementaiton of antsMultivariateTemplateConstruction2.sh"
  printf 'Usage: %s [-h|--help] [--output-dir <arg>] [--gradient-step <arg>] [--starting-target <arg>] [--starting-target-mask <arg>] [--(no-)com-initialize] [--starting-average-resolution <arg>] [--iterations <arg>] [--convergence <arg>] [--syn-shrink-factors <arg>] [--syn-smoothing-sigmas <arg>] [--syn-convergence <arg>] [--syn-control <arg>] [--linear-shrink-factors <arg>] [--linear-smoothing-sigmas <arg>] [--linear-convergence <arg>] [--(no-)float] [--(no-)fast] [--average-type <AVERAGE>] [--average-prog <PROG>] [--(no-)average-norm] [--(no-)nlin-shape-update] [--(no-)affine-shape-update] [--(no-)scale-affines] [--(no-)rigid-update] [--sharpen-type <SHARPEN>] [--masks <arg>] [--(no-)mask-extract] [--mask-merge-threshold <arg>] [--stages <arg>] [--(no-)reuse-affines] [--final-target <arg>] [--final-target-mask <arg>] [--walltime-short <arg>] [--walltime-linear <arg>] [--walltime-nonlinear <arg>] [--jobname-prefix <arg>] [--job-predepend <arg>] [--(no-)skip-file-checks] [--(no-)block] [--(no-)debug] [--(no-)dry-run] <inputs-1> [<inputs-2>] ... [<inputs-n>] ...\n' "$0"
  printf '\t%s\n' "<inputs>: Input text file, one line per input"
  printf '\t%s\n' "-h, --help: Prints help"
  printf '\t%s\n' "--output-dir: Output directory for modelbuild (default: 'output')"
  printf '\t%s\n' "--gradient-step: Gradient scaling step during template warping, can be a comma separated list same length as number of iterations (default: '0.25')"
  printf '\t%s\n' "--starting-target: Initial image used to start modelbuild, defines orientation and voxel space, if 'none' an average of all subjects is constructed as a starting target (default: 'none')"
  printf '\t%s\n' "--starting-target-mask: Mask for starting target (no default)"
  printf '\t%s\n' "--com-initialize, --no-com-initialize: When a starting target is not provided, align all inputs using their center-of-mass before averaging (on by default)"
  printf '\t%s\n' "--starting-average-resolution: If no starting target is provided, an average is constructed from all inputs, resample average to a target resolution MxNxO before modelbuild (no default)"
  printf '\t%s\n' "--iterations: Number of iterations of model building per stage (default: '4')"
  printf '\t%s\n' "--convergence: Convergence limit during registration calls (default: '1e-7')"
  printf '\t%s\n' "--syn-shrink-factors: Shrink factors for Non-linear (SyN) stages, provide to override automatic generation, must be provided with sigmas and convergence (no default)"
  printf '\t%s\n' "--syn-smoothing-sigmas: Smoothing sigmas for Non-linear (SyN) stages, provide to override automatic generation, must be provided with shrinks and convergence (no default)"
  printf '\t%s\n' "--syn-convergence: Convergence levels for Non-linear (SyN) stages, provide to override automatic generation, must be provided with shrinks and sigmas (no default)"
  printf '\t%s\n' "--syn-control: Non-linear (SyN) gradient and regularization parameters, not checked for correctness (default: '0.1,3,0')"
  printf '\t%s\n' "--linear-shrink-factors: Shrink factors for linear stages, provide to override automatic generation, must be provided with sigmas and convergence (no default)"
  printf '\t%s\n' "--linear-smoothing-sigmas: Smoothing sigmas for linear stages, provide to override automatic generation, must be provided with shrinks and convergence (no default)"
  printf '\t%s\n' "--linear-convergence: Convergence levels for linear stages, provide to override automatic generation, must be provided with shrinks and sigmas (no default)"
  printf '\t%s\n' "--float, --no-float: Use float instead of double for calculations (reduce memory requirements) (off by default)"
  printf '\t%s\n' "--fast, --no-fast: Run SyN registration with Mattes instead of CC (off by default)"
  printf '\t%s\n' "--average-type: Type of averaging to apply during modelbuild. Can be one of: 'mean', 'median', 'trimmed_mean', 'efficient_trimean' and 'huber' (default: 'mean')"
  printf '\t%s\n' "--average-prog: Software to use for averaging images and transforms
		        python with SimpleITK needed for trimmed_mean, efficient_trimean, and huber. Can be one of: 'ANTs' and 'python' (default: 'ANTs')"
  printf '\t%s\n' "--average-norm, --no-average-norm: Normalize images by their mean before averaging (on by default)"
  printf '\t%s\n' "--nlin-shape-update, --no-nlin-shape-update: Perform nlin shape update, disable to switch to a forward-only modelbuild (on by default)"
  printf '\t%s\n' "--affine-shape-update, --no-affine-shape-update: Scale template by inverse of average affine transforms during shape update step (on by default)"
  printf '\t%s\n' "--scale-affines, --no-scale-affines: Apply gradient step scaling factor to average affine during shape update step, requires python with VTK and SimpleITK (off by default)"
  printf '\t%s\n' "--rigid-update, --no-rigid-update: Include rigid component of transform when performing shape update on template (disable if template drifts in translation or orientation) (off by default)"
  printf '\t%s\n' "--sharpen-type: Type of sharpening applied to average during modelbuild. Can be one of: 'none', 'laplacian' and 'unsharp' (default: 'unsharp')"
  printf '\t%s\n' "--masks: File containing mask filenames, one file per line (no default)"
  printf '\t%s\n' "--mask-extract, --no-mask-extract: Use masks to extract images before registration (off by default)"
  printf '\t%s\n' "--mask-merge-threshold: Threshold to combine masks during averaging (default: '0.5')"
  printf '\t%s\n' "--stages: Stages of modelbuild used (comma separated options: 'rigid' 'similarity' 'affine' 'nlin' 'nlin-only','volgenmodel-nlin'), append a number in brackets 'rigid[n]' to override global iteration setting (default: 'rigid,similarity,affine,nlin')"
  printf '\t%s\n' "--reuse-affines, --no-reuse-affines: Reuse affines from previous stage/iteration to initialize next stage (off by default)"
  printf '\t%s\n' "--final-target: Perform a final registration between the average and final target, used in postprocessing (default: 'none')"
  printf '\t%s\n' "--final-target-mask: Mask for the final target used in postprocessing (default: 'none')"
  printf '\t%s\n' "--walltime-short: Walltime for short running stages (averaging, resampling) (default: '00:30:00')"
  printf '\t%s\n' "--walltime-linear: Walltime for linear registration stages (default: '0:45:00')"
  printf '\t%s\n' "--walltime-nonlinear: Walltime for nonlinear registration stages (default: '4:30:00')"
  printf '\t%s\n' "--jobname-prefix: Prefix to add to front of job names, used by twolevel wrapper (no default)"
  printf '\t%s\n' "--job-predepend: Job name dependency pattern to prepend to all jobs, used by twolevel wrapper (no default)"
  printf '\t%s\n' "--skip-file-checks, --no-skip-file-checks: Skip preflight checking of existence of files, used by twolevel wrapper (off by default)"
  printf '\t%s\n' "--block, --no-block: For SGE, PBS and SLURM, blocks execution until jobs are finished. (off by default)"
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
      --gradient-step)
        test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
        _arg_gradient_step="$2"
        shift
        ;;
      --gradient-step=*)
        _arg_gradient_step="${_key##--gradient-step=}"
        ;;
      --starting-target)
        test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
        _arg_starting_target="$2"
        shift
        ;;
      --starting-target=*)
        _arg_starting_target="${_key##--starting-target=}"
        ;;
      --starting-target-mask)
        test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
        _arg_starting_target_mask="$2"
        shift
        ;;
      --starting-target-mask=*)
        _arg_starting_target_mask="${_key##--starting-target-mask=}"
        ;;
      --no-com-initialize|--com-initialize)
        _arg_com_initialize="on"
        test "${1:0:5}" = "--no-" && _arg_com_initialize="off"
        ;;
      --starting-average-resolution)
        test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
        _arg_starting_average_resolution="$2"
        shift
        ;;
      --starting-average-resolution=*)
        _arg_starting_average_resolution="${_key##--starting-average-resolution=}"
        ;;
      --iterations)
        test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
        _arg_iterations="$2"
        shift
        ;;
      --iterations=*)
        _arg_iterations="${_key##--iterations=}"
        ;;
      --convergence)
        test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
        _arg_convergence="$2"
        shift
        ;;
      --convergence=*)
        _arg_convergence="${_key##--convergence=}"
        ;;
      --syn-shrink-factors)
        test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
        _arg_syn_shrink_factors="$2"
        shift
        ;;
      --syn-shrink-factors=*)
        _arg_syn_shrink_factors="${_key##--syn-shrink-factors=}"
        ;;
      --syn-smoothing-sigmas)
        test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
        _arg_syn_smoothing_sigmas="$2"
        shift
        ;;
      --syn-smoothing-sigmas=*)
        _arg_syn_smoothing_sigmas="${_key##--syn-smoothing-sigmas=}"
        ;;
      --syn-convergence)
        test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
        _arg_syn_convergence="$2"
        shift
        ;;
      --syn-convergence=*)
        _arg_syn_convergence="${_key##--syn-convergence=}"
        ;;
      --syn-control)
        test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
        _arg_syn_control="$2"
        shift
        ;;
      --syn-control=*)
        _arg_syn_control="${_key##--syn-control=}"
        ;;
      --linear-shrink-factors)
        test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
        _arg_linear_shrink_factors="$2"
        shift
        ;;
      --linear-shrink-factors=*)
        _arg_linear_shrink_factors="${_key##--linear-shrink-factors=}"
        ;;
      --linear-smoothing-sigmas)
        test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
        _arg_linear_smoothing_sigmas="$2"
        shift
        ;;
      --linear-smoothing-sigmas=*)
        _arg_linear_smoothing_sigmas="${_key##--linear-smoothing-sigmas=}"
        ;;
      --linear-convergence)
        test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
        _arg_linear_convergence="$2"
        shift
        ;;
      --linear-convergence=*)
        _arg_linear_convergence="${_key##--linear-convergence=}"
        ;;
      --no-float|--float)
        _arg_float="on"
        test "${1:0:5}" = "--no-" && _arg_float="off"
        ;;
      --no-fast|--fast)
        _arg_fast="on"
        test "${1:0:5}" = "--no-" && _arg_fast="off"
        ;;
      --average-type)
        test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
        _arg_average_type="$(averagetype "$2" "average-type")" || exit 1
        shift
        ;;
      --average-type=*)
        _arg_average_type="$(averagetype "${_key##--average-type=}" "average-type")" || exit 1
        ;;
      --average-prog)
        test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
        _arg_average_prog="$(averageprogtype "$2" "average-prog")" || exit 1
        shift
        ;;
      --average-prog=*)
        _arg_average_prog="$(averageprogtype "${_key##--average-prog=}" "average-prog")" || exit 1
        ;;
      --no-average-norm|--average-norm)
        _arg_average_norm="on"
        test "${1:0:5}" = "--no-" && _arg_average_norm="off"
        ;;
      --no-nlin-shape-update|--nlin-shape-update)
        _arg_nlin_shape_update="on"
        test "${1:0:5}" = "--no-" && _arg_nlin_shape_update="off"
        ;;
      --no-affine-shape-update|--affine-shape-update)
        _arg_affine_shape_update="on"
        test "${1:0:5}" = "--no-" && _arg_affine_shape_update="off"
        ;;
      --no-scale-affines|--scale-affines)
        _arg_scale_affines="on"
        test "${1:0:5}" = "--no-" && _arg_scale_affines="off"
        ;;
      --no-rigid-update|--rigid-update)
        _arg_rigid_update="on"
        test "${1:0:5}" = "--no-" && _arg_rigid_update="off"
        ;;
      --sharpen-type)
        test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
        _arg_sharpen_type="$(sharptypetype "$2" "sharpen-type")" || exit 1
        shift
        ;;
      --sharpen-type=*)
        _arg_sharpen_type="$(sharptypetype "${_key##--sharpen-type=}" "sharpen-type")" || exit 1
        ;;
      --masks)
        test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
        _arg_masks="$2"
        shift
        ;;
      --masks=*)
        _arg_masks="${_key##--masks=}"
        ;;
      --no-mask-extract|--mask-extract)
        _arg_mask_extract="on"
        test "${1:0:5}" = "--no-" && _arg_mask_extract="off"
        ;;
      --mask-merge-threshold)
        test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
        _arg_mask_merge_threshold="$2"
        shift
        ;;
      --mask-merge-threshold=*)
        _arg_mask_merge_threshold="${_key##--mask-merge-threshold=}"
        ;;
      --stages)
        test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
        _arg_stages="$2"
        shift
        ;;
      --stages=*)
        _arg_stages="${_key##--stages=}"
        ;;
      --no-reuse-affines|--reuse-affines)
        _arg_reuse_affines="on"
        test "${1:0:5}" = "--no-" && _arg_reuse_affines="off"
        ;;
      --final-target)
        test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
        _arg_final_target="$2"
        shift
        ;;
      --final-target=*)
        _arg_final_target="${_key##--final-target=}"
        ;;
      --final-target-mask)
        test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
        _arg_final_target_mask="$2"
        shift
        ;;
      --final-target-mask=*)
        _arg_final_target_mask="${_key##--final-target-mask=}"
        ;;
      --walltime-short)
        test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
        _arg_walltime_short="$2"
        shift
        ;;
      --walltime-short=*)
        _arg_walltime_short="${_key##--walltime-short=}"
        ;;
      --walltime-linear)
        test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
        _arg_walltime_linear="$2"
        shift
        ;;
      --walltime-linear=*)
        _arg_walltime_linear="${_key##--walltime-linear=}"
        ;;
      --walltime-nonlinear)
        test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
        _arg_walltime_nonlinear="$2"
        shift
        ;;
      --walltime-nonlinear=*)
        _arg_walltime_nonlinear="${_key##--walltime-nonlinear=}"
        ;;
      --jobname-prefix)
        test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
        _arg_jobname_prefix="$2"
        shift
        ;;
      --jobname-prefix=*)
        _arg_jobname_prefix="${_key##--jobname-prefix=}"
        ;;
      --job-predepend)
        test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
        _arg_job_predepend="$2"
        shift
        ;;
      --job-predepend=*)
        _arg_job_predepend="${_key##--job-predepend=}"
        ;;
      --no-skip-file-checks|--skip-file-checks)
        _arg_skip_file_checks="on"
        test "${1:0:5}" = "--no-" && _arg_skip_file_checks="off"
        ;;
      --no-block|--block)
        _arg_block="on"
        test "${1:0:5}" = "--no-" && _arg_block="off"
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
    _positional_names="$_positional_names _arg_inputs[$((ii + 1))]"
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
# Validation of values




### END OF CODE GENERATED BY Argbash (sortof) ### ])
# [ <-- needed because of Argbash

set -uo pipefail
set -eE -o functrace


# Load up helper scripts and define helper variables
# shellcheck source=helpers.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/helpers.sh"

# Set magic variables for current file, directory, os, etc.
__file="${__dir}/$(basename "${BASH_SOURCE[${__b3bp_tmp_source_idx:-0}]}")"
__base="$(basename "${__file}" .sh)"
# shellcheck disable=SC2034,SC2015
__invocation="$(printf %q "${__file}")$( (($#)) && printf ' %q' "$@" || true)"

# Setup a directory which contains all commands run
# for this invocation
mkdir -p ${_arg_output_dir}/jobs/${__datetime}
export QBATCH_SCRIPT_FOLDER="${_arg_output_dir}/qbatch/${__datetime}"

# Store the full command line for each run
echo ${__invocation} >${_arg_output_dir}/jobs/${__datetime}/invocation

info "Checking input files"

# Load input file into array
if [[ ! -s ${_arg_inputs[0]} ]]; then
  failure "Input file ${_arg_inputs[0]} is non-existent or zero size"
else
  mapfile -t _arg_inputs <${_arg_inputs[0]}
fi

input_filenames_for_dup_check=()

for file in "${_arg_inputs[@]}"; do
  input_filenames_for_dup_check+=($(basename ${file}))
  if [[ ${_arg_skip_file_checks} == "off" ]]; then
    if [[ ! -s ${file} ]]; then
      failure "Input file ${file} is non-existent or zero size"
    fi
  fi
done

#Check for duplicate filenames
duplicates=$(IFS=$'\n' ; sort <<<"${input_filenames_for_dup_check[*]}" | uniq -d)
if [[ ! -z ${duplicates} ]]; then
  failure "The following filenames are duplicated in the input file, file names must be unique \n ${duplicates}"
fi

# Fill up array of masks
if [[ -z ${_arg_masks} ]]; then
  _arg_masks=()
  for file in "${_arg_inputs[@]}"; do
    _arg_masks+=('')
  done
else
  mapfile -t _arg_masks <${_arg_masks}
  info "Checking mask files"
  if [[ ${_arg_skip_file_checks} == "off" ]]; then
    for file in "${_arg_masks[@]}"; do
      if [[ ! -s ${file} ]]; then
        failure "Mask file ${file} is non-existent or zero size"
      fi
    done
  fi
fi

# If target mask is specified use it
target_mask=${_arg_starting_target_mask}

if [[ -n ${target_mask} && ! -s ${target_mask} ]]; then
  failure "Starting target mask ${target_mask} is non-existant or zero size"
fi

# Enable fast mode in antsRegistration_affine_SyN.sh
if [[ ${_arg_fast} == "on" ]]; then
  _arg_fast="--fast"
else
  _arg_fast="--no-fast"
fi

# Enable mask extraction in antsRegistration_affine_SyN.sh
if [[ ${_arg_mask_extract} == "on" ]]; then
  _arg_mask_extract="--mask-extract"
else
  _arg_mask_extract="--no-mask-extract"
fi

# Enable float mode for ants commands
if [[ ${_arg_float} == "on" ]]; then
  _arg_float="--float"
else
  _arg_float=""
fi

# Handle registration overrides
if [[ -n ${_arg_linear_convergence} && -n ${_arg_linear_shrink_factors} && -n ${_arg_linear_smoothing_sigmas} ]]; then
  _arg_linear_convergence="--linear-convergence ${_arg_linear_convergence}"
  _arg_linear_shrink_factors="--linear-shrink-factors ${_arg_linear_shrink_factors}"
  _arg_linear_smoothing_sigmas="--linear-smoothing-sigmas ${_arg_linear_smoothing_sigmas}"
fi

if [[ -n ${_arg_syn_convergence} && -n ${_arg_syn_shrink_factors} && -n ${_arg_syn_smoothing_sigmas} ]]; then
  _arg_syn_convergence="--syn-convergence ${_arg_syn_convergence}"
  _arg_syn_shrink_factors="--syn-shrink-factors ${_arg_syn_shrink_factors}"
  _arg_syn_smoothing_sigmas="--syn-smoothing-sigmas ${_arg_syn_smoothing_sigmas}"
fi

# Include rigid component in affine when updating template
if [[ ${_arg_rigid_update} == "on" ]]; then
  AVERAGE_AFFINE_PROGRAM="AverageAffineTransform"
else
  AVERAGE_AFFINE_PROGRAM="AverageAffineTransformNoRigid"
fi

# Enable block for qbatch job submission
if [[ ${_arg_block} == "on" ]]; then
  _arg_block="--block"
else
  _arg_block=""
fi

# Job predependency from wrapper
if [[ ! -z ${_arg_job_predepend} ]]; then
  _arg_job_predepend="--depend ${_arg_job_predepend}*"
fi

# Prefight check for required programs
for program in AverageImages ImageSetStatistics ResampleImage qbatch ImageMath \
  ThresholdImage ExtractRegionFromImageByMask antsAI ConvertImage \
  antsApplyTransforms AverageAffineTransform AverageAffineTransformNoRigid \
  antsRegistration_affine_SyN.sh parallel; do

  if ! command -v ${program} &>/dev/null; then
    failure "Required program ${program} not found!"
  fi

done

# Check for valid average choices
if [[ ${_arg_average_prog} == "ANTs" ]]; then
  case ${_arg_average_type} in
    trimmed_mean|efficient_trimean|huber)
    failure "Average method ${_arg_average_type} is not supported in ANTs, use --average-prog python"
    ;;
  esac
fi

# Check that python code will run
if [[ ${_arg_average_prog} == "python" ]]; then
  ${__dir}/sitk_image_math.py -h &>/dev/null || failure "sitk_image_math.py failed to run, check python version and dependencies"
  ${__dir}/sitk_average_affine_transforms.py -h &>/dev/null || failure "sitk_average_affine_transforms.py failed to run, check python version and dependencies"
fi

# Check that interpolator works if requested
if [[ ${_arg_scale_affines} == "on" ]]; then
  ${__dir}/interp_transform.py -h &>/dev/null || failure "interp_transform.py failed to run, check python version and dependencies"
fi

if [[ ${_arg_average_norm} == "off" ]]; then
  unset _arg_average_norm
else
  _arg_average_norm=2
fi

# Averaging function
average_images () {
  local output=$1
  shift
  local avg_inputs=("$@")

  if [[ ${_arg_average_prog} == "ANTs" ]]; then
    case ${_arg_average_type} in
      mean)
        echo AverageImages 3 ${output} \
          ${_arg_average_norm:-0} \
          "${avg_inputs[@]}"
      ;;
      median)
          printf '%s\n' "${avg_inputs[@]}" > $(dirname ${output})/$(basename ${output} .nii.gz)_medianinput.txt
          echo ImageSetStatistics 3 $(dirname ${output})/$(basename ${output} .nii.gz)_medianinput.txt \
            ${output} 0
      ;;
    esac
  else
    echo ${__dir}/sitk_image_math.py \
      -o ${output} \
      --method ${_arg_average_type} \
      ${_arg_average_norm:+--normalize} \
      --file-list "${avg_inputs[@]}"
  fi
}

# If no starting target is supplied, create one
if [[ ${_arg_starting_target} == "none" ]]; then
  if [[ ! -s ${_arg_output_dir}/initialaverage/initialtarget.nii.gz ]]; then
    mkdir -p ${_arg_output_dir}/initialaverage
    if [[ ${_arg_com_initialize} == "off" ]]; then
      info "Generating initial average of all subjects using ${_arg_average_type} method"
      average_images ${_arg_output_dir}/initialaverage/initialtarget.nii.gz "${_arg_inputs[@]}" \
        >${_arg_output_dir}/jobs/${__datetime}/initialaverage

      if [[ -n ${_arg_starting_average_resolution} ]]; then
        echo ResampleImage 3 ${_arg_output_dir}/initialaverage/initialtarget.nii.gz \
          ${_arg_output_dir}/initialaverage/initialtarget.nii.gz \
          ${_arg_starting_average_resolution} 0 \
          >>${_arg_output_dir}/jobs/${__datetime}/initialaverage
      fi

      debug "$(cat ${_arg_output_dir}/jobs/${__datetime}/initialaverage)"

      if [[ ${_arg_dry_run} == "off" ]]; then
        qbatch ${_arg_block} --logdir ${_arg_output_dir}/logs/${__datetime} \
          --walltime ${_arg_walltime_short} \
          -N ${_arg_jobname_prefix}modelbuild_${__datetime}_initialaverage \
          ${_arg_job_predepend} \
          -- bash ${_arg_output_dir}/jobs/${__datetime}/initialaverage
      fi

      last_round_job="--depend ${_arg_jobname_prefix}modelbuild_${__datetime}_initialaverage"

    else
      info "Generating initial average of all subjects using ${_arg_average_type} and center-of-mass alignment"
      # Bootstrap COM alignment with a normalized mean
      echo AverageImages 3 ${_arg_output_dir}/initialaverage/initialtarget_dumb.nii.gz 2 \
        "${_arg_inputs[@]}" \
        >${_arg_output_dir}/jobs/${__datetime}/initialaverage_dumb
      echo ImageMath 3 ${_arg_output_dir}/initialaverage/initialtarget_dumb.nii.gz \
        PadImage ${_arg_output_dir}/initialaverage/initialtarget_dumb.nii.gz 20 \
        >>${_arg_output_dir}/jobs/${__datetime}/initialaverage_dumb
      echo ThresholdImage 3 ${_arg_output_dir}/initialaverage/initialtarget_dumb.nii.gz \
        ${_arg_output_dir}/initialaverage/bgmask.nii.gz Otsu 4 \
        >>${_arg_output_dir}/jobs/${__datetime}/initialaverage_dumb
      echo ThresholdImage 3 ${_arg_output_dir}/initialaverage/bgmask.nii.gz \
        ${_arg_output_dir}/initialaverage/bgmask.nii.gz 0.5 Inf 1 0 \
        >>${_arg_output_dir}/jobs/${__datetime}/initialaverage_dumb
      echo ExtractRegionFromImageByMask 3 ${_arg_output_dir}/initialaverage/initialtarget_dumb.nii.gz \
        ${_arg_output_dir}/initialaverage/initialtarget_dumb_recrop.nii.gz \
        ${_arg_output_dir}/initialaverage/bgmask.nii.gz 1 20 \
        >>${_arg_output_dir}/jobs/${__datetime}/initialaverage_dumb
      echo cp -f ${_arg_output_dir}/initialaverage/initialtarget_dumb_recrop.nii.gz \
        ${_arg_output_dir}/initialaverage/initialtarget_dumb.nii.gz \
        >>${_arg_output_dir}/jobs/${__datetime}/initialaverage_dumb

      debug "$(cat ${_arg_output_dir}/jobs/${__datetime}/initialaverage_dumb)"

      if [[ ${_arg_dry_run} == "off" ]]; then
        qbatch ${_arg_block} --logdir ${_arg_output_dir}/logs/${__datetime} \
          --walltime ${_arg_walltime_short} \
          -N ${_arg_jobname_prefix}modelbuild_${__datetime}_initialaverage_dumb \
          ${_arg_job_predepend} \
          -- bash ${_arg_output_dir}/jobs/${__datetime}/initialaverage_dumb
      fi

      # Center-of-mass align the files onto the average, create an average and repeat

      for file in "${_arg_inputs[@]}"; do
        echo antsAI -d 3 --convergence 0 \
          -m Mattes[${_arg_output_dir}/initialaverage/initialtarget_dumb.nii.gz,${file},32,None] \
          -o ${_arg_output_dir}/initialaverage/$(basename ${file} | extension_strip).mat \
          -t AlignCentersOfMass >>${_arg_output_dir}/jobs/${__datetime}/initialaverage_reg_com
      done

      for file in "${_arg_inputs[@]}"; do
        echo antsApplyTransforms -d 3 -i ${file} -r ${_arg_output_dir}/initialaverage/initialtarget_dumb.nii.gz \
          -t ${_arg_output_dir}/initialaverage/$(basename ${file} | extension_strip).mat \
          -o ${_arg_output_dir}/initialaverage/$(basename ${file} | extension_strip).nii.gz >>${_arg_output_dir}/jobs/${__datetime}/initialaverage_resample_com
      done

      average_images ${_arg_output_dir}/initialaverage/initialtarget_com.nii.gz \
        $(for j in "${!_arg_inputs[@]}"; do echo -n "${_arg_output_dir}/initialaverage/$(basename ${_arg_inputs[${j}]} | extension_strip).nii.gz "; done) \
        >>${_arg_output_dir}/jobs/${__datetime}/initialaverage_com

      echo ImageMath 3 ${_arg_output_dir}/initialaverage/initialtarget_com.nii.gz \
        PadImage ${_arg_output_dir}/initialaverage/initialtarget_com.nii.gz 20 \
        >>${_arg_output_dir}/jobs/${__datetime}/initialaverage_com
      echo ThresholdImage 3 ${_arg_output_dir}/initialaverage/initialtarget_com.nii.gz \
        ${_arg_output_dir}/initialaverage/bgmask.nii.gz Otsu 4 \
        >>${_arg_output_dir}/jobs/${__datetime}/initialaverage_com
      echo ThresholdImage 3 ${_arg_output_dir}/initialaverage/bgmask.nii.gz \
        ${_arg_output_dir}/initialaverage/bgmask.nii.gz 0.5 Inf 1 0 \
        >>${_arg_output_dir}/jobs/${__datetime}/initialaverage_com
      echo ExtractRegionFromImageByMask 3 ${_arg_output_dir}/initialaverage/initialtarget_com.nii.gz \
        ${_arg_output_dir}/initialaverage/initialtarget_com_recrop.nii.gz \
        ${_arg_output_dir}/initialaverage/bgmask.nii.gz 1 20 \
        >>${_arg_output_dir}/jobs/${__datetime}/initialaverage_com
      echo mv -f ${_arg_output_dir}/initialaverage/initialtarget_com_recrop.nii.gz \
        ${_arg_output_dir}/initialaverage/initialtarget_com.nii.gz \
        >>${_arg_output_dir}/jobs/${__datetime}/initialaverage_com
      if [[ -n ${_arg_starting_average_resolution} ]]; then
        echo ResampleImage 3 ${_arg_output_dir}/initialaverage/initialtarget_com.nii.gz \
          ${_arg_output_dir}/initialaverage/initialtarget.nii.gz ${_arg_starting_average_resolution} 0 \
          >>${_arg_output_dir}/jobs/${__datetime}/initialaverage_com
      else
        echo cp -f ${_arg_output_dir}/initialaverage/initialtarget_com.nii.gz \
          ${_arg_output_dir}/initialaverage/initialtarget.nii.gz \
          >>${_arg_output_dir}/jobs/${__datetime}/initialaverage_com
      fi

      debug "$(cat ${_arg_output_dir}/jobs/${__datetime}/initialaverage_reg_com)"
      debug "$(cat ${_arg_output_dir}/jobs/${__datetime}/initialaverage_resample_com)"
      debug "$(cat ${_arg_output_dir}/jobs/${__datetime}/initialaverage_com)"

      if [[ ${_arg_dry_run} == "off" ]]; then
        qbatch ${_arg_block} --logdir ${_arg_output_dir}/logs/${__datetime} \
          --walltime ${_arg_walltime_short} \
          -N ${_arg_jobname_prefix}modelbuild_${__datetime}_initialaverage_reg_com \
          ${_arg_job_predepend} --depend ${_arg_jobname_prefix}modelbuild_${__datetime}_initialaverage_dumb \
          ${_arg_output_dir}/jobs/${__datetime}/initialaverage_reg_com
        qbatch ${_arg_block} --logdir ${_arg_output_dir}/logs/${__datetime} \
          --walltime ${_arg_walltime_short} \
          -N ${_arg_jobname_prefix}modelbuild_${__datetime}_initialaverage_resample_com \
          ${_arg_job_predepend} --depend ${_arg_jobname_prefix}modelbuild_${__datetime}_initialaverage_reg_com \
          ${_arg_output_dir}/jobs/${__datetime}/initialaverage_resample_com
        qbatch ${_arg_block} --logdir ${_arg_output_dir}/logs/${__datetime} \
          --walltime ${_arg_walltime_short} \
          -N ${_arg_jobname_prefix}modelbuild_${__datetime}_initialaverage_com \
          ${_arg_job_predepend} --depend ${_arg_jobname_prefix}modelbuild_${__datetime}_initialaverage_resample_com \
          -- bash ${_arg_output_dir}/jobs/${__datetime}/initialaverage_com
      fi

      last_round_job="--depend ${_arg_jobname_prefix}modelbuild_${__datetime}_initialaverage_com"
    fi
  else
    last_round_job=""
  fi
  ln -srf ${_arg_output_dir}/initialaverage/initialtarget.nii.gz ${_arg_output_dir}/initialtarget.nii.gz
  target=${_arg_output_dir}/initialtarget.nii.gz
else
  info "Checking starting target"
  if [[ ! -s ${_arg_starting_target} ]]; then
    failure "Starting target ${_arg_starting_target} is non-existant or zero size"
  fi
  cp -f ${_arg_starting_target} ${_arg_output_dir}/initialtarget.nii.gz
  target=${_arg_output_dir}/initialtarget.nii.gz
  last_round_job=""
fi

walltime_reg=${_arg_walltime_linear}

#Convert comma-seperated options into array
IFS=',' read -r -a _arg_stages <<<${_arg_stages}

#Read gradient schedule into array
IFS=',' read -r -a _arg_gradient_step <<<${_arg_gradient_step}

# Looping over different stages of modelbuilding
for reg_type in "${_arg_stages[@]}"; do

  stage_iterations=$(grep -E -o '[0-9]+' <<<${reg_type} || echo ${_arg_iterations})
  reg_type=$(sed -r 's/\[[0-9]+\]//g' <<<${reg_type})

  k=0

  if [[ "${reg_type}" == *volgenmodel*  ]]; then
    tmpdir=$(mktemp -d)
    info "Calculating maximum image feature dimension of template for volgenmodel iterations"
    ThresholdImage 3 ${_arg_output_dir}/initialtarget.nii.gz ${tmpdir}/bgmask.h5 1e-12 Inf 1 0
    ThresholdImage 3 ${_arg_output_dir}/initialtarget.nii.gz ${tmpdir}/otsu.h5 Otsu 4 ${tmpdir}/bgmask.h5 &> /dev/null
    ThresholdImage 3 ${tmpdir}/otsu.h5 ${tmpdir}/otsu.h5 2 Inf 1 0
    LabelGeometryMeasures 3 ${tmpdir}/otsu.h5 none ${tmpdir}/geometry.csv &> /dev/null
    volgenmodel_fixed_maximum_resolution=$(python -c "print(max([ a*b for a,b in zip( [ a-b for a,b in zip( [float(x) for x in \"$(tail -1 ${tmpdir}/geometry.csv | cut -d, -f 14,16,18)\".split(\",\") ],[float(x) for x in \"$(tail -1 ${tmpdir}/geometry.csv | cut -d, -f 13,15,17)\".split(\",\") ])],[abs(x) for x in [float(x) for x in \"$(PrintHeader ${_arg_output_dir}/initialtarget.nii.gz 1)\".split(\"x\")]])]))")
    info "Calculating minimum image feature dimension of template for volgenmodel iterations"
    volgenmodel_fixed_minimum_resolution=$(python -c "print(min([abs(x) for x in [float(x) for x in \"$(PrintHeader ${_arg_output_dir}/initialtarget.nii.gz 1)\".split(\"x\")]]))")
    volgenmodel_iterations=$(ants_generate_iterations.py --min ${volgenmodel_fixed_minimum_resolution} --max ${volgenmodel_fixed_maximum_resolution} | grep shrink | grep -o x | wc -l)
    info "volgenmodel registration will perform ${volgenmodel_iterations} levels with ${stage_iterations} repeats at each level"
    rm -rf ${tmpdir}
  else
    volgenmodel_iterations=0
  fi

  while ((k <= volgenmodel_iterations)); do
  i=0

    if [[ "${reg_type}" == *volgenmodel*  ]]; then
      reg_type=volgenmodel-nlin_${k}

      IFS=: read h m s <<<"${_arg_walltime_nonlinear%.*}"
      walltime_reg=$((10#$s+10#$m*60+10#$h*3600))
      walltime_reg=$(calc "int(${walltime_reg}*8^(${k}/${volgenmodel_iterations} - 1))")
      if ((walltime_reg < 900)); then
        walltime_reg=900
      fi
      walltime_reg=$(date -d@${walltime_reg} -u +%H:%M:%S)
    fi

    while ((i < stage_iterations)); do
      info "Computing ${reg_type} stage iteration $((i + 1)) jobs"

      if [[ ! -z ${_arg_gradient_step[i]:-} ]]; then
        gradient_step=${_arg_gradient_step[i]}
      else
        gradient_step=${_arg_gradient_step[-1]}
      fi

      if [[ ${target} == ${_arg_output_dir}/initialtarget.nii.gz ]]; then
        use_histogram=""
      else
        use_histogram="--histogram-matching"
      fi

      if [[ ! -s ${_arg_output_dir}/${reg_type}/${i}/average/template_sharpen_shapeupdate.nii.gz ]]; then
        mkdir -p ${_arg_output_dir}/${reg_type}/${i}/{transforms,resample,average}
        mkdir -p ${_arg_output_dir}/${reg_type}/${i}/resample/masks

        # Empty files
        >${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_reg
        >${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_maskresample
        >${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_maskaverage

        # Register images to target
        for j in "${!_arg_inputs[@]}"; do

          # Check for existence of moving mask, if it exists, add option
          if [[ -s ${_arg_masks[${j}]} ]]; then
            _mask="--moving-mask ${_arg_masks[${j}]}"
          else
            _mask=""
          fi

          # If target mask is defined, add to the registration command
          if [[ -n ${target_mask} ]]; then
            _mask+=" --fixed-mask ${target_mask}"
          fi

          # If three was a previous round of modelbuilding, bootstrap registration with its affine (if enabled), also do so for nlin-only stages
          if [[ $(basename ${target}) == "template_sharpen_shapeupdate.nii.gz" && $(dirname $(dirname $(dirname $(dirname ${target})))) == "${_arg_output_dir}" && ${_arg_reuse_affines} == "on" ]]; then
            bootstrap="--initial-transform $(dirname $(dirname ${target}))/transforms/$(basename ${_arg_inputs[${j}]} | extension_strip)_0GenericAffine.mat"
          else
            bootstrap=""
          fi
          if [[ ! -s ${_arg_output_dir}/${reg_type}/${i}/resample/$(basename ${_arg_inputs[${j}]} | extension_strip).nii.gz ]]; then
            if [[ ${reg_type} =~ ^(rigid|similarity|affine)$ ]]; then
              # Linear stages of registration
              walltime_reg=${_arg_walltime_linear}
              echo antsRegistration_affine_SyN.sh --clobber \
                ${_arg_float} ${_arg_fast} \
                ${use_histogram} \
                ${_arg_linear_convergence} \
                ${_arg_linear_shrink_factors} \
                ${_arg_linear_smoothing_sigmas} \
                ${_arg_syn_convergence} \
                ${_arg_syn_shrink_factors} \
                ${_arg_syn_smoothing_sigmas} \
                --skip-nonlinear --linear-type ${reg_type} \
                ${_arg_mask_extract} ${_mask} \
                ${bootstrap} \
                --convergence ${_arg_convergence} \
                -o ${_arg_output_dir}/${reg_type}/${i}/resample/$(basename ${_arg_inputs[${j}]} | extension_strip).nii.gz \
                ${_arg_inputs[${j}]} ${target} \
                ${_arg_output_dir}/${reg_type}/${i}/transforms/$(basename ${_arg_inputs[${j}]} | extension_strip)_ \
                >>${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_reg
            elif [[ ${reg_type} == "nlin" ]]; then
              # Full regisration affine + nlin
              walltime_reg=${_arg_walltime_nonlinear}
              echo antsRegistration_affine_SyN.sh --clobber \
                ${_arg_float} ${_arg_fast} \
                ${use_histogram} \
                ${_arg_linear_convergence} \
                ${_arg_linear_shrink_factors} \
                ${_arg_linear_smoothing_sigmas} \
                ${_arg_syn_convergence} \
                ${_arg_syn_shrink_factors} \
                ${_arg_syn_smoothing_sigmas} \
                --syn-control ${_arg_syn_control} \
                -o ${_arg_output_dir}/${reg_type}/${i}/resample/$(basename ${_arg_inputs[${j}]}  | extension_strip).nii.gz \
                ${_arg_mask_extract} ${_mask} \
                ${bootstrap} \
                --convergence ${_arg_convergence} \
                ${_arg_inputs[${j}]} ${target} \
                ${_arg_output_dir}/${reg_type}/${i}/transforms/$(basename ${_arg_inputs[${j}]} | extension_strip)_ \
                >>${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_reg
            elif [[ ${reg_type} == "nlin-only" ]]; then
              # nlin-only registration, affines always bootstrapped from previous iteration (if there is a previous)
              walltime_reg=${_arg_walltime_nonlinear}
              echo antsRegistration_affine_SyN.sh --clobber \
                ${_arg_float} ${_arg_fast} \
                ${use_histogram} \
                ${_arg_linear_convergence} \
                ${_arg_linear_shrink_factors} \
                ${_arg_linear_smoothing_sigmas} \
                ${_arg_syn_convergence} \
                ${_arg_syn_shrink_factors} \
                ${_arg_syn_smoothing_sigmas} \
                --syn-control ${_arg_syn_control} \
                -o ${_arg_output_dir}/${reg_type}/${i}/resample/$(basename ${_arg_inputs[${j}]} | extension_strip).nii.gz \
                ${_arg_mask_extract} ${_mask} \
                ${bootstrap} \
                --skip-linear \
                --convergence ${_arg_convergence} \
                ${_arg_inputs[${j}]} ${target} \
                ${_arg_output_dir}/${reg_type}/${i}/transforms/$(basename ${_arg_inputs[${j}]} | extension_strip)_ \
                >>${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_reg
            elif [[ ${reg_type} == *volgenmodel* ]]; then
              # nlin-only registration, affines always bootstrapped from previous iteration (if there is a previous)
                echo antsRegistration_affine_SyN.sh --clobber \
                  --volgenmodel-iteration ${k} \
                  ${_arg_float} ${_arg_fast} \
                  ${use_histogram} \
                  ${_arg_linear_convergence} \
                  ${_arg_linear_shrink_factors} \
                  ${_arg_linear_smoothing_sigmas} \
                  ${_arg_syn_convergence} \
                  ${_arg_syn_shrink_factors} \
                  ${_arg_syn_smoothing_sigmas} \
                  -o ${_arg_output_dir}/${reg_type}/${i}/resample/$(basename ${_arg_inputs[${j}]} | extension_strip).nii.gz \
                  ${_arg_mask_extract} ${_mask} \
                  --skip-linear \
                  --initial-transform $(dirname $(dirname ${target}))/transforms/$(basename ${_arg_inputs[${j}]} | extension_strip)_0GenericAffine.mat \
                  --convergence ${_arg_convergence} \
                  ${_arg_inputs[${j}]} ${target} \
                  ${_arg_output_dir}/${reg_type}/${i}/transforms/$(basename ${_arg_inputs[${j}]} | extension_strip)_ \
                  >>${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_reg
            fi
          fi
          # If input masks were provided, resample them using the registration
          if [[ ! -s ${_arg_output_dir}/${reg_type}/${i}/resample/masks/$(basename ${_arg_inputs[${j}]} | extension_strip).nii.gz && -s ${_arg_masks[${j}]} ]]; then
            if [[ ${reg_type} =~ ^(rigid|similarity|affine)$ ]]; then
              echo antsApplyTransforms -d 3 ${_arg_float} \
                -i ${_arg_masks[${j}]} \
                -n GenericLabel \
                -r ${_arg_output_dir}/${reg_type}/${i}/resample/$(basename ${_arg_inputs[${j}]} | extension_strip).nii.gz \
                -t ${_arg_output_dir}/${reg_type}/${i}/transforms/$(basename ${_arg_inputs[${j}]} | extension_strip)_0GenericAffine.mat \
                -o ${_arg_output_dir}/${reg_type}/${i}/resample/masks/$(basename ${_arg_inputs[${j}]} | extension_strip).nii.gz \
                >>${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_maskresample
            else
              echo antsApplyTransforms -d 3 ${_arg_float} \
                -i ${_arg_masks[${j}]} \
                -n GenericLabel \
                -r ${_arg_output_dir}/${reg_type}/${i}/resample/$(basename ${_arg_inputs[${j}]} | extension_strip).nii.gz \
                -t ${_arg_output_dir}/${reg_type}/${i}/transforms/$(basename ${_arg_inputs[${j}]} | extension_strip)_1Warp.nii.gz \
                -t ${_arg_output_dir}/${reg_type}/${i}/transforms/$(basename ${_arg_inputs[${j}]} | extension_strip)_0GenericAffine.mat \
                -o ${_arg_output_dir}/${reg_type}/${i}/resample/masks/$(basename ${_arg_inputs[${j}]} | extension_strip).nii.gz \
                >>${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_maskresample
            fi
          fi
        done

        # If masks were supplied, merge them and hard threshold at >25% confidence
        if [[ " ${_arg_masks[@]} " =~ ".nii" ]]; then
          if [[ ! -s ${_arg_output_dir}/${reg_type}/${i}/average/mask.nii.gz ]]; then
            echo AverageImages 3 ${_arg_output_dir}/${reg_type}/${i}/average/mask.nii.gz 0 \
              $(for j in "${!_arg_inputs[@]}"; do
                if [[ -s ${_arg_masks[${j}]} ]]; then
                  echo -n "${_arg_output_dir}/${reg_type}/${i}/resample/masks/$(basename ${_arg_inputs[${j}]} | extension_strip).nii.gz "
                fi
                ((++j))
              done) >${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_maskaverage

            echo ThresholdImage 3 ${_arg_output_dir}/${reg_type}/${i}/average/mask.nii.gz \
              ${_arg_output_dir}/${reg_type}/${i}/average/mask.nii.gz ${_arg_mask_merge_threshold} Inf 1 0 \
              >>${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_maskaverage
          fi
          target_mask=${_arg_output_dir}/${reg_type}/${i}/average/mask_shapeupdate.nii.gz
        else
          target_mask=""
        fi

        debug "$(cat ${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_reg)"
        debug "$(cat ${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_maskresample)"
        debug "$(cat ${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_maskaverage)"

        if [[ ${_arg_dry_run} == "off" ]]; then
          qbatch ${_arg_block} --logdir ${_arg_output_dir}/logs/${__datetime} \
            --walltime ${walltime_reg} \
            -N ${_arg_jobname_prefix}modelbuild_${__datetime}_${reg_type}_${i}_reg \
            ${_arg_job_predepend} \
            ${last_round_job} \
            ${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_reg
          if [[ -s ${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_maskresample ]]; then
            qbatch ${_arg_block} --logdir ${_arg_output_dir}/logs/${__datetime} \
              --walltime ${_arg_walltime_short} \
              -N ${_arg_jobname_prefix}modelbuild_${__datetime}_${reg_type}_${i}_maskresample \
              ${_arg_job_predepend} --depend ${_arg_jobname_prefix}modelbuild_${__datetime}_${reg_type}_${i}_reg* \
              --chunksize 0 \
              ${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_maskresample
          fi
          # Need a special test here in case jobfile is empty
          if [[ -s ${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_maskaverage ]]; then
            qbatch ${_arg_block} --logdir ${_arg_output_dir}/logs/${__datetime} \
              --walltime ${_arg_walltime_short} \
              -N ${_arg_jobname_prefix}modelbuild_${__datetime}_${reg_type}_${i}_maskaverage \
              ${_arg_job_predepend} --depend ${_arg_jobname_prefix}modelbuild_${__datetime}_${reg_type}_${i}_maskresample* \
              -- bash ${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_maskaverage
          fi
        fi

        rm -f ${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_shapeupdate &&
          touch ${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_shapeupdate
        last_round_job=""

        # Now we average the transformed input scans and shape update
        if [[ ! -s ${_arg_output_dir}/${reg_type}/${i}/average/template_sharpen_shapeupdate.nii.gz ]]; then
          echo "#!/bin/bash" >${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_shapeupdate
          echo "set -euo pipefail" >>${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_shapeupdate

        average_images ${_arg_output_dir}/${reg_type}/${i}/average/template.nii.gz \
          $(for j in "${!_arg_inputs[@]}"; do echo -n "${_arg_output_dir}/${reg_type}/${i}/resample/$(basename ${_arg_inputs[${j}]} | extension_strip).nii.gz "; done) \
          >>${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_shapeupdate

          # Shape updating
          case ${_arg_sharpen_type} in
          laplacian)
            echo ImageMath 3 ${_arg_output_dir}/${reg_type}/${i}/average/template_sharpen.nii.gz \
              Sharpen ${_arg_output_dir}/${reg_type}/${i}/average/template.nii.gz \
              >>${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_shapeupdate
            ;;
          unsharp)
            echo ImageMath 3 ${_arg_output_dir}/${reg_type}/${i}/average/template_sharpen.nii.gz \
              UnsharpMask ${_arg_output_dir}/${reg_type}/${i}/average/template.nii.gz 0.5 1 0 0 \
              >>${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_shapeupdate
            ;;
          none)
            echo cp -f ${_arg_output_dir}/${reg_type}/${i}/average/template.nii.gz \
              ${_arg_output_dir}/${reg_type}/${i}/average/template_sharpen.nii.gz \
              >>${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_shapeupdate
            ;;
          esac

          # We threshold greater than zero so we don't get negative values
          echo ThresholdImage 3 ${_arg_output_dir}/${reg_type}/${i}/average/template_sharpen.nii.gz \
            ${_arg_output_dir}/${reg_type}/${i}/average/nonzero.nii.gz 1e-12 Inf 1 0 \
            >>${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_shapeupdate
          echo ImageMath 3 ${_arg_output_dir}/${reg_type}/${i}/average/template_sharpen.nii.gz m \
            ${_arg_output_dir}/${reg_type}/${i}/average/template_sharpen.nii.gz \
            ${_arg_output_dir}/${reg_type}/${i}/average/nonzero.nii.gz \
            >>${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_shapeupdate

          if [[ ${reg_type} =~ ^(rigid|similarity|affine)$ && ${_arg_affine_shape_update} == "on" ]]; then
            # Average all the affine transforms
            if [[ ${_arg_average_prog} == "ANTs" ]]; then
              if [[ ${_arg_rigid_update} == "on" ]]; then
                echo AverageAffineTransform 3 ${_arg_output_dir}/${reg_type}/${i}/average/affine.mat \
                  $(for j in "${!_arg_inputs[@]}"; do echo -n "${_arg_output_dir}/${reg_type}/${i}/transforms/$(basename ${_arg_inputs[${j}]} | extension_strip)_0GenericAffine.mat "; done) \
                  >>${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_shapeupdate
              else
                echo AverageAffineTransformNoRigid 3 ${_arg_output_dir}/${reg_type}/${i}/average/affine.mat \
                  $(for j in "${!_arg_inputs[@]}"; do echo -n "${_arg_output_dir}/${reg_type}/${i}/transforms/$(basename ${_arg_inputs[${j}]} | extension_strip)_0GenericAffine.mat "; done) \
                  >>${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_shapeupdate
              fi
            else
              if [[ ${_arg_rigid_update} == "on" ]]; then
                echo ${__dir}/sitk_average_affine_transforms.py -o ${_arg_output_dir}/${reg_type}/${i}/average/affine.mat \
                  --file-list $(for j in "${!_arg_inputs[@]}"; do echo -n "${_arg_output_dir}/${reg_type}/${i}/transforms/$(basename ${_arg_inputs[${j}]} | extension_strip)_0GenericAffine.mat "; done) \
                  >>${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_shapeupdate
              else
                echo ${__dir}/sitk_average_affine_transforms.py -o ${_arg_output_dir}/${reg_type}/${i}/average/affine.mat \
                  --no-rigid \
                  --file-list $(for j in "${!_arg_inputs[@]}"; do echo -n "${_arg_output_dir}/${reg_type}/${i}/transforms/$(basename ${_arg_inputs[${j}]} | extension_strip)_0GenericAffine.mat "; done) \
                  >>${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_shapeupdate
              fi
            fi

            # If python code is available, scale affine
            if [[ ${_arg_scale_affines} == "on" ]]; then
              # Invert the transform so we scale from the correct direction
              echo antsApplyTransforms -d 3 -t ${_arg_output_dir}/${reg_type}/${i}/average/affine.mat -o Linear[ ${_arg_output_dir}/${reg_type}/${i}/average/affine_inverted.mat,1 ] \
              >>${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_shapeupdate

              # Scale the transform
              echo ${__dir}/interp_transform.py ${_arg_output_dir}/${reg_type}/${i}/average/affine_inverted.mat ${gradient_step} ${_arg_output_dir}/${reg_type}/${i}/average/affine_inverted_scaled.mat \
              >>${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_shapeupdate

              shapeupdate_affine="${_arg_output_dir}/${reg_type}/${i}/average/affine_inverted_scaled.mat"
            else
              shapeupdate_affine="[ ${_arg_output_dir}/${reg_type}/${i}/average/affine.mat,1 ]"
            fi
          else
            # Generate identity transforms so affine shape update doesn't happen for nlin-only stage
            echo ImageMath 3 ${_arg_output_dir}/${reg_type}/${i}/average/affine.mat MakeAffineTransform 1 \
              >>${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_shapeupdate
            shapeupdate_affine="[ ${_arg_output_dir}/${reg_type}/${i}/average/affine.mat,1 ]"
          fi

          # Now we update the template shape using the same steps as the original code
          if [[ ( ${reg_type} == *nlin* ) && ( ${_arg_nlin_shape_update} == "on" ) ]]; then
            # Average all the warp transforms
            echo AverageImages 3 ${_arg_output_dir}/${reg_type}/${i}/average/warp.nii.gz \
              0 $(for j in "${!_arg_inputs[@]}"; do echo -n "${_arg_output_dir}/${reg_type}/${i}/transforms/$(basename ${_arg_inputs[${j}]} | extension_strip)_1Warp.nii.gz "; done) \
              >>${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_shapeupdate

            # Scale warp average by the gradient step (note the gradient step is negative!!)
            echo MultiplyImages 3 ${_arg_output_dir}/${reg_type}/${i}/average/warp.nii.gz \
              -${gradient_step} ${_arg_output_dir}/${reg_type}/${i}/average/scaled_warp.nii.gz \
              >>${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_shapeupdate

            # Apply the inverse affine to the scaled warp
            echo antsApplyTransforms -d 3 -e vector ${_arg_float} \
              -i ${_arg_output_dir}/${reg_type}/${i}/average/scaled_warp.nii.gz \
              -o ${_arg_output_dir}/${reg_type}/${i}/average/affine_scaled_warp.nii.gz \
              -t ${shapeupdate_affine} \
              -r ${_arg_output_dir}/${reg_type}/${i}/average/template_sharpen.nii.gz \
              >>${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_shapeupdate

            # Apply the scaled warp 4 times to the template, then apply the inverse affine
            echo antsApplyTransforms -d 3 ${_arg_float} \
              -i ${_arg_output_dir}/${reg_type}/${i}/average/template_sharpen.nii.gz \
              -o ${_arg_output_dir}/${reg_type}/${i}/average/template_sharpen_shapeupdate.nii.gz \
              -n BSpline[5] \
              -t ${shapeupdate_affine} \
              -t ${_arg_output_dir}/${reg_type}/${i}/average/affine_scaled_warp.nii.gz \
              -t ${_arg_output_dir}/${reg_type}/${i}/average/affine_scaled_warp.nii.gz \
              -t ${_arg_output_dir}/${reg_type}/${i}/average/affine_scaled_warp.nii.gz \
              -t ${_arg_output_dir}/${reg_type}/${i}/average/affine_scaled_warp.nii.gz \
              -r ${_arg_output_dir}/${reg_type}/${i}/average/template_sharpen.nii.gz \
              >>${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_shapeupdate

            # Shape update the mask if it is used
            if [[ " ${_arg_masks[@]} " =~ .nii ]]; then
              echo antsApplyTransforms -d 3 ${_arg_float} \
                -i ${_arg_output_dir}/${reg_type}/${i}/average/mask.nii.gz \
                -o ${_arg_output_dir}/${reg_type}/${i}/average/mask_shapeupdate.nii.gz \
                -n GenericLabel \
                -t ${shapeupdate_affine} \
                -t ${_arg_output_dir}/${reg_type}/${i}/average/affine_scaled_warp.nii.gz \
                -t ${_arg_output_dir}/${reg_type}/${i}/average/affine_scaled_warp.nii.gz \
                -t ${_arg_output_dir}/${reg_type}/${i}/average/affine_scaled_warp.nii.gz \
                -t ${_arg_output_dir}/${reg_type}/${i}/average/affine_scaled_warp.nii.gz \
                -r ${_arg_output_dir}/${reg_type}/${i}/average/template_sharpen.nii.gz \
                >>${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_shapeupdate
            fi

          else
            # Shape update a rigid/similarity/affine template by simply applying the inverse average affine
            echo antsApplyTransforms -d 3 ${_arg_float} \
              -i ${_arg_output_dir}/${reg_type}/${i}/average/template_sharpen.nii.gz \
              -o ${_arg_output_dir}/${reg_type}/${i}/average/template_sharpen_shapeupdate.nii.gz \
              -n BSpline[5] \
              -t ${shapeupdate_affine} \
              -r ${_arg_output_dir}/${reg_type}/${i}/average/template_sharpen.nii.gz \
              >>${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_shapeupdate

            # Shape update the mask if it is used
            if [[ " ${_arg_masks[@]} " =~ .nii ]]; then
              echo antsApplyTransforms -d 3 ${_arg_float} \
                -i ${_arg_output_dir}/${reg_type}/${i}/average/mask.nii.gz \
                -o ${_arg_output_dir}/${reg_type}/${i}/average/mask_shapeupdate.nii.gz \
                -n GenericLabel \
                -t ${shapeupdate_affine} \
                -r ${_arg_output_dir}/${reg_type}/${i}/average/template_sharpen.nii.gz \
                >>${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_shapeupdate
            fi
          fi

          # Because we use BSpline resampling, we need to truncate the negative values it generates
          echo ThresholdImage 3 ${_arg_output_dir}/${reg_type}/${i}/average/template_sharpen_shapeupdate.nii.gz \
            ${_arg_output_dir}/${reg_type}/${i}/average/nonzero.nii.gz 1e-12 Inf 1 0 \
            >>${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_shapeupdate
          echo ImageMath 3 ${_arg_output_dir}/${reg_type}/${i}/average/template_sharpen_shapeupdate.nii.gz m \
            ${_arg_output_dir}/${reg_type}/${i}/average/template_sharpen_shapeupdate.nii.gz \
            ${_arg_output_dir}/${reg_type}/${i}/average/nonzero.nii.gz \
            >>${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_shapeupdate

          debug "$(cat ${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_shapeupdate)"

          if [[ ${_arg_dry_run} == "off" ]]; then
            qbatch ${_arg_block} --logdir ${_arg_output_dir}/logs/${__datetime} \
              --walltime ${_arg_walltime_short} -N ${_arg_jobname_prefix}modelbuild_${__datetime}_${reg_type}_${i}_shapeupdate \
              ${_arg_job_predepend} --depend ${_arg_jobname_prefix}modelbuild_${__datetime}_${reg_type}_${i}_reg \
              --depend ${_arg_jobname_prefix}modelbuild_${__datetime}_${reg_type}_${i}_maskaverage \
              -- bash ${_arg_output_dir}/jobs/${__datetime}/${reg_type}_${i}_shapeupdate
          fi
          last_round_job="--depend ${_arg_jobname_prefix}modelbuild_${__datetime}_${reg_type}_${i}_shapeupdate"
        fi

      fi

      target=${_arg_output_dir}/${reg_type}/${i}/average/template_sharpen_shapeupdate.nii.gz
      if [[ -n ${target_mask} ]]; then
          target_mask=${_arg_output_dir}/${reg_type}/${i}/average/mask_shapeupdate.nii.gz
      fi

      ((++i))
    done

    ((++k))

  done

done

if [[ ! -L ${_arg_output_dir}/final ]]; then
    ln -srf ${_arg_output_dir}/${reg_type}/$((i - 1)) ${_arg_output_dir}/final
fi

if [[ -s ${_arg_final_target} ]]; then
  mkdir -p ${_arg_output_dir}/final-target
  if [[ ! -s ${_arg_output_dir}/final-target/to_target_1Warp.nii.gz ]]; then
    echo ConvertImage 3 ${_arg_final_target} ${_arg_output_dir}/final-target/final_target.nii.gz \
        > ${_arg_output_dir}/jobs/${__datetime}/final_target
    if [[ -n ${_arg_final_target_mask} ]]; then
      echo ConvertImage 3 ${_arg_final_target_mask} ${_arg_output_dir}/final-target/final_target_mask.nii.gz \
          >> ${_arg_output_dir}/jobs/${__datetime}/final_target
      _arg_final_target_mask="--fixed-mask ${_arg_output_dir}/final-target/final_target_mask.nii.gz"
    else
      _arg_final_target_mask=""
    fi
    if [[ -n ${target_mask} ]]; then
      target_mask="--moving-mask ${target_mask}"
    else
      target_mask=""
    fi
    echo antsRegistration_affine_SyN.sh \
      ${_arg_float} ${_arg_fast} \
      ${_arg_linear_convergence} \
      ${_arg_linear_shrink_factors} \
      ${_arg_linear_smoothing_sigmas} \
      ${_arg_syn_convergence} \
      ${_arg_syn_shrink_factors} \
      ${_arg_syn_smoothing_sigmas} \
      ${_arg_final_target_mask} \
      ${target_mask} \
      ${_arg_output_dir}/final/average/template_sharpen_shapeupdate.nii.gz \
      ${_arg_output_dir}/final-target/final_target.nii.gz \
      ${_arg_output_dir}/final-target/to_target_ \
        >> ${_arg_output_dir}/jobs/${__datetime}/final_target

    debug "$(cat ${_arg_output_dir}/jobs/${__datetime}/final_target)"

    if [[ ${_arg_dry_run} == "off" ]]; then
      # We use the walltime for a linear job here because its a single registration
      qbatch ${_arg_block} --logdir ${_arg_output_dir}/logs/${__datetime} \
        --walltime ${_arg_walltime_linear} \
        ${_arg_job_predepend} \
        --depend ${_arg_jobname_prefix}modelbuild_${__datetime}_${reg_type}_$((i - 1))_shapeupdate \
        -N ${_arg_jobname_prefix}modelbuild_${__datetime}_final_target \
        -- bash ${_arg_output_dir}/jobs/${__datetime}/final_target
    fi
  fi
fi

# ] <-- needed because of Argbash
