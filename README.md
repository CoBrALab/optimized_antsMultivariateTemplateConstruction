# optimized_antsMultivariateTemplateConstruction

This pipeline is a re-implementation of the [ANTs](https://github.com/ANTsX/ANTs)
template construction pipeline (in particular, `antsMultivariateTemplateConstruction2.sh`).
The pipeline attempts to maintain the principles of template construction while
differing in some of the implementation mechanisms.

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
  - optimized registration scale pyramids based on image and voxel size
  - constrained linear transform path via rigid->similarity->affine path
  - stage repeats without/with masking
- Integration of masking during registration (if desired)
- Interpolation using `BSpline[5]` transforms where applicable
- Staged template construction using progressively higher-order transform types
(rigid, similarity, affine, nlin)
- (optional) affine transforms at later stages are bootstrapped from prior stages to reduce
computational load
- some defaults have been changed compared to `antsMultivariateTemplateConstruction2.sh`
  - affine transforms are averaged without rigid component
  - average sharpening defaults to UnsharpMask
  - computation defaults to double
- convergence for registration loosened to `1e-7`

## Requirements

This pipeline is primarity written in `bash`, and requires [ANTs](https://github.com/ANTsX/ANTs)
for the primary commands, `antsRegistration_affine_SyN.sh` and `ants_generate_iterations.py`
from [minc-toolkit-extras](https://github.com/CoBrALab/minc-toolkit-extras/) for the
optimized registration generation, and [qbatch](https://github.com/pipitone/qbatch)
for running commands locally or with cluster integration.

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

## Basic usage

Example help, always check `./modelbuild.sh --help` in case this document has not
been updated

```
A qbatch enabled, optimal registration pyramid based re-implementaiton of antsMultivariateTemplateConstruction2.sh
Usage: ./modelbuild.sh [-h|--help] [--output-dir <arg>] [--gradient-step <arg>] [--starting-target <arg>] [--starting-target-mask <arg>] [--(no-)com-initialize] [--starting-average-resolution <arg>] [--iterations <arg>] [--convergence <arg>] [--(no-)float] [--(no-)fast] [--average-type <AVERAGE>] [--(no-)rigid-update] [--sharpen-type <SHARPEN>] [--masks <arg>] [--(no-)mask-extract] [--stages <arg>] [--(no-)reuse-affines] [--walltime-short <arg>] [--walltime-linear <arg>] [--walltime-nonlinear <arg>] [--jobname-prefix <arg>] [--job-predepend <arg>] [--(no-)skip-file-checks] [--(no-)block] [--(no-)debug] [--(no-)dry-run] <inputs-1> [<inputs-2>] ... [<inputs-n>] ...
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
        --float, --no-float: Use float instead of double for calculations (reduce memory requirements) (off by default)
        --fast, --no-fast: Run SyN registration with Mattes instead of CC (off by default)
        --average-type: Type of averaging to apply during modelbuild. Can be one of: 'mean', 'median' and 'normmean' (default: 'normmean')
        --rigid-update, --no-rigid-update: Include rigid component of transform when performing shape update on template (disable if template drifts in translation or orientation) (off by default)
        --sharpen-type: Type of sharpening applied to average during modelbuild. Can be one of: 'none', 'laplacian' and 'unsharp' (default: 'unsharp')
        --masks: File containing mask filenames, one file per line (no default)
        --mask-extract, --no-mask-extract: Use masks to extract images before registration (off by default)
        --stages: Stages of modelbuild used (comma separated options: 'rigid' 'similarity' 'affine' 'nlin' 'nlin-only'), append a number in brackets 'rigid[n]' to override global iteration setting (default: 'rigid,similarity,affine,nlin')
        --reuse-affines, --no-reuse-affines: Reuse affines from previous stage/iteration to initialize next stage (off by default)
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
containing subject-wise modelbuild outputs.

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

Two-level DBM processing produces two types of outputs, `overall` DBM files,
which encode the entire voxel-wise difference between the original input scan and
the final second-level average, and `resampled-dbm` which encode the within-subject
change, with voxel-wise correspondence at the population level. The `resampled-dbm`
outputs are typically what is used for longitudinal analysis.

`dbm` directories are created within each `${output_dir}/firstlevel/subject_${N}` directory, as well as in the `${output_dir}/secondlevel` directory for the within-level computation of needed intermediates. DBM outputs intended for analysis at the second level are produced at `${output_dir}/secondlevel/{overall-dbm,resampled-dbm}/jacobian/{full,relative}/smooth` with naming according to the original input scans.

### Classical DBM

In classical DBM, rather than building an unbiased average, a direct registration is done to a target template
and the Jacobian determinants computed. This is achievable using these tools by limiting the model construction
to a single iteration and ignoring the average model in favour of the initial target.

```bash
$ ./modelbuild.sh --starting-target <MNI_model> --stages nlin[1] input.txt
$ ./dbm.sh input.txt
```

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
