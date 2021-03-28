#!/bin/bash
# ARG_HELP([A qbatch and optimal registration pyramid based re-implementaiton fo antsMultivariateTemplateConstruction2.sh])
# ARG_OPTIONAL_SINGLE([output-dir],[],[Output directory for modelbuild],[output])
# ARG_OPTIONAL_SINGLE([gradient-step],[],[Gradient scaling step during template warping],[0.25])
# ARG_OPTIONAL_SINGLE([starting-target],[],[Initial image used to start modelbuild, defines orientation and voxel space, if 'none' a average all subjects is constructed as a starting target],[none])
# ARG_OPTIONAL_SINGLE([starting-target-mask],[],[Mask for starting target],[])
# ARG_OPTIONAL_SINGLE([iterations],[],[Number of iterations of model building per stage],[3])
# ARG_OPTIONAL_SINGLE([convergence],[],[Convergence limit during registration calls],[1e-7])
# ARG_OPTIONAL_BOOLEAN([fast],[],[Run SyN registration with Mattes instead of CC],[])
# ARG_OPTIONAL_BOOLEAN([debug],[],[Debug mode, print all commands to stdout],[])
# ARG_OPTIONAL_BOOLEAN([dry-run],[],[Dry run, don't run any commands, implies debug],[])
# ARG_OPTIONAL_SINGLE([average-type],[],[Type of averaging to apply during modelbuild],[normmean])
# ARG_OPTIONAL_SINGLE([masks],[],[File containing mask filenames, one file per line],[])
# ARG_TYPE_GROUP_SET([averagetype],[AVERAGE],[average-type],[mean,median,normmean])
# ARG_OPTIONAL_SINGLE([sharpen-type],[],[Type of sharpening applied to average during modelbuild],[unsharp])
# ARG_TYPE_GROUP_SET([sharptypetype],[SHARPEN],[sharpen-type],[none,laplacian,unsharp])
# ARG_OPTIONAL_REPEATED([stages],[],[Stages of modelbuild used],['rigid' 'similarity' 'affine' 'nlin'])
# ARG_POSITIONAL_INF([inputs],[list of input files],[1])
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
	local _allowed=("mean" "median" "normmean") _seeking="$1"
	for element in "${_allowed[@]}"
	do
		test "$element" = "$_seeking" && echo "$element" && return 0
	done
	die "Value '$_seeking' (of argument '$2') doesn't match the list of allowed values: 'mean', 'median' and 'normmean'" 4
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
_arg_iterations="3"
_arg_convergence="1e-7"
_arg_fast="off"
_arg_debug="off"
_arg_dry_run="off"
_arg_average_type="normmean"
_arg_masks=
_arg_sharpen_type="unsharp"
_arg_stages=('rigid' 'similarity' 'affine' 'nlin')


print_help()
{
	printf '%s\n' "A qbatch and optimal registration pyramid based re-implementaiton fo antsMultivariateTemplateConstruction2.sh"
	printf 'Usage: %s [-h|--help] [--output-dir <arg>] [--gradient-step <arg>] [--starting-target <arg>] [--starting-target-mask <arg>] [--iterations <arg>] [--convergence <arg>] [--(no-)fast] [--(no-)debug] [--(no-)dry-run] [--average-type <AVERAGE>] [--masks <arg>] [--sharpen-type <SHARPEN>] [--stages <arg>] <inputs-1> [<inputs-2>] ... [<inputs-n>] ...\n' "$0"
	printf '\t%s\n' "<inputs>: list of input files"
	printf '\t%s\n' "-h, --help: Prints help"
	printf '\t%s\n' "--output-dir: Output directory for modelbuild (default: 'output')"
	printf '\t%s\n' "--gradient-step: Gradient scaling step during template warping (default: '0.25')"
	printf '\t%s\n' "--starting-target: Initial image used to start modelbuild, defines orientation and voxel space, if 'none' a average all subjects is constructed as a starting target (default: 'none')"
	printf '\t%s\n' "--starting-target-mask: Mask for starting target (no default)"
	printf '\t%s\n' "--iterations: Number of iterations of model building per stage (default: '3')"
	printf '\t%s\n' "--convergence: Convergence limit during registration calls (default: '1e-7')"
	printf '\t%s\n' "--fast, --no-fast: Run SyN registration with Mattes instead of CC (off by default)"
	printf '\t%s\n' "--debug, --no-debug: Debug mode, print all commands to stdout (off by default)"
	printf '\t%s\n' "--dry-run, --no-dry-run: Dry run, don't run any commands, implies debug (off by default)"
	printf '\t%s\n' "--average-type: Type of averaging to apply during modelbuild. Can be one of: 'mean', 'median' and 'normmean' (default: 'normmean')"
	printf '\t%s\n' "--masks: File containing mask filenames, one file per line (no default)"
	printf '\t%s\n' "--sharpen-type: Type of sharpening applied to average during modelbuild. Can be one of: 'none', 'laplacian' and 'unsharp' (default: 'unsharp')"
	printf '\t%s' "--stages: Stages of modelbuild used (default array elements:"
	printf " '%s'" 'rigid' 'similarity' 'affine' 'nlin'
	printf ')\n'
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
			--no-fast|--fast)
				_arg_fast="on"
				test "${1:0:5}" = "--no-" && _arg_fast="off"
				;;
			--no-debug|--debug)
				_arg_debug="on"
				test "${1:0:5}" = "--no-" && _arg_debug="off"
				;;
			--no-dry-run|--dry-run)
				_arg_dry_run="on"
				test "${1:0:5}" = "--no-" && _arg_dry_run="off"
				;;
			--average-type)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_average_type="$(averagetype "$2" "average-type")" || exit 1
				shift
				;;
			--average-type=*)
				_arg_average_type="$(averagetype "${_key##--average-type=}" "average-type")" || exit 1
				;;
			--masks)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_masks="$2"
				shift
				;;
			--masks=*)
				_arg_masks="${_key##--masks=}"
				;;
			--sharpen-type)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_sharpen_type="$(sharptypetype "$2" "sharpen-type")" || exit 1
				shift
				;;
			--sharpen-type=*)
				_arg_sharpen_type="$(sharptypetype "${_key##--sharpen-type=}" "sharpen-type")" || exit 1
				;;
			--stages)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_stages+=("$2")
				shift
				;;
			--stages=*)
				_arg_stages+=("${_key##--stages=}")
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


set -euo pipefail

# Register all images to the template.
# Average all warped images to create a new template.
# Average all the transforms from 1 to create a single transform.
# Apply the transform from 3 the template to warp the template towards the true mean shape.
# Use a sharpening filter on the adjusted template to enhance edges.
# Go back to 1.

function run_smart {
  #Function runs the command it wraps if the file does not exist
  if [[ ! -s "$1" ]]; then
    "$2"
  fi
}

mkdir -p ${_arg_output_dir}/jobs

mapfile -t _arg_inputs < ${_arg_inputs[0]}

# Fill up array of masks
if [[ -z ${_arg_masks} ]]; then
  _arg_masks=()
  for file in "${_arg_inputs[@]}"; do
    _arg_masks+=('NONE')
  done
else
  mapfile -t _arg_masks < ${_arg_masks}
fi

target_mask=${_arg_starting_target_mask}

# Enable fast mode in antsRegistration_affine_SyN.sh
if [[ ${_arg_fast} == "on" ]]; then
  _arg_fast="--fast"
else
  _arg_fast=""
fi

# If no starting target is supplied, create one
if [[ ${_arg_starting_target} == "none" ]]; then
  if [[ ! -s ${_arg_output_dir}/startingtarget.nii.gz ]]; then
    case ${_arg_average_type} in
      mean)
        echo AverageImages 3 ${_arg_output_dir}/startingtarget.nii.gz 0 "${_arg_inputs[@]}" > ${_arg_output_dir}/jobs/initialaverage
        ;;
      normmean)
        AverageImages 3 ${_arg_output_dir}/startingtarget.nii.gz 2 "${_arg_inputs[@]}" > ${_arg_output_dir}/jobs/initialaverage
        ;;
      median)
        printf '%s\n' "${_arg_inputs[@]}" > ${_arg_output_dir}/medianlist.txt
        ImageSetStatistics 3 ${_arg_output_dir}/medianlist.txt ${_arg_output_dir}/startingtarget.nii.gz 0 > ${_arg_output_dir}/jobs/initialaverage
        ;;
    esac

    if [[ ${_arg_dry_run} == "on" || ${_arg_debug} == "on" ]]; then
      cat ${_arg_output_dir}/jobs/initialaverage
    fi

    if [[ ${_arg_dry_run} == "off" ]]; then
      bash ${_arg_output_dir}/jobs/initialaverage
    fi


  fi
  target=${_arg_output_dir}/startingtarget.nii.gz
else
  target=${_arg_starting_target}
fi

#AVERAGE_AFFINE_PROGRAM="AverageAffineTransform"
AVERAGE_AFFINE_PROGRAM="AverageAffineTransformNoRigid"

# Looping over different stages of modelbuilding
for reg_type in "${_arg_stages[@]}"; do

  i=0

  while ((i < _arg_iterations)); do

    if [[ ! -s ${_arg_output_dir}/${reg_type}/${i}/average/template_shapeupdate.nii.gz ]]; then
      mkdir -p ${_arg_output_dir}/${reg_type}/${i}/{transforms,resample,average}

      # Register images to target
      rm -f ${_arg_output_dir}/jobs/${reg_type}_${i}_reg && touch ${_arg_output_dir}/jobs/${reg_type}_${i}_reg
      rm -f ${_arg_output_dir}/jobs/${reg_type}_${i}_maskresample && touch ${_arg_output_dir}/jobs/${reg_type}_${i}_maskresample
      rm -f ${_arg_output_dir}/jobs/${reg_type}_${i}_maskaverage && touch ${_arg_output_dir}/jobs/${reg_type}_${i}_maskaverage
      for j in "${!_arg_inputs[@]}"; do

        #Check for existance of moving mask, if it exists, add option
        if [[ -s ${_arg_masks[${j}]} ]]; then
          _mask="--moving-mask ${_arg_masks[${j}]}"
          mkdir -p ${_arg_output_dir}/${reg_type}/${i}/resample/masks
        else
          _mask=""
        fi

        # If target mask is defined, add to the registration command
        if [[ -n ${target_mask} ]]; then
          _mask+=" --fixed-mask ${target_mask}"
        fi

        # If three was a previous round of modelbuilding, bootstrap registration with affine
        if [[ $(basename ${target}) == "template_sharpen_shapeupdate.nii.gz" ]]; then
          bootstrap="--close --initial-transform $(dirname $(dirname ${target}))/transforms/$(basename ${_arg_inputs[${j}]} | sed -r 's/(.nii$|.nii.gz$)//g')_0GenericAffine.mat"
        else
          bootstrap=""
        fi
        if [[ ! -s ${_arg_output_dir}/${reg_type}/${i}/resample/$(basename ${_arg_inputs[${j}]}) ]]; then
          if [[ ${reg_type} != "nlin" ]]; then
            echo antsRegistration_affine_SyN.sh --clobber \
              --skip-nonlinear --linear-type ${reg_type} ${_arg_fast} \
              ${_mask} \
              ${bootstrap} \
              --convergence ${_arg_convergence} \
              -o ${_arg_output_dir}/${reg_type}/${i}/resample/$(basename ${_arg_inputs[${j}]}) \
              ${_arg_inputs[${j}]} ${target} \
              ${_arg_output_dir}/${reg_type}/${i}/transforms/$(basename ${_arg_inputs[${j}]} | sed -r 's/(.nii$|.nii.gz$)//g')_ \
              >> ${_arg_output_dir}/jobs/${reg_type}_${i}_reg
            if [[ -s ${_arg_masks[${j}]} ]]; then
              echo antsApplyTransforms -d 3 -i ${_arg_masks[${j}]} \
                -n GenericLabel \
                -r ${_arg_output_dir}/${reg_type}/${i}/resample/$(basename ${_arg_inputs[${j}]}) \
                -t ${_arg_output_dir}/${reg_type}/${i}/transforms/$(basename ${_arg_inputs[${j}]} | sed -r 's/(.nii$|.nii.gz$)//g')_0GenericAffine.mat \
                -o ${_arg_output_dir}/${reg_type}/${i}/resample/masks/$(basename ${_arg_inputs[${j}]}) \
                >> ${_arg_output_dir}/jobs/${reg_type}_${i}_maskresample
            fi
          else
            echo antsRegistration_affine_SyN.sh --clobber \
              -o ${_arg_output_dir}/${reg_type}/${i}/resample/$(basename ${_arg_inputs[${j}]}) \
              ${_mask} \
              ${bootstrap} \
              --convergence ${_arg_convergence} \
              ${_arg_inputs[${j}]} ${target} \
              ${_arg_output_dir}/${reg_type}/${i}/transforms/$(basename ${_arg_inputs[${j}]} | sed -r 's/(.nii$|.nii.gz$)//g')_ \
              >> ${_arg_output_dir}/jobs/${reg_type}_${i}_reg
            if [[ -s ${_arg_masks[${j}]} ]]; then
              echo antsApplyTransforms -d 3 -i ${_arg_masks[${j}]} \
                -n GenericLabel \
                -r ${_arg_output_dir}/${reg_type}/${i}/resample/$(basename ${_arg_inputs[${j}]}) \
                -t ${_arg_output_dir}/${reg_type}/${i}/transforms/$(basename ${_arg_inputs[${j}]} | sed -r 's/(.nii$|.nii.gz$)//g')_1Warp.nii.gz \
                -t ${_arg_output_dir}/${reg_type}/${i}/transforms/$(basename ${_arg_inputs[${j}]} | sed -r 's/(.nii$|.nii.gz$)//g')_0GenericAffine.mat \
                -o ${_arg_output_dir}/${reg_type}/${i}/resample/masks/$(basename ${_arg_inputs[${j}]}) \
                >> ${_arg_output_dir}/jobs/${reg_type}_${i}_maskresample
            fi
          fi
        fi
      done

      if [[ ${_arg_masks[0]} != "NONE" ]]; then
        if [[ ! -s ${_arg_output_dir}/${reg_type}/${i}/average/mask.nii.gz ]]; then
          echo AverageImages 3 ${_arg_output_dir}/${reg_type}/${i}/average/mask.nii.gz 0 \
            $(for j in "${!_arg_inputs[@]}"; do if [[ -s ${_arg_masks[${j}]} ]]; then
              echo -n "${_arg_output_dir}/${reg_type}/${i}/resample/masks/$(basename ${_arg_inputs[${j}]}) "; fi
              ((++j))
          done) > ${_arg_output_dir}/jobs/${reg_type}_${i}_maskaverage

          echo ThresholdImage 3 ${_arg_output_dir}/${reg_type}/${i}/average/mask.nii.gz \
            ${_arg_output_dir}/${reg_type}/${i}/average/mask.nii.gz 1e-12 Inf 1 0 \
            >> ${_arg_output_dir}/jobs/${reg_type}_${i}_maskaverage
        fi
        target_mask=${_arg_output_dir}/${reg_type}/${i}/average/mask.nii.gz
      else
        target_mask=""
      fi

      if [[ ${_arg_dry_run} == "on" || ${_arg_debug} == "on" ]]; then
        cat ${_arg_output_dir}/jobs/${reg_type}_${i}_reg
        cat ${_arg_output_dir}/jobs/${reg_type}_${i}_maskresample
        cat ${_arg_output_dir}/jobs/${reg_type}_${i}_maskaverage
      fi

      if [[ ${_arg_dry_run} == "off" ]]; then
        bash ${_arg_output_dir}/jobs/${reg_type}_${i}_reg
        bash ${_arg_output_dir}/jobs/${reg_type}_${i}_maskresample
        bash ${_arg_output_dir}/jobs/${reg_type}_${i}_maskaverage
      fi

      rm -f ${_arg_output_dir}/jobs/${reg_type}_${i}_shapeupdate && touch ${_arg_output_dir}/jobs/${reg_type}_${i}_shapeupdate

      if [[ ! -s ${_arg_output_dir}/${reg_type}/${i}/average/template_sharpen_shapeupdate.nii.gz ]]; then
        echo "#!/bin/bash" >  ${_arg_output_dir}/jobs/${reg_type}_${i}_shapeupdate
        echo "set -euo pipefail" >> ${_arg_output_dir}/jobs/${reg_type}_${i}_shapeupdate

        case ${_arg_average_type} in
          mean)
            echo AverageImages 3 ${_arg_output_dir}/${reg_type}/${i}/average/template.nii.gz \
              1 $(for j in "${!_arg_inputs[@]}"; do echo -n "${_arg_output_dir}/${reg_type}/${i}/resample/$(basename ${_arg_inputs[${j}]}) "; done) \
              >> ${_arg_output_dir}/jobs/${reg_type}_${i}_shapeupdate
            ;;
          normmean)
            echo AverageImages 3 ${_arg_output_dir}/${reg_type}/${i}/average/template.nii.gz \
              2 $(for j in "${!_arg_inputs[@]}"; do echo -n "${_arg_output_dir}/${reg_type}/${i}/resample/$(basename ${_arg_inputs[${j}]}) "; done) \
              >> ${_arg_output_dir}/jobs/${reg_type}_${i}_shapeupdate
            ;;
          median)
            for j in "${!_arg_inputs[@]}"; do echo -n "${_arg_output_dir}/${reg_type}/${i}/resample/$(basename ${_arg_inputs[${j}]}) "; done > ${_arg_output_dir}/medianlist.txt
            echo ImageSetStatistics 3 ${_arg_output_dir}/medianlist.txt ${_arg_output_dir}/${reg_type}/${i}/average/template.nii.gz 0 \
              >> ${_arg_output_dir}/jobs/${reg_type}_${i}_shapeupdate
            ;;
        esac

        case ${_arg_sharpen_type} in
          laplacian)
            echo ImageMath 3 ${_arg_output_dir}/${reg_type}/${i}/average/template_sharpen.nii.gz Sharpen ${_arg_output_dir}/${reg_type}/${i}/average/template.nii.gz \
              >> ${_arg_output_dir}/jobs/${reg_type}_${i}_shapeupdate
            ;;
          unsharp)
            echo ImageMath 3 ${_arg_output_dir}/${reg_type}/${i}/average/template_sharpen.nii.gz UnsharpMask ${_arg_output_dir}/${reg_type}/${i}/average/template.nii.gz 0.5 1 0 0 \
              >> ${_arg_output_dir}/jobs/${reg_type}_${i}_shapeupdate
            ;;
          none)
            echo cp -f ${_arg_output_dir}/${reg_type}/${i}/average/template.nii.gz ${_arg_output_dir}/${reg_type}/${i}/average/template_sharpen.nii.gz \
              >> ${_arg_output_dir}/jobs/${reg_type}_${i}_shapeupdate
            ;;
        esac

        echo ThresholdImage 3 ${_arg_output_dir}/${reg_type}/${i}/average/template_sharpen.nii.gz \
          ${_arg_output_dir}/${reg_type}/${i}/average/nonzero.nii.gz 1e-12 Inf 1 0 \
          >> ${_arg_output_dir}/jobs/${reg_type}_${i}_shapeupdate
        echo ImageMath 3 ${_arg_output_dir}/${reg_type}/${i}/average/template_sharpen.nii.gz m \
          ${_arg_output_dir}/${reg_type}/${i}/average/template_sharpen.nii.gz ${_arg_output_dir}/${reg_type}/${i}/average/nonzero.nii.gz \
          >> ${_arg_output_dir}/jobs/${reg_type}_${i}_shapeupdate


        echo ${AVERAGE_AFFINE_PROGRAM} 3 ${_arg_output_dir}/${reg_type}/${i}/average/affine.mat \
          $(for j in "${!_arg_inputs[@]}"; do echo -n "${_arg_output_dir}/${reg_type}/${i}/transforms/$(basename ${_arg_inputs[${j}]} | sed -r 's/(.nii$|.nii.gz$)//g')_0GenericAffine.mat "; done) \
          >> ${_arg_output_dir}/jobs/${reg_type}_${i}_shapeupdate

        if [[ ${reg_type} == "nlin" ]]; then
          echo AverageImages 3 ${_arg_output_dir}/${reg_type}/${i}/average/warp.nii.gz \
            0 $(for j in "${!_arg_inputs[@]}"; do echo -n "${_arg_output_dir}/${reg_type}/${i}/transforms/$(basename ${_arg_inputs[${j}]} | sed -r 's/(.nii$|.nii.gz$)//g')_1Warp.nii.gz "; done) \
            >> ${_arg_output_dir}/jobs/${reg_type}_${i}_shapeupdate
          echo ImageMath 3 ${_arg_output_dir}/${reg_type}/${i}/average/scaled_warp.nii.gz m ${_arg_output_dir}/${reg_type}/${i}/average/warp.nii.gz ${_arg_gradient_step} \
            >> ${_arg_output_dir}/jobs/${reg_type}_${i}_shapeupdate
          echo antsApplyTransforms -d 3 -e vector \
            -i ${_arg_output_dir}/${reg_type}/${i}/average/scaled_warp.nii.gz \
            -o ${_arg_output_dir}/${reg_type}/${i}/average/affine_scaled_warp.nii.gz \
            -t [ ${_arg_output_dir}/${reg_type}/${i}/average/affine.mat,1 ] \
            -r ${_arg_output_dir}/${reg_type}/${i}/average/template_sharpen.nii.gz \
            >> ${_arg_output_dir}/jobs/${reg_type}_${i}_shapeupdate
          echo antsApplyTransforms -d 3 -i ${_arg_output_dir}/${reg_type}/${i}/average/template_sharpen.nii.gz \
            -o ${_arg_output_dir}/${reg_type}/${i}/average/template_sharpen_shapeupdate.nii.gz \
            -n BSpline[5] \
            -t [ ${_arg_output_dir}/${reg_type}/${i}/average/affine.mat,1 ] \
            -t ${_arg_output_dir}/${reg_type}/${i}/average/affine_scaled_warp.nii.gz \
            -t ${_arg_output_dir}/${reg_type}/${i}/average/affine_scaled_warp.nii.gz \
            -t ${_arg_output_dir}/${reg_type}/${i}/average/affine_scaled_warp.nii.gz \
            -t ${_arg_output_dir}/${reg_type}/${i}/average/affine_scaled_warp.nii.gz \
            -r ${_arg_output_dir}/${reg_type}/${i}/average/template_sharpen.nii.gz \
            >> ${_arg_output_dir}/jobs/${reg_type}_${i}_shapeupdate
        else
          echo antsApplyTransforms -d 3 -i ${_arg_output_dir}/${reg_type}/${i}/average/template_sharpen.nii.gz \
            -o ${_arg_output_dir}/${reg_type}/${i}/average/template_sharpen_shapeupdate.nii.gz \
            -n BSpline[5] \
            -t [ ${_arg_output_dir}/${reg_type}/${i}/average/affine.mat,1 ] \
            -r ${_arg_output_dir}/${reg_type}/${i}/average/template_sharpen.nii.gz \
            >> ${_arg_output_dir}/jobs/${reg_type}_${i}_shapeupdate
        fi

        echo ThresholdImage 3 ${_arg_output_dir}/${reg_type}/${i}/average/template_sharpen_shapeupdate.nii.gz \
          ${_arg_output_dir}/${reg_type}/${i}/average/nonzero.nii.gz 1e-12 Inf 1 0 \
          >> ${_arg_output_dir}/jobs/${reg_type}_${i}_shapeupdate
        echo ImageMath 3 ${_arg_output_dir}/${reg_type}/${i}/average/template_sharpen_shapeupdate.nii.gz m \
          ${_arg_output_dir}/${reg_type}/${i}/average/template_sharpen_shapeupdate.nii.gz ${_arg_output_dir}/${reg_type}/${i}/average/nonzero.nii.gz \
          >> ${_arg_output_dir}/jobs/${reg_type}_${i}_shapeupdate


        if [[ ${_arg_dry_run} == "on" || ${_arg_debug} == "on" ]]; then
          cat ${_arg_output_dir}/jobs/${reg_type}_${i}_shapeupdate
        fi

        if [[ ${_arg_dry_run} == "off" ]]; then
          bash ${_arg_output_dir}/jobs/${reg_type}_${i}_shapeupdate
        fi

      fi

    fi

    target=${_arg_output_dir}/${reg_type}/${i}/average/template_sharpen_shapeupdate.nii.gz

    ((++i))
  done

done

# ] <-- needed because of Argbash
