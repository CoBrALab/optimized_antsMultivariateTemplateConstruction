# optimized_antsMultivariateTemplateConstruction

This pipeline is a re-implementation of the [ANTs](https://github.com/ANTsX/ANTs)
template construction pipeline (in particular, `antsMultivariateTemplateConstruction2.sh`).
The pipeline attempts to maintain the principles of template construction while
differing substantially in some of the implementation steps.

## How does this all work?

The ANTs unbiased model/template building method consists of the iterative application
of two major stages, the registration stage, and the template updating stage.

In the registration stage, all inputs are registered to a target, which is either
the initial target (first round) or the evolving template from the previous round.
After registration, each input is resampled into the target space.

In the template updating stage, several sub-steps happen.

1. The resampled inputs are voxel-wise averaged.
2. The resulting average has a sharpening filter applied.
3. The affine transforms from inputs to targets are averaged.
    - (If enabled) the average affine transform is scaled.
4. The (non-linear) transformations from inputs to target are averaged, pseudo-inverted, and scaled (multiplied by the negative of the gradient step value)
5. The resulting inverted average affine transform and pseudo-inverted-scaled average transform is applied to the sharpened average.

This new average is used as the target for the next round of registration and the process is repeated.

## Differences

### Changes made to pipeline flow which should not affect final outcome:

- File-presence based state tracking to allow for resume
- Logging of all commands run
- Integration of [qbatch](https://github.com/pipitone/qbatch) for local and cluster
parallelism
- complete computation of work graph before job submission
- nested directory hierarchy for organization of files
- no overwriting of intermediate files allowing for traceability of steps

### Changes which are expected to affect final outcome:

- Registration with [`antsRegistration_affine_SyN.sh`](https://github.com/CoBrALab/minc-toolkit-extras/blob/master/antsRegistration_affine_SyN.sh)
and driven by [`ants_generate_iterations.py`](https://github.com/CoBrALab/minc-toolkit-extras/blob/master/ants_generate_iterations.py)
  - Optimized registration scale pyramids based on image and voxel size
  - Constrained linear transform path via rigid->similarity->affine path
  - Stage repeats without/with masking
- (if enabled) Integration of masking during registration
- Interpolation using `BSpline[5]` transforms where applicable
- Staged template construction using progressively higher-order transform types
(rigid, similarity, affine, nlin)
- (optional) Affine transforms at later stages are bootstrapped from prior stages to reduce
computational load
- (if enabled) Affine transforms averaged using lie algebra instead of averaging matrix components
- (if enabled) Average affine transform scaled using gradient step
- Some defaults have been changed compared to `antsMultivariateTemplateConstruction2.sh`
  - Affine transforms are averaged without rigid component
  - Average sharpening defaults to UnsharpMask
  - Computation defaults to double
- convergence for registration loosened to `1e-7`

## Requirements

This pipeline is primarity written in `bash`, and requires [ANTs](https://github.com/ANTsX/ANTs)
for the primary commands, and [qbatch](https://github.com/pipitone/qbatch)
for running commands locally or with cluster integration.

A depdenency submodule of [minc-toolkit-extras](https://github.com/cobralab/minc-toolkit-extras)
is automatically included with appropriate versioning via a submodule.

(Optional) advanced averaging options are provided by a python scripts which require
[SimpleITK](https://simpleitk.org/), [NumPy](https://numpy.org/), [SciPy](https://scipy.org/)
and [VTK](https://pypi.org/project/vtk/)

## Missing features

The following are features missing compared to `antsMultivariateTemplateConstruction2.sh`

### Planned

- multispectral registration
  - modality weights
- change non-linear transform type
- metric control for all stages
- nonlinear parameter control

### Will not be implemented

- preprocessing
- 2D
- 4D

## Installation

Provided you have installed ANTs (via conda, binaries, or source), and qbatch (via pip)

```
$ git clone --recursive https://github.com/CoBrALab/optimized_antsMultivariateTemplateConstruction.git
```

You can add this directory to your `PATH` or refer to the scritps from any working directory, it will
properly find the rest of its dependent scripts.

## Basic usage

Example help, always check `./modelbuild.sh --help` in case this document has not
been updated

```bash
A qbatch enabled, optimal registration pyramid based re-implementaiton of antsMultivariateTemplateConstruction2.sh
Usage: ./modelbuild.sh [-h|--help] [--output-dir <arg>] [--gradient-step <arg>] [--starting-target <arg>] [--starting-target-mask <arg>] [--(no-)com-initialize] [--starting-average-resolution <arg>] [--iterations <arg>] [--convergence <arg>] [--syn-shrink-factors <arg>] [--syn-smoothing-sigmas <arg>] [--syn-convergence <arg>] [--syn-control <arg>] [--linear-shrink-factors <arg>] [--linear-smoothing-sigmas <arg>] [--linear-convergence <arg>] [--(no-)float] [--(no-)fast] [--average-type <AVERAGE>] [--average-prog <PROG>] [--(no-)average-norm] [--(no-)nlin-shape-update] [--(no-)affine-shape-update] [--(no-)scale-affines] [--(no-)rigid-update] [--sharpen-type <SHARPEN>] [--masks <arg>] [--(no-)mask-extract] [--mask-merge-threshold <arg>] [--stages <arg>] [--(no-)reuse-affines] [--final-target <arg>] [--final-target-mask <arg>] [--walltime-short <arg>] [--walltime-linear <arg>] [--walltime-nonlinear <arg>] [--jobname-prefix <arg>] [--job-predepend <arg>] [--(no-)skip-file-checks] [--(no-)block] [--(no-)debug] [--(no-)dry-run] <inputs-1> [<inputs-2>] ... [<inputs-n>] ...
        <inputs>: Input text file, one line per input
        -h, --help: Prints help
        --output-dir: Output directory for modelbuild (default: 'output')
        --gradient-step: Gradient scaling step during template warping, can be a comma separated list same length as number of iterations (default: '0.25')
        --starting-target: Initial image used to start modelbuild, defines orientation and voxel space, if 'none' an average of all subjects is constructed as a starting target (default: 'none')
        --starting-target-mask: Mask for starting target (no default)
        --com-initialize, --no-com-initialize: When a starting target is not provided, align all inputs using their center-of-mass before averaging (on by default)
        --starting-average-resolution: If no starting target is provided, an average is constructed from all inputs, resample average to a target resolution MxNxO before modelbuild (no default)
        --iterations: Number of iterations of model building per stage (default: '4')
        --convergence: Convergence limit during registration calls (default: '1e-7')
        --syn-shrink-factors: Shrink factors for Non-linear (SyN) stages, provide to override automatic generation, must be provided with sigmas and convergence (no default)
        --syn-smoothing-sigmas: Smoothing sigmas for Non-linear (SyN) stages, provide to override automatic generation, must be provided with shrinks and convergence (no default)
        --syn-convergence: Convergence levels for Non-linear (SyN) stages, provide to override automatic generation, must be provided with shrinks and sigmas (no default)
        --syn-control: Non-linear (SyN) gradient and regularization parameters, not checked for correctness (default: '0.1,3,0')
        --linear-shrink-factors: Shrink factors for linear stages, provide to override automatic generation, must be provided with sigmas and convergence (no default)
        --linear-smoothing-sigmas: Smoothing sigmas for linear stages, provide to override automatic generation, must be provided with shrinks and convergence (no default)
        --linear-convergence: Convergence levels for linear stages, provide to override automatic generation, must be provided with shrinks and sigmas (no default)
        --float, --no-float: Use float instead of double for calculations (reduce memory requirements) (off by default)
        --fast, --no-fast: Run SyN registration with Mattes instead of CC (off by default)
        --average-type: Type of averaging to apply during modelbuild. Can be one of: 'mean', 'median', 'trimmed_mean', 'efficient_trimean' and 'huber' (default: 'mean')
        --average-prog: Software to use for averaging images and transforms
                        python with SimpleITK needed for trimmed_mean, efficient_trimean, and huber. Can be one of: 'ANTs' and 'python' (default: 'ANTs')
        --average-norm, --no-average-norm: Normalize images by their mean before averaging (on by default)
        --nlin-shape-update, --no-nlin-shape-update: Perform nlin shape update, disable to switch to a forward-only modelbuild (on by default)
        --affine-shape-update, --no-affine-shape-update: Scale template by inverse of average affine transforms during shape update step (on by default)
        --scale-affines, --no-scale-affines: Apply gradient step scaling factor to average affine during shape update step, requires python with VTK and SimpleITK (off by default)
        --rigid-update, --no-rigid-update: Include rigid component of transform when performing shape update on template (disable if template drifts in translation or orientation) (off by default)
        --sharpen-type: Type of sharpening applied to average during modelbuild. Can be one of: 'none', 'laplacian' and 'unsharp' (default: 'unsharp')
        --masks: File containing mask filenames, one file per line (no default)
        --mask-extract, --no-mask-extract: Use masks to extract images before registration (off by default)
        --mask-merge-threshold: Threshold to combine masks during averaging (default: '0.5')
        --stages: Stages of modelbuild used (comma separated options: 'rigid' 'similarity' 'affine' 'nlin' 'nlin-only','volgenmodel-nlin'), append a number in brackets 'rigid[n]' to override global iteration setting (default: 'rigid,similarity,affine,nlin')
        --reuse-affines, --no-reuse-affines: Reuse affines from previous stage/iteration to initialize next stage (off by default)
        --final-target: Perform a final registration between the average and final target, used in postprocessing (default: 'none')
        --final-target-mask: Mask for the final target used in postprocessing (default: 'none')
        --walltime-short: Walltime for short running stages (averaging, resampling) (default: '00:30:00')
        --walltime-linear: Walltime for linear registration stages (default: '0:45:00')
        --walltime-nonlinear: Walltime for nonlinear registration stages (default: '4:30:00')
        --jobname-prefix: Prefix to add to front of job names, used by twolevel wrapper (no default)
        --job-predepend: Job name dependency pattern to prepend to all jobs, used by twolevel wrapper (no default)
        --skip-file-checks, --no-skip-file-checks: Skip preflight checking of existence of files, used by twolevel wrapper (off by default)
        --block, --no-block: For SGE, PBS and SLURM, blocks execution until jobs are finished. (off by default)
        --debug, --no-debug: Debug mode, print all commands to stdout (off by default)
        --dry-run, --no-dry-run: Dry run, don't run any commands, implies debug (off by default)
```

Minimal run command, assuming an input text file `inputs.txt` containing one line
per path to an input file

```bash
$ ./modelbuild.sh input.txt
```

### Outputs

The final output round of a `modelbuild.sh` run will be in `${output_dir}/final` which is linked to
the final stage output directory which was specified on the command line. See [Output directory structure](#output-directory-structure).

The final modelbuild average is `${output_dir}/final/average/template_sharpen_shapeupdate.nii.gz`

## Two-level wrapper

```
A wrapper to enable two-level modelbuild (aka longitudinal) modelling using optimized_antsMultivariateTemplateConstruction
Usage: ./twolevel_modelbuild.sh [-h|--help] [--output-dir <arg>] [--masks <arg>] [--(no-)debug] [--(no-)dry-run] <inputs> ...
        <inputs>: Input text files, one line per subject, comma separated scans per subject
        ... : Arguments to be passed to modelbuild.sh without validation
        -h, --help: Prints help
        --output-dir: Output directory for modelbuild (default: 'output')
        --masks: File containing mask filenames, identical to inputs in structure (no default)
        --debug, --no-debug: Debug mode, print all commands to stdout (off by default)
        --dry-run, --no-dry-run: Dry run, don't run any commands, implies debug (off by default)
```

`--output-dir` will contain a `firstlevel/` containing scan-wise `modelbuild.sh` outputs, and a `secondlevel/` directory,
containing subject-wise modelbuild outputs. See above for details.

## Deformation Based Morphometry (DBM) -- Model build must be completed first

Once a unbiased average model has been constructed, its possible to post-process the consensus deformation fields
to produce Jacobian determinants which encode the voxel-wise distance from each input scan to the consensus
average.

Post processing will generate `absolute` (including affine components) and `relative` (excluding affine components, and residual affines)
log Jacobian determinants (`voxel > 0`, voxel expands towards subject (i.e. subject voxel is larger), `voxel < 0`, voxel contracts towards subject (i.e. subject voxel is smaller)).

A minimal run command, assuming a complete run from `modelbuild.sh`, run using `input.txt`

```bash
$ ./dbm.sh input.txt
```

Complete run options

```
DBM post-processing for optimized_antsMultivariateTemplateConstruction
Usage: ./dbm.sh [-h|--help] [--output-dir <arg>] [--(no-)float] [--mask <arg>] [--delin-affine-ratio <arg>] [--(no-)use-geometric] [--jacobian-smooth <arg>] [--walltime <arg>] [--(no-)block] [--(no-)debug] [--(no-)dry-run] [--jobname-prefix <arg>] <inputs-1> [<inputs-2>] ... [<inputs-n>] ...
        <inputs>: Input text files, one line per input, one file per spectra
        -h, --help: Prints help
        --output-dir: Output directory for modelbuild (default: 'output')
        --float, --no-float: Use float instead of double for calculations (reduce memory requirements, reduce precision) (off by default)
        --mask: Mask file for average to improve delin estimates (no default)
        --delin-affine-ratio: Ratio of voxels within mask used to estimate delin affine (default: '0.25')
        --use-geometric, --no-use-geometric: Use geometric estimate of Jacobian instead of finite-difference (on by default)
        --jacobian-smooth: Comma separated list of smoothing gaussian FWHM, append "vox" for voxels, "mm" for millimeters (default: '4vox')
        --walltime: Walltime for short running stages (averaging, resampling) (default: '00:15:00')
        --block, --no-block: For qbatch SGE, PBS and SLURM, blocks execution until jobs are finished. (off by default)
        --debug, --no-debug: Debug mode, print all commands to stdout (off by default)
        --dry-run, --no-dry-run: Dry run, don't run any commands, implies debug (off by default)
        --jobname-prefix: Prefix to add to front of job names, used by twolevel wrapper (no default)
```

#### Outputs

Single level DBM outputs are found in `${output_dir}/dbm/jacobian/{full,relative}/smooth` named according to the input scan with a suffix of the smoothing option (`_fwhm_4vox` for example)

#### Classical DBM

In classical DBM, rather than building an unbiased average, a direct registration is done to a target template
and the Jacobian determinants computed. This is achievable using these tools by limiting the model construction
to a single iteration and ignoring the average model in favour of the initial target.

```bash
$ ./modelbuild.sh --starting-target <MNI_model> --stages nlin[1] input.txt
$ ./dbm.sh input.txt
```

### Two-level DBM wrapper

```
A wrapper to enable two-level (aka longitudinal) DBM using optimized_antsMultivariateTemplateConstruction
Usage: ./twolevel_dbm.sh [-h|--help] [--output-dir <arg>] [--jacobian-smooth <arg>] [--walltime <arg>] [--(no-)debug] [--(no-)dry-run] <inputs> ...
        <inputs>: Input text files, one line per subject, comma separated scans per subject
        ... : Arguments to be passed to modelbuild.sh without validation
        -h, --help: Prints help
        --output-dir: Output directory for modelbuild (default: 'output')
        --jacobian-smooth: Comma separated list of smoothing gaussian FWHM, append "vox" for voxels, "mm" for millimeters (default: '4vox')
        --walltime: Walltime for short running stages (averaging, resampling) (default: '00:15:00')
        --debug, --no-debug: Debug mode, print all commands to stdout (off by default)
        --dry-run, --no-dry-run: Dry run, don't run any commands, implies debug (off by default)
```

A minimal run command, assuming a complete run from `twolevel_modelbuild.sh`, run using `input.txt`

```bash
$ ./twolevel_dbm.sh input.txt
```

#### Outputs

Two-level DBM processing produces two types of outputs, `overall-dbm` files,
which encode the entire voxel-wise difference between the original input scan and
the final second-level average, and `resampled-dbm` which encode the within-subject
change, with voxel-wise correspondence at the population level. The `resampled-dbm`
outputs are typically what is used for longitudinal analysis as they contain
within-subject changes aligned at the population level.

`dbm` directories are created within each `${output_dir}/firstlevel/subject_${N}` directory, as well as in the `${output_dir}/secondlevel` directory for the within-level computation of needed intermediates. DBM outputs intended for analysis at the second level are produced at `${output_dir}/secondlevel/{overall-dbm,resampled-dbm}/jacobian/{full,relative}/smooth` with naming according to the original input scans.


## Output directory structure

```bash
output/
├── initialaverage
│   └── initialtarget.nii.gz # Generated if no starting target is supplied
├── jobs
│   └── <run date/time in ISO format>
│       ├── initialaverage
│       ├── rigid_{0,1,2,3}_maskaverage
│       ├── rigid_{0,1,2,3}_maskresample
│       ├── rigid_{0,1,2,3}_reg
│       ├── rigid_{0,1,2,3}_shapeupdate
│       ├── similarity_{0,1,2,3}_maskaverage
│       ├── similarity_{0,1,2,3}_maskresample
│       ├── similarity_{0,1,2,3}_reg
│       ├── similarity_{0,1,2,3}_shapeupdate
│       ├── affine_{0,1,2,3}_maskaverage
│       ├── affine_{0,1,2,3}_maskresample
│       ├── affine_{0,1,2,3}_reg
│       ├── affine_{0,1,2,3}_shapeupdate
│       ├── nlin_{0,1,2,3}_maskaverage
│       ├── nlin_{0,1,2,3}_maskresample
│       ├── nlin_{0,1,2,3}_reg
│       └── nlin_{0,1,2,3}_shapeupdate
├── dbm
│   ├── intermediate
│   │   ├── affine # jacobians from affine transforms
│   │   ├── delin # jacobians from residual affines
│   │   └── nlin # jacobians from nonlinear deformation fields
│   └── jacobian
│       ├── full
│       │   └── smooth # Final per-scan smoothed absolute jacobains
│       └── relative
│           └── smooth # Final per-scan smoothed relative jacobains
├── rigid
│   ├── {0,1,2,3}
│   │   ├── average
│   │   │   ├── template.nii.gz # Average of resampled files
│   │   │   ├── affine.mat # Average of affines
│   │   │   ├── template_sharpen.nii.gz # Template after sharpening
│   │   │   ├── nonzero.nii.gz # Nonzero mask to clip negative values from BSpline[5]
│   │   │   └── template_sharpen_shapeupdate.nii.gz # Template after shape update
│   │   ├── resample # One file per input, resampled into template space
│   │   │   └── masks # One mask file per input, resampled into template space
│   │   └── transforms # Affine transform files per input
├── similarity
│   ├── {0,1,2,3}
│   │   ├── average
│   │   │   ├── template.nii.gz
│   │   │   ├── affine.mat
│   │   │   ├── template_sharpen.nii.gz
│   │   │   ├── nonzero.nii.gz
│   │   │   └── template_sharpen_shapeupdate.nii.gz
│   │   ├── resample
│   │   │   └── masks
│   │   └── transforms
├── affine
│   ├── {0,1,2,3}
│   │   ├── average
│   │   │   ├── template.nii.gz
│   │   │   ├── affine.mat
│   │   │   ├── template_sharpen.nii.gz
│   │   │   ├── nonzero.nii.gz
│   │   │   └── template_sharpen_shapeupdate.nii.gz
│   │   ├── resample
│   │   │   └── masks
│   │   └── transforms
└── nlin
    └── {0,1,2,3}
        ├── average
        │   ├── template.nii.gz
        │   ├── affine.mat
        │   ├── template_sharpen.nii.gz
        │   ├── warp.nii.gz # Average of warp fields
        │   ├── scaled_warp.nii.gz # Scaled/pseudoinverted average warp
        │   ├── affine_scaled_warp.nii.gz # Warp transformed with inverse affine
        │   ├── nonzero.nii.gz
        │   └── template_sharpen_shapeupdate.nii.gz
        ├── resample
        │   └── masks
        └── transforms # Affine and warp transform files per input
```
