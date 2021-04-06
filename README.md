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
