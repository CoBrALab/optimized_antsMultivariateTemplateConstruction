# optimized_antsMultivariateTemplateConstruction
This pipeline is a re-implementation of the [ANTs](https://github.com/ANTsX/ANTs)
template construction pipeline (in particular, `antsMultivariateTemplateConstruction2.sh`).
The pipeline attempts to maintain the principles of template construction while
differing in some of the implementation mechanisms.

## Differences

Changes made to pipeline flow which should not affect final outcome:
- File-presence based state tracking to allow for resume
- Logging of all commands run
- Integration of [qbatch](https://github.com/pipitone/qbatch) for local and cluster
parallelism
- complete computation of work graph before job submission
- nested directory hierarchy for organization of files
- no overwriting of intermediate files allowing for tracibility of steps

Changes which are expected to affect final outcome:
- Registration with [`antsRegistration_affine_SyN.sh`](https://github.com/CoBrALab/minc-toolkit-extras/blob/master/antsRegistration_affine_SyN.sh)
and driven by [`ants_generate_iterations.py`](https://github.com/CoBrALab/minc-toolkit-extras/blob/master/ants_generate_iterations.py)
  - optimized registration scale pyramids based on image and voxel size
  - constrained linear transform path via rigid->similarity->affine path
  - stage repeats without/with masking
- Integration of masking during registration (if desired)
- Interpolation using `BSpline[5]` transforms where applicable
- Staged template construction using progressively higher-order transform types
(rigid, similarity, affine, nlin)
- affine transforms at later stages are bootstrapped from prior stages to reduce
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
some of which will be added on a interest basis:
- multispectral registration
  - modality weights
- change non-linear transform type
- metric control for all stages
- nonlinear parameter control
- preprocessing (will not be implemented)
- 2D (will not be implemented)
- 4D (will not be implemented)

## Basic usage

Example help, always check `./modelbuild.sh --help` in case this document has not
been updated
```bash
$ ./modelbuild.sh --help
A qbatch and optimal registration pyramid based re-implementaiton of antsMultivariateTemplateConstruction2.sh
Usage: ./modelbuild.sh [-h|--help] [--output-dir <arg>] [--gradient-step <arg>] [--starting-target <arg>] [--starting-target-mask <arg>] [--iterations <arg>] [--convergence <arg>] [--(no-)float] [--(no-)fast] [--average-type <AVERAGE>] [--(no-)average-norm] [--(no-)rigid-update] [--sharpen-type <SHARPEN>] [--masks <arg>] [--(no-)mask-extract] [--stages <arg>] [--walltime-short <arg>] [--walltime-linear <arg>] [--walltime-nonlinear <arg>] [--(no-)block] [--(no-)debug] [--(no-)dry-run] <inputs-1> [<inputs-2>] ... [<inputs-n>] ...
      	<inputs>: Input text files, one line per input, one file per spectra
      	-h, --help: Prints help
      	--output-dir: Output directory for modelbuild (default: 'output')
      	--gradient-step: Gradient scaling step during template warping (default: '0.25')
      	--starting-target: Initial image used to start modelbuild, defines orientation and voxel space, if 'none' an average all subjects is constructed as a starting target (default: 'none')
      	--starting-target-mask: Mask for starting target (no default)
      	--iterations: Number of iterations of model building per stage (default: '4')
      	--convergence: Convergence limit during registration calls (default: '1e-7')
      	--float, --no-float: Use float instead of double for calculations (reduce memory requirements) (off by default)
      	--fast, --no-fast: Run SyN registration with Mattes instead of CC (off by default)
      	--average-type: Type of averaging to apply during modelbuild. Can be one of: 'mean', 'median', 'trimmed_mean' and 'huber' (default: 'mean')
      	--average-norm, --no-average-norm: Whether to normalize each image by their mean before evaluating average. (off by default)
      	--rigid-update, --no-rigid-update: Include rigid component of transform when performing shape update on template (disable if template drifts in translation or orientation) (off by default)
      	--sharpen-type: Type of sharpening applied to average during modelbuild. Can be one of: 'none', 'laplacian' and 'unsharp' (default: 'unsharp')
      	--masks: File containing mask filenames, one file per line (no default)
      	--mask-extract, --no-mask-extract: Use masks to extract images before registration (off by default)
      	--stages: Stages of modelbuild used (comma separated options: 'rigid' 'similarity' 'affine' 'nlin' 'nlin-only') (default: 'rigid,similarity,affine,nlin')
      	--walltime-short: Walltime for short running stages (averaging, resampling) (default: '00:15:00')
      	--walltime-linear: Walltime for linear registration stages (default: '0:30:00')
      	--walltime-nonlinear: Walltime for nonlinear registration stages (default: '2:30:00')
      	--block, --no-block: For SGE, PBS and SLURM, blocks execution until jobs are finished. (off by default)
      	--debug, --no-debug: Debug mode, print all commands to stdout (off by default)
      	--dry-run, --no-dry-run: Dry run, don't run any commands, implies debug (off by default)
```

Minimal run command, assuming an input text file `inputs.txt` containing one line
per path to an input file
```
$ ./modelbuild.sh input.txt
```

## Output directory structure
```bash
output/
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
│       ├── nlin_{0,1,2,3}_shapeupdate
├── rigid
│   ├── {0,1,2,3}
│   │   ├── average
│   │       ├── template.nii.gz # Average of resampled files
│   │       ├── affine.mat # Average of affines
│   │       ├── template_sharpen.nii.gz # Template after sharpening
│   │       ├── nonzero.nii.gz # Nonzero mask to clip negative values from BSpline[5]
│   │       └── template_sharpen_shapeupdate.nii.gz # Template after shape update
│   │   ├── resample # One file per input, resampled into template space
│   │   │   └── masks # One mask file per input, resampled into template space
│   │   └── transforms # Affine transform files per input
├── similarity
│   ├── {0,1,2,3}
│   │   ├── average
│   │       ├── template.nii.gz
│   │       ├── affine.mat
│   │       ├── template_sharpen.nii.gz
│   │       ├── nonzero.nii.gz
│   │       └── template_sharpen_shapeupdate.nii.gz
│   │   ├── resample
│   │   │   └── masks
│   │   └── transforms
├── affine
│   ├── {0,1,2,3}
│   │   ├── average
│   │       ├── template.nii.gz
│   │       ├── affine.mat
│   │       ├── template_sharpen.nii.gz
│   │       ├── nonzero.nii.gz
│   │       └── template_sharpen_shapeupdate.nii.gz
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
