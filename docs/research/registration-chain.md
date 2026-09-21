# Registration Chain in pydpiper: how it connects scans

Research for [#139](https://github.com/CoBrALab/optimized_antsMultivariateTemplateConstruction/issues/139) (part of map [#138](https://github.com/CoBrALab/optimized_antsMultivariateTemplateConstruction/issues/138)).

**Question.** How does pydpiper's `registration_chain.py` connect scans? Describe it precisely enough to re-implement it with ANTs.

## Sources

- **pydpiper source code**, pinned at commit [`04db1087f685dc54ec43253bb030efc438a2bbd8`](https://github.com/Mouse-Imaging-Centre/pydpiper/tree/04db1087f685dc54ec43253bb030efc438a2bbd8) (HEAD of the default branch, 2022-09-29). All line citations refer to this commit. This is the primary source.
- **MISS 2017 longitudinal registration slides** ([PDF](https://mouse-imaging-centre.github.io/summer_school2017/longitudinal_slides/MISS_Longitudinal_Registration.pdf)), by the pydpiper authors' group. Used only for vocabulary and for one claim that the code contradicts (see [Missing timepoints](#6-missing-timepoints)).
- **MICe wiki** (`https://wiki.mouseimaging.ca/display/MICePub/Longitudinal+Registration+Tools`). Not reachable: the DNS lookup for `wiki.mouseimaging.ca` fails, and the Wayback Machine has no snapshot. No claim in this document comes from the wiki.

Citation shorthand (all links go to the pinned commit):

| Short name | File |
|---|---|
| `rc.py` | `pydpiper/pipelines/registration_chain.py` |
| `reg.py` | `pydpiper/minc/registration.py` |
| `analysis.py` | `pydpiper/minc/analysis.py` |
| `arguments.py` | `pydpiper/core/arguments.py` |
| `strategies.py` | `pydpiper/minc/registration_strategies.py` |
| `ANTS.py` | `pydpiper/minc/ANTS.py` |
| `antsRegistration.py` | `pydpiper/minc/antsRegistration.py` |

## Vocabulary

This document uses the terms in `CONTEXT.md`:

- **Template**: the unbiased average image from iterative registration and averaging. pydpiper calls it a "model", "average" or "consensus average". This document uses those words only in quotes.
- **Longitudinal strategy**: the topology that connects scans across subjects and timepoints. Here: Registration Chain.
- **Level 1 / Level 2**: the first and second stage of a strategy. For the Registration Chain, Level 1 is the within-subject chain of sequential scans. Level 2 is the between-subject template of the common-timepoint scans. The MISS slides use the same split ([slides p. 10](https://mouse-imaging-centre.github.io/summer_school2017/longitudinal_slides/MISS_Longitudinal_Registration.pdf#page=10)).

**Transform direction convention.** This document describes every transform as a *point map*. "A→B" means: the transform takes a point in the space of A to the corresponding point in the space of B. A MINC `.xfm` from `source` to `target` is the point map source→target. `mincresample -transform source_to_target.xfm -like target source` pulls `source` into the space of `target`.

## Answer in brief

1. The input is a CSV with columns `subject_id`, `timepoint` (integer), `filename`, and an optional `is_common`. Extra columns are ignored.
2. Level 0 (preprocessing): pydpiper rigidly aligns (6 parameters) each scan, one at a time, to an initial model. With `--pride-of-models`, each scan goes to the model with the nearest timepoint. The chain then works on these rigidly resampled images.
3. Level 1: for each subject, pydpiper sorts the available scans by `timepoint`. It registers each scan to the next scan (earlier = source, later = target). Each link is a 12-parameter affine (minctracc) followed by a nonlinear registration (legacy `ANTS` SyN by default). The link is not symmetric. There is no intermediate or subject-specific template.
4. Level 2: pydpiper builds a template from the one "common timepoint" scan of each subject. It uses pairwise 12-parameter affine registration plus iterative nonlinear registration to the average. Scans at other timepoints do not contribute to any template.
5. Composition: to reach the Level 2 template from scan `t_k`, pydpiper concatenates the chain links from `t_k` to the subject's common-timepoint scan, then the Level 2 transform. Links after the common timepoint are used inverted. Links before it are used forward.
6. Determinants: pydpiper computes log-Jacobians of the inverted composites. "First level" = scan relative to its own common-timepoint scan, resampled to the template. "Second level" = scan relative to the template, through the whole composite. Each has an absolute (affine + nonlinear) and a relative (nonlinear only) version.
7. Missing timepoints: the code keeps the subject and registers across the gap. No interpolation occurs. Only a missing *common* timepoint is an error, and that error stops the whole pipeline. This contradicts the MISS slides, which say the subject is ignored.

The sections below give the detail and the citations.

## 1. Input CSV

- The CSV must have the columns `subject_id`, `timepoint` and `filename` ([rc.py L651-678](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L651-L678)). pydpiper reads it with `csv.DictReader`. It strips the values, but not the header names.
- `timepoint` is parsed with `int()` ([rc.py L671](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L671)). A value such as `18.5` raises an error. Two TODO comments ask for fractional timepoints ([rc.py L60-61](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L60-L61), [L85](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L85)).
- `timepoint` is a label, not an index. pydpiper uses it only to sort each subject's scans ([rc.py L131](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L131)) and to pick a pride model by distance ([rc.py L538-578](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L538-L578)). The test suite uses the values 23, 35 and 65 ([test/test_cli.py L39](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/test/test_cli.py#L39), [L55-66](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/test/test_cli.py#L55-L66)). The time interval between scans has no effect on the registration.
- `is_common` is optional. It marks the scan of that subject to use for Level 2. Accepted true values: `1`, `True`, `true`, `T`, `t`. Accepted false values: empty, `0`, `False`, `false`, `F`, `f`. Any other value is an error ([rc.py L628-643](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L628-L643)). A subject can have at most one true value ([rc.py L679-685](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L679-L685)).
- Other columns are ignored. The doctest has a `genotype` column ([rc.py L659-662](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L659-L662)).
- Two rows with the same `subject_id` and `timepoint` do not cause an error. The last row replaces the earlier one ([rc.py L678](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L678)).
- All file basenames must be unique across the CSV, because pydpiper makes one output directory per basename ([reg.py L2133-2145](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/registration.py#L2133-L2145)).
- The CSV is given with `--chain-csv-file` ([arguments.py L603-611](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/core/arguments.py#L603-L611)). The `chain` prefix comes from the parser annotation ([rc.py L847](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L847), [arguments.py L126-142](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/core/arguments.py#L126-L142)). The test suite confirms the full flag names ([test/test_cli.py L261-264](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/test/test_cli.py#L261-L264)).

## 2. `--chain-common-time-point`

The common timepoint selects, for each subject, the one scan that goes into Level 2. The flag takes an integer; the default is `None` ([arguments.py L612-619](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/core/arguments.py#L612-L619)). pydpiper resolves it per subject in this order ([rc.py L690-714](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L690-L714)):

1. If the subject has `is_common` set, use that scan. If the flag gives a different value, print a note and use `is_common`.
2. Else, if the flag is not given, stop with `TimePointError`.
3. Else, if the subject has a scan at that timepoint, use it.
4. Else, if the value is `-1`, use the subject's last (largest) timepoint.
5. Else, stop with `TimePointError`. This error stops the whole pipeline, not only the subject.

Consequences:

- The common timepoint can differ between subjects (through `is_common` or `-1`). The Level 2 template can then mix ages.
- `--chain-common-time-point-name` (default `common`) changes only directory names ([arguments.py L620-625](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/core/arguments.py#L620-L625), [rc.py L176-177](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L176-L177)).

## 3. Level 0: rigid alignment and `--pride-of-models`

Before the chain, pydpiper aligns every scan rigidly and resamples it. This step runs only with `--input-space native`, which is the default ([arguments.py L422-426](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/core/arguments.py#L422-L426), [rc.py L212-255](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L212-L255)).

- pydpiper calls `lsq6_nuc_inorm` once per scan, with a list of one image ([rc.py L243-255](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L243-L255)). No average is made.
- The target is the native-space file of the initial model if it exists, else the standard-space file ([reg.py L2440](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/registration.py#L2440)). The default method is `lsq6_large_rotations`, a brute-force rotation search ([arguments.py L455](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/core/arguments.py#L455), [L517-522](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/core/arguments.py#L517-L522)).
- Non-uniformity correction and intensity normalisation are on by default. They run in native space. Then pydpiper resamples the result into the standard space of the model, with sinc interpolation ([reg.py L2470-2536](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/registration.py#L2470-L2536), [arguments.py L456-457](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/core/arguments.py#L456-L457)).
- The Level 1 chain and the Level 2 template use these rigidly resampled images ([rc.py L300-308](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L300-L308), [L401-407](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L401-L407)). Thus the rigid transform is **not** part of any concatenated transform or determinant.
- `--bootstrap` is not allowed for the chain ([rc.py L213-216](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L213-L216)). Exactly one of `--init-model`, `--lsq6-target`, `--pride-of-models` must be given ([reg.py L2674-2697](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/registration.py#L2674-L2697)).
- With `--input-space lsq6`, pydpiper skips Level 0. With `--input-space lsq12`, it skips Level 0 and the Level 2 affine step ([rc.py L298-301](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L298-L301), [L339-352](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L339-L352)). In both cases, all inputs must have the same grid ([rc.py L195-206](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L195-L206)). The Level 1 links still include their affine step.

### `--pride-of-models`

A pride of models is a set of initial models, one per age. It exists for data with large size differences between timepoints ([pydpiper NEWS L235](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/NEWS#L235)).

- The flag takes a CSV with the columns `model_file` and `time_point` ([arguments.py L484-492](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/core/arguments.py#L484-L492), [reg.py L2791-2803](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/registration.py#L2791-L2803)). `time_point` can be an integer or a float; pydpiper stores it as a float ([reg.py L2808-2830](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/registration.py#L2808-L2830)).
- All models must have the same resolution ([reg.py L2817-2825](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/registration.py#L2817-L2825)). Each model needs `<name>_mask.mnc`. It can also have `<name>_native.mnc`, `<name>_native_mask.mnc` and `<name>_native_to_standard.xfm` ([reg.py L2591-2653](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/registration.py#L2591-L2653)).
- For each scan, pydpiper picks the model with the nearest `time_point` ([rc.py L217-233](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L217-L233), [L538-578](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L538-L578)):
  - An exact match wins.
  - If the scan is before the first model, the first model is used.
  - On a tie, the later (larger) model is used (`>=` at [rc.py L571](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L571)).
  - If the scan is after the last model, `bisect` returns `len(keys)` and the lookup at [rc.py L569](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L569) raises `IndexError`. This looks like a bug. The intended behaviour is probably "use the last model".
- The pride of models changes **only** the Level 0 target (and the mask for non-uniformity correction and normalisation). Each scan is resampled into the standard space of *its* model ([reg.py L2508-2514](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/registration.py#L2508-L2514)). Level 1 and Level 2 do not use the pride.
- pydpiper does not check that the models share one coordinate space. If they do not, the Level 1 affine step must absorb the offset between models.

## 4. Level 1: sequential within-subject registration

### Topology

For each subject, pydpiper sorts the scans by `timepoint`. It registers each adjacent pair, `t_n` to `t_(n+1)` ([rc.py L109-148](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L109-L148)). `pairs(lst)` is `zip(lst[:-1], lst[1:])` ([pydpiper/core/util.py L69-70](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/core/util.py#L69-L70)). A subject with `N` scans gives `N - 1` links. A subject with one scan gives no link.

```
subject A:  A_t1 --L1--> A_t2 --L2--> A_t3        (L_n: point map t_n -> t_(n+1))
subject B:  B_t1 --L1--> B_t2 --L2--> B_t3
                          |
                  Level 2 template of {A_t2, B_t2, ...}   (common timepoint = t2)
```

### Direction and symmetry

- `source` = the earlier scan `t_n`. `target` = the later scan `t_(n+1)` ([rc.py L137-147](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L137-L147)). The stored link is the point map `t_n -> t_(n+1)`. The resampled output is `t_n` in the space of `t_(n+1)` ([rc.py L439](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L439)).
- In ANTs terms, pydpiper's `source` is the **fixed** image and `target` is the **moving** image. Evidence: the legacy `ANTS` metric is `CC[source,target,...]`, which is `CC[fixed,moving,...]` ([ANTS.py L205-208](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/ANTS.py#L205-L208)). The mask is the source mask (`-x`, [pydpiper/templates/ANTS.sh L9](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/templates/ANTS.sh#L9)). The `antsRegistration` wrapper says so in its docstring ([antsRegistration.py L192-195](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/antsRegistration.py#L192-L195), [L271-282](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/antsRegistration.py#L271-L282)). So the nonlinear field of link `L_n` lives on the grid of the earlier scan `t_n`.
- The link is **not symmetric**. pydpiper runs one registration per pair, in one direction. It gets the reverse direction by inversion (`invert_xfmhandler`, [reg.py L1015-1045](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/registration.py#L1015-L1045)). For the default `ANTS` method, this is `xfminvert`, which only flags the MINC transform as inverted ([pydpiper/templates/xfminvert.sh](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/templates/xfminvert.sh)).
- There is **no intermediate template**. There is no midpoint and no subject-specific template. pydpiper has a midpoint routine (`nonlinear_midpoint_xfm`, [strategies.py L67-127](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/registration_strategies.py#L67-L127)), but only the `tournament` strategy uses it. The chain does not.

### Transform types in one link

`intrasubject_registrations` calls `lsq12_nlin` ([rc.py L139-146](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L139-L146), [reg.py L1620-1699](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/registration.py#L1620-L1699)). A link is:

1. **12-parameter affine** with minctracc. The configuration is hard-coded: `default_lsq12_multilevel_minctracc` ([rc.py L424](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L424), with a TODO at L425). It has three levels: step 0.9 / 0.46 / 0.3 mm, blur 0.28 / 0.19 / 0.14 mm, cross-correlation, with masks ([reg.py L1752-1783](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/registration.py#L1752-L1783)). These are absolute millimetre values for mouse brain. `--lsq12-protocol` does **not** change this step. It changes only Level 2.
2. **Nonlinear** registration with the method from `--registration-method`. The default is `ANTS` (the legacy `ANTS` binary) ([arguments.py L684-689](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/core/arguments.py#L684-L689), [rc.py L317](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L317), [reg.py L1396-1426](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/registration.py#L1396-L1426)).
   - Default single-run `ANTS` settings: `SyN[0.1]`, `Gauss[2,1]`, `100x100x100x150`, two metrics (CC radius 3 on intensities and CC radius 3 on blurred gradient images), source mask, no affine iterations ([ANTS.py L33-59](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/ANTS.py#L33-L59), [L120-121](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/ANTS.py#L120-L121), [ANTS.sh L1-9](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/templates/ANTS.sh#L1-L9)).
   - If `--nlin-protocol` is given, the link uses **only the first generation** of that protocol and prints "warning, too many confs" ([rc.py L428](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L428), [reg.py L1650-1651](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/registration.py#L1650-L1651), [ANTS.py L282-288](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/ANTS.py#L282-L288)). The same protocol drives all generations of Level 2. In the usual protocol shape, the first generation is the coarsest.
   - With `--registration-method antsRegistration`, the default is `SyN[0.5,3,0]` with 6 levels (`16x8x6x4x2x1`) ([antsRegistration.py L165-177](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/antsRegistration.py#L165-L177), [L389-395](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/antsRegistration.py#L389-L395)). Protocol files are "not implemented" for this method ([antsRegistration.py L419-427](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/antsRegistration.py#L419-L427)).
3. **Concatenation.** Legacy `ANTS` does not accept an initial transform ([ANTS.py L131](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/ANTS.py#L131)). So pydpiper resamples the source with the affine, runs `ANTS` on the result, and concatenates affine then nonlinear into one `.xfm` ([reg.py L1684-1698](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/registration.py#L1684-L1698)). For methods that accept an initial transform, the affine goes in as the initial transform ([reg.py L1670-1683](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/registration.py#L1670-L1683)).

## 5. Level 2: template of the common-timepoint scans

- The inputs are the rigidly resampled common-timepoint scans, one per subject ([rc.py L298-308](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L298-L308)). The MISS slides describe the same thing ([slides p. 10](https://mouse-imaging-centre.github.io/summer_school2017/longitudinal_slides/MISS_Longitudinal_Registration.pdf#page=10)).
- pydpiper calls `lsq12_nlin_build_model` with the prefix `common` ([rc.py L328-337](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L328-L337), [reg.py L2030-2100](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/registration.py#L2030-L2100)). This is the generic pydpiper model-building function (pairwise affine, then iterative nonlinear):
  1. **Pairwise 12-parameter affine.** Each scan is registered to up to `--lsq12-max-pairs` scans (default 25, [arguments.py L646-649](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/core/arguments.py#L646-L649)). If the number of scans is not more than the limit, the set is all scans, including the scan itself. With more scans than the limit, the set is a seeded random sample, and it includes the scan itself only by chance ([reg.py L1861-1870](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/registration.py#L1861-L1870), seed at [L34](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/registration.py#L34)). pydpiper averages the transforms with `xfmaverage`, resamples each scan, and averages the images ([reg.py L1880-1919](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/registration.py#L1880-L1919), [L1872-1873](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/registration.py#L1872-L1873)). The comment at [reg.py L1887-1903](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/registration.py#L1887-L1903) explains why the self-registration is included.
  2. **Iterative nonlinear** (`build_model` strategy, the default, [arguments.py L691-694](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/core/arguments.py#L691-L694)). For each generation, pydpiper registers every affine-resampled scan (source) to the current average (target). Then it averages the resampled scans into `common-nlin-<i>.mnc` ([strategies.py L19-59](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/registration_strategies.py#L19-L59)). `ANTS` has 3 default generations (`100x100x100x0`, `...x20`, `...x100`, [ANTS.py L78-92](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/ANTS.py#L78-L92)). `antsRegistration` has 4 ([antsRegistration.py L397-408](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/antsRegistration.py#L397-L408)). There is **no shape-update step** and no sharpening, unlike `modelbuild.sh`.
  3. **Per-subject transform** = concatenation of the averaged affine and the last-generation nonlinear transform ([reg.py L2092-2096](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/registration.py#L2092-L2096)). This is the point map `subject common scan -> template`. Note: its target is the average used in the last generation (`common-nlin-(N-1)`), while the reported template is `common-nlin-N`. Both have the same grid.
- In this repository, the equivalent of Level 2 is `modelbuild.sh` on the list of common-timepoint scans.

## 6. Missing timepoints

- **The code keeps the subject.** It chains whatever scans exist, in sorted order ([rc.py L131-147](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L131-L147)). If `t2` is missing, the link goes directly from `t1` to `t3`. There is no interpolation. There is no check that the design is balanced. Subjects can have different numbers of scans and different timepoints.
- **A missing common timepoint is an error for the whole run**, unless `is_common` or `-1` gives that subject another scan ([rc.py L700-710](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L700-L710)).
- **Conflict with the slides.** The MISS slides say "If subject is missing a single timepoint, subject is ignored" ([slides p. 22](https://mouse-imaging-centre.github.io/summer_school2017/longitudinal_slides/MISS_Longitudinal_Registration.pdf#page=22)) and "Requires a balanced design" ([slides p. 11](https://mouse-imaging-centre.github.io/summer_school2017/longitudinal_slides/MISS_Longitudinal_Registration.pdf#page=11)). The code at the pinned commit does neither. The slides may describe a recommendation, not the code.

## 7. Transform composition to the common space

Notation for subject `s` with sorted scans `t_1 .. t_N` and common scan `t_c`:

- `L_n`: Level 1 link, point map `t_n -> t_(n+1)`.
- `G`: Level 2 transform, point map `t_c -> template`.

`get_chain_transforms_for_stats` builds two transforms for each scan `t_k` ([rc.py L719-831](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L719-L831)). `xfmconcat` lists transforms in the order it applies them to a point ([pydpiper/templates/xfmconcat.sh](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/templates/xfmconcat.sh), [reg.py L750-814](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/registration.py#L750-L814)).

| Scan | To subject common scan (`Y_k`) | To template (`X_k`) | Source |
|---|---|---|---|
| `k = c` | none (identity; not computed) | `G` | [rc.py L760-773](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L760-L773) |
| `k > c` | `inv(L_(k-1)), ..., inv(L_c)` | `inv(L_(k-1)), ..., inv(L_c), G` | [rc.py L783-795](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L783-L795) |
| `k < c` | `L_k, ..., L_(c-1)` | `L_k, ..., L_(c-1), G` | [rc.py L804-822](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L804-L822) |

- The composition is **asymmetric about `t_c`**. Links after the common timepoint are used inverted. Links before it are used forward. The guard at [rc.py L811](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L811) prevents a Python negative-index wrap when `t_c` is the first scan.
- Each step is a concatenation of `.xfm` files, not a resampled field. File names are `id_<subject>_pt_<tp>_to_common_avg.xfm` and `id_<subject>_pt_<tp>_to_common_subject.xfm` ([rc.py L785](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L785), [L794](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L794)).
- The MISS slides give the same path for a cross-subject map: subject 1 P23.5 → subject 1 P42 → template → subject 3 P42 → subject 3 P23.5 → subject 3 P14 ([slides p. 20](https://mouse-imaging-centre.github.io/summer_school2017/longitudinal_slides/MISS_Longitudinal_Registration.pdf#page=20)).

### ANTs translation of the composition (derived, not from pydpiper)

`antsApplyTransforms` lists transforms from the reference (`-r`) space outward. `xfmconcat` lists them from the source scan outward. So the order reverses, and each element becomes the opposite point map. This repository already uses the `antsApplyTransforms` order in `twolevel_dbm.sh` (the `final-target` branch lists the transform nearest the reference first).

Suppose each link runs `antsRegistration` with fixed = `t_n` and moving = `t_(n+1)`, as pydpiper does. The forward output (`Warp`, `Affine`) is then the point map `t_n -> t_(n+1)`. The inverse output (`[Affine,1]`, `InverseWarp`) is `t_(n+1) -> t_n`. Suppose Level 2 is `modelbuild.sh`, where the template is fixed. Its forward output is `template -> t_c`. To pull scan `t_k` into template space:

- `k < c`: `-r template -t G_1Warp -t G_0GenericAffine -t [L_(c-1)_Affine,1] -t L_(c-1)_InverseWarp ... -t [L_k_Affine,1] -t L_k_InverseWarp`
- `k > c`: `-r template -t G_1Warp -t G_0GenericAffine -t L_c_Warp -t L_c_Affine ... -t L_(k-1)_Warp -t L_(k-1)_Affine`

A composite field for determinants comes from the same list with `-o [field.nii.gz,1]` (as in `dbm.sh`).

## 8. Determinants (Level 1 and Level 2)

The code comment lists three quantities ([rc.py L456-459](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L456-L459)). pydpiper computes only the first two:

1. **Level 1 ("first level")**: scan relative to its own common-timepoint scan. pydpiper takes the determinant of `inv(Y_k)` (point map `t_c -> t_k`) ([rc.py L470-474](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L470-L474)). `minc_displacement` samples the field on the grid of the transform's source ([reg.py L319-327](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/registration.py#L319-L327)). Here that is the grid of `t_c`. Then pydpiper resamples each log-determinant into template space with `G`, as a plain scalar image ([rc.py L503-517](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L503-L517)). The output suffix is `_resampled_to_common`. The `like` file is the determinant itself, so the output keeps the Level 0 grid. The common scan has no Level 1 determinant.
2. **Level 2 ("second level")**: scan relative to the template, through the full composite. pydpiper takes the determinant of `inv(X_k)` (point map `template -> t_k`), on the template grid ([rc.py L521-525](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L521-L525)). This includes the common scan (`X_c = G`).
3. **Not produced**: determinants of each link `t_n <- t_(n+1)`. The link transforms exist on disk, but pydpiper computes no determinant from them.

**Naming trap.** pydpiper's "second level" determinant is the *whole* path (within-subject plus between-subject). It is not the between-subject part only. The between-subject part alone (`G`) is only the second-level value of the common scan.

**Sign.** The field is the map template → scan, sampled in template space. This is the same sense as `dbm.sh` in this repository: a value above 1 (log above 0) means the scan is larger there than the reference.

**Absolute and relative.** `determinants_at_fwhms` ([analysis.py L142-193](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/analysis.py#L142-L193)) gives two versions:

- `_abs`: determinant of the full displacement (affine + nonlinear). The rigid part is absent because of Level 0.
- `_rel`: determinant of the nonlinear part only. `nlin_part` concatenates the transform with the inverse of a 12-parameter linear fit (`lin_from_nlin -lsq12`) ([analysis.py L17-26](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/analysis.py#L17-L26), [L91-122](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/analysis.py#L91-L122)). The analogue in this repository is the "delin" path in `dbm.sh` (`ANTSUseDeformationFieldToGetAffineTransform`).

**Smoothing.** pydpiper smooths the **displacement field** with `smooth_vector` and then computes the determinant ([analysis.py L78-79](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/analysis.py#L78-L79), [L206-213](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/analysis.py#L206-L213)). `dbm.sh` smooths the Jacobian image instead. The kernels come from `--stats-kernels` (default `0.2`, in mm), and pydpiper always adds an unsmoothed version (`fwhm 0`) ([arguments.py L582-593](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/core/arguments.py#L582-L593), [analysis.py L172-177](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/analysis.py#L172-L177)). The determinant is `mincblob -determinant` plus 1, then `mincmath -log` ([analysis.py L28-62](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/analysis.py#L28-L62), [L84-87](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/analysis.py#L84-L87)). The chain ignores `--no-calc-stats`: `rc.py` never reads `calc_stats`.

**Analysis CSV.** pydpiper writes `<pipeline_name>_analysis_files.csv` with one row per scan and kernel ([rc.py L881-906](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L881-L906)). The columns are `subject_id, timepoint, fwhm, log_det_absolute_second_level, log_det_relative_second_level, log_det_absolute_first_level, log_det_relative_first_level`. The first-level columns are `NA` for the common scan.

## 9. Output layout

`<out>` is `--output-dir` and `<name>` is `--pipeline-name`.

| Path | Content | Source |
|---|---|---|
| `<out>/<name>_processed/<scan basename>/` | Per-scan files: `resampled/`, `transforms/`, `tmp/`, `stats-volumes/` | [rc.py L175](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L175), [L181-183](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L181-L183); [core/files.py L39-48](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/core/files.py#L39-L48) |
| `<out>/<name>_lsq12_<ctp name>/` | Level 2 affine average (`avg_lsq12.mnc`) | [rc.py L176](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L176), [reg.py L1844-1859](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/registration.py#L1844-L1859) |
| `<out>/<name>_nlin_<ctp name>/` | Level 2 nonlinear averages `common-nlin-<i>.mnc`; the last is the template | [rc.py L177](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L177), [strategies.py L54-57](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/registration_strategies.py#L54-L57) |
| `<out>/<name>_montage/` | QC images, one per link and one per stage | [rc.py L178](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L178), [L435-444](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L435-L444) |
| `<out>/<name>_init_model/` or `<out>/<name>_<tp>_init_model/` | Initial model, or one per pride model | [reg.py L2604-2608](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/registration.py#L2604-L2608) |
| `<out>/<name>_target_file/`, `<out>/<name>_reg_target_resampled/` | `--lsq6-target` file; target resampled to `--resolution` | [reg.py L2718-2720](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/registration.py#L2718-L2720), [L2741-2753](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/registration.py#L2741-L2753) |
| `./<name>_analysis_files.csv` | Determinant index. Written to the **current working directory**, not `<out>` | [rc.py L881](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L881) |

## 10. MINC-specific parts with no direct ANTs equivalent

| pydpiper / MINC | Behaviour | ANTs approach |
|---|---|---|
| `xfminvert` on an `.xfm` with grids | Flags the transform as inverted; MINC inverts it numerically when it applies it | Use the explicit `1InverseWarp.nii.gz` and `[0GenericAffine.mat,1]` |
| `xfmconcat` | One `.xfm` that chains affine and grid transforms, listed from the source outward | A list of `-t` arguments, listed from the reference outward, or a composite field from `antsApplyTransforms -o [field,1]` |
| `minc_displacement` | Samples a chain of transforms into one displacement field on a given grid | `antsApplyTransforms -r <grid> -t ... -o [field.nii.gz,1]` |
| `mincblob -determinant` (+1) | Determinant of a displacement field | `CreateJacobianDeterminantImage 3 field out 1 0` |
| `smooth_vector --fwhm` | Smooths the displacement field before the determinant | No single tool. `SmoothDisplacementField` or per-component `SmoothImage`, or smooth the log-Jacobian as `dbm.sh` does (a different method) |
| `lin_from_nlin -lsq12` | Fits a 12-parameter linear transform to a nonlinear one | `ANTSUseDeformationFieldToGetAffineTransform` (the "delin" path in `dbm.sh`) |
| minctracc multilevel LSQ12 with mm blur and step sizes | Affine registration | `antsRegistration` affine stage (the `antsRegistration_affine_SyN` submodule) |
| Pairwise LSQ12 + `xfmaverage` | Unbiased affine template start | `modelbuild.sh` affine stages with transform averaging |
| Legacy `ANTS` CC on blurred gradient images | Second similarity metric | No gradient metric in `antsRegistration`. Precompute gradient images (for example `ImageMath Grad`) and add a second metric, or drop it |
| `rotational_minctracc` (`lsq6_large_rotations`) | Brute-force rotation search for the rigid step | `antsAI`, or the rigid path of the submodule |
| `nu_correct`, `inormalize` | Level 0 preprocessing | `N4BiasFieldCorrection`; intensity normalisation is out of scope for this repository today |

## Open questions for the spec

1. **Link direction.** pydpiper registers earlier → later and inverts links after the common timepoint. Do we copy this, or do we register every link toward the common timepoint, so that all links are used forward and no inverse is needed?
2. **Link symmetry.** Do we keep one asymmetric registration per pair, or use a symmetric link (for example a two-scan `modelbuild.sh`, or a midpoint)? The choice affects bias between earlier and later scans.
3. **Missing data policy.** The code bridges gaps and keeps the subject. The slides say the subject is dropped. Which policy does our spec adopt? What happens when a subject has no scan at the common timepoint: error, drop, or fall back to another scan?
4. **Common timepoint selection.** Do we support `is_common`, `-1` (last scan), and per-subject overrides? Do we allow a Level 2 template that mixes ages?
5. **Fractional timepoints.** pydpiper accepts only integers for scans but floats for pride models. Do we accept floats?
6. **Pride of models.** Do we need it? If yes, must the models share one coordinate space? What is the ANTs substitute: a per-timepoint rigid target for Level 0, or a different initial target per scan?
7. **Level 0.** pydpiper removes the rigid part before the chain. Our pipelines start from raw scans. Where does the rigid step go, and does it stay out of the determinants?
8. **Affine in each link.** pydpiper hard-codes a mouse-tuned affine for links and ignores `--lsq12-protocol`. Do we reuse the `antsRegistration_affine_SyN` defaults for links?
9. **Smoothing.** Smooth the displacement field before the determinant (pydpiper) or the log-Jacobian after (`dbm.sh`)?
10. **Extra determinants.** Do we add per-link determinants (`t_n` vs `t_(n+1)`), which pydpiper lists in a comment but does not produce?
11. **Level 2 determinant meaning.** pydpiper's "second level" is the whole path. `twolevel_dbm.sh` has separate between-subject determinants and an "overall" sum. Which set of outputs does the chain spec produce, and with which names?
12. **Level 1 determinant grid.** pydpiper computes Level 1 on the common scan grid and resamples it as a scalar image. Do we do the same, or compute it on the template grid through the composite?
