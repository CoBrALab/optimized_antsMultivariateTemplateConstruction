# How pydpiper's Tamarack connects scans

Research for [#140](https://github.com/CoBrALab/optimized_antsMultivariateTemplateConstruction/issues/140), part of map [#138](https://github.com/CoBrALab/optimized_antsMultivariateTemplateConstruction/issues/138).

## Sources

- pydpiper source, pinned at commit
  [`04db1087f685dc54ec43253bb030efc438a2bbd8`](https://github.com/Mouse-Imaging-Centre/pydpiper/tree/04db1087f685dc54ec43253bb030efc438a2bbd8)
  (branch `main`, 2022-09-29). The `develop` branch has an identical
  `registration_tamarack.py`. All line numbers below refer to this commit.
- MISS 2017 longitudinal registration slides (MICe),
  [PDF](https://mouse-imaging-centre.github.io/summer_school2017/longitudinal_slides/MISS_Longitudinal_Registration.pdf),
  pages 10, 26, 27 and 28.
- The MICe wiki page "Longitudinal Registration Tools" is not reachable
  (DNS lookup of `wiki.mouseimaging.ca` fails). This document does not use it.
- The pydpiper issue tracker has no issues that mention Tamarack.

Short links used below (all at the pinned commit):

| Short name | File |
|---|---|
| `tamarack` | [`pydpiper/pipelines/registration_tamarack.py`](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_tamarack.py) |
| `chain` | [`pydpiper/pipelines/registration_chain.py`](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py) |
| `MBM` | [`pydpiper/pipelines/MBM.py`](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/MBM.py) |
| `registration` | [`pydpiper/minc/registration.py`](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/registration.py) |
| `strategies` | [`pydpiper/minc/registration_strategies.py`](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/registration_strategies.py) |
| `analysis` | [`pydpiper/minc/analysis.py`](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/analysis.py) |
| `files` | [`pydpiper/core/files.py`](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/core/files.py) |
| `test_cli` | [`test/test_cli.py`](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/test/test_cli.py) |
| `NEWS` | [`NEWS`](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/NEWS) |

## Answer in brief

Tamarack is a "transposed" Registration Chain. `NEWS` L120-123 says:
"This acts sort of like a 'transposed' registration chain in which
between-timepoint registrations are obtained (via composition) from
average-to-average registrations". Its topology is:

```
Level 1 (one template per timepoint, all subjects at that timepoint):

   scans @ t0      scans @ t1      scans @ t2      scans @ t3
       |               |               |               |
    [MBM]           [MBM]           [MBM]           [MBM]
       v               v               v               v
      T0              T1              T2              T3

Level 2 (template to next template, forward in time only):

      T0 ---X0---> T1 ---X1---> T2 ---X2---> T3
                               ^
                        common timepoint (for example t2)

To common space:  T0 -> T2 = X0 then X1
                  T1 -> T2 = X1
                  T2        = identity
                  T3 -> T2 = inverse(X2)
```

- Level 1 groups scans by timepoint, not by subject. Tamarack has no subject
  identifier. It never links the scans of one subject across time.
- Level 2 registers each timepoint template to the next timepoint template
  with one asymmetric affine (12 parameter) plus nonlinear registration.
- The pipeline composes the level 2 transforms to reach the template of one
  user-selected common timepoint.
- It writes two determinant tables: level 1 determinants resampled into the
  common template, and "overall" determinants of the composed
  scan-to-common-template transform.
- The shipped code composes the transforms incorrectly when two or more
  timepoints come after the common timepoint (see
  [Section 4.2](#42-bug-wrong-composition-after-the-common-timepoint)).

## 1. Input format

- CLI flag `--csv-file` (generic application flag,
  [`pydpiper/core/arguments.py` L269-271](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/core/arguments.py#L269-L271)).
- Tamarack reads only two columns: `group` and `filename`
  (`tamarack` [L38-46](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_tamarack.py#L38-L46),
  `usecols=['group', 'filename']`). It strips whitespace from `filename`.
  All other columns are ignored.
- `group` is the timepoint. The code comment says so
  (`# TODO 'group' => 'timept' ?`, L106). The test suite builds the Tamarack
  CSV from the Registration Chain CSV with `group = timepoint`
  (`test_cli` [L69-72](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/test/test_cli.py#L69-L72)).
- `group` must be numeric:
  - `--common-time-point` has `type=float` and the help text says it "must be
    one of the group IDs" (L237-238).
  - The code compares `group` with the common timepoint using `==`, `<` and
    `>=` (L156-159, L181-184). A text label (for example `p3`) makes these
    comparisons fail.
  - `sort_values(by='group')` (L121) sets the order of the timepoints. The
    order is numeric order of `group`, not the order of rows in the CSV.
- File basenames must be unique across the whole CSV. pydpiper makes one
  directory per basename
  (`registration` [L2133-2145](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/registration.py#L2133-L2145)).
- Inputs are MINC files.

Example:

```csv
group,filename
3,/data/sub01_p3.mnc
3,/data/sub02_p3.mnc
5,/data/sub01_p5.mnc
5,/data/sub02_p5.mnc
17,/data/sub02_p17.mnc
```

## 2. Level 1: one template per timepoint

`tamarack` [L104-123](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_tamarack.py#L104-L123)
groups the rows by `group` and calls the standard MBM function `mbm()` once
per group, with `prefix=<group>` and output directory
`<output_dir>/<pipeline_name>_first_level/<group>_processed`.

`mbm()` (`MBM` [L211-474](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/MBM.py#L211-L474)) does these steps for the scans of one timepoint:

1. **Registration target.** `registration_targets()` picks the LSQ6 target
   (`MBM` L232-234). Target types are `initial_model`, `bootstrap`,
   `target`, `pride_of_models`
   (`registration` [L64-65](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/registration.py#L64-L65)).
   - With `--bootstrap`, each timepoint uses the first scan of its own group
     as target (`MBM` L234 passes `imgs[0].path`;
     `registration` [L2722-2730](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/registration.py#L2722-L2730)).
     Thus the timepoint templates are not in one shared rigid space.
   - With `--init-model` or `--lsq6-target`, all timepoints share one target.
   - With a pride of models, `group_options()` picks, per timepoint, the
     model with the closest `time_point` and changes the target type to
     `initial_model` (`tamarack` [L69-102](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_tamarack.py#L69-L102)).
     The pride CSV has columns `model_file` and `time_point`
     (`registration` [L2778-2832](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/registration.py#L2778-L2832)).
     If there is no exact match and there is a tie, the later timepoint wins
     (`chain` [L538-578](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L538-L578)).
2. **LSQ6 (rigid)** to the target, with optional non-uniformity correction
   and intensity normalization (`lsq6_nuc_inorm`, `MBM` L284-289). If
   `--no-run-lsq6`, pydpiper uses an identity transform (L290-302).
3. **Optional MAGeT masking and segmentation** (`MBM` L305-320, L411-423).
   Tamarack calls `mbm()` with the default `with_maget=True`.
4. **LSQ12 (affine), pairwise.** Each scan is registered to the other
   scans (or to `max_pairs` random scans). The affine transforms of each scan
   are averaged with `xfmavg`. The resampled scans are averaged into the LSQ12
   average (`registration` [L1814-1919](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/registration.py#L1814-L1919),
   [L1932-1978](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/registration.py#L1932-L1978)).
5. **Nonlinear template building.** For each level of the nonlinear protocol:
   register every scan to the current average, then average the resampled
   scans into `<group>-nlin-<i>.mnc`
   (`strategies` [L33-59](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/registration_strategies.py#L33-L59)).
   There is no shape-update step (no inverse-average-warp correction). The
   last generation is the timepoint template `avg_img`.
6. **Per-scan transform.** `lsq12_nlin_xfm` = LSQ12 then nonlinear, from the
   LSQ6-resampled scan to the timepoint template
   (`registration` [L2091-2096](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/registration.py#L2091-L2096)).
   `mbm()` returns it in the `xfms` table together with `rigid_xfm` and
   `overall_xfm` (rigid then LSQ12 then nonlinear) (`MBM` L391-396).
7. **Level 1 determinants.** See [Section 5.1](#51-level-1-determinants).

Tamarack requires all timepoints to run at one resolution. If not, it stops
with `ValueError` (`tamarack` [L125-130](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_tamarack.py#L125-L130)).

## 3. Level 2: connect sequential timepoint templates

`tamarack` [L137-152](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_tamarack.py#L137-L152):

```python
average_registrations = (
    first_level_results[:-1]
        .assign(next_model=list(first_level_results[1:].build_model))
        # TODO: we should be able to do lsq6 registration here as well!
        .assign(xfm=lambda df: df.apply(axis=1, func=lambda row: s.defer(
                                  lsq12_nlin(source=row.build_model.avg_img,
                                             target=row.next_model.avg_img, ...
                                             resample_source=True)))))
```

- **Pairs.** Only adjacent timepoints in sorted order: `T[i] -> T[i+1]`.
  N timepoints give N-1 registrations. There are no skip connections.
- **Direction.** Source is the earlier template. Target is the later template.
  Only this direction is registered. The slides show the same forward arrows:
  "p3 consensus average → p5 avg", "p5 avg → p17 avg", "p17 avg → p36 avg"
  (slide page 28).
- **Symmetry.** None. It is one asymmetric source-to-target registration. There
  is no midpoint template and no inverse-consistency step. When pydpiper needs
  the other direction, it inverts the transform with `xfminvert`
  (`registration` [L1015-1045](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/registration.py#L1015-L1045)).
- **Transform types.** `lsq12_nlin()`
  (`registration` [L1620-1699](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/registration.py#L1620-L1699)):
  a 12-parameter affine registration with `minctracc` (`--lsq12-protocol`),
  then one nonlinear registration with the MBM nonlinear method and protocol
  (`--registration-method`, `--nlin-protocol`;
  [`pydpiper/core/arguments.py` L655, L684, L695](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/core/arguments.py#L655-L695)).
  The level 1 templates and the level 2 registrations use the same flags.
  No rigid (LSQ6) step (see the
  TODO at L141). The affine and nonlinear parts are concatenated into one
  transform.
- **Primitive.** `lsq12_nlin()` is the same function that the Registration
  Chain uses for within-subject registration of consecutive scans
  (`chain` [L137-147](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L137-L147);
  docstring at `registration` L1632).

## 4. Common timepoint and composition to common space

### 4.1 Intended behaviour

- `--common-time-point` (required, float) selects the template that is the
  common space (`tamarack` L155-156, L237-238). The value must equal one
  `group` value. If not, `.iloc[0]` at L156 raises `IndexError`.
- The code splits the level 2 transforms at the common timepoint
  (L158-159): `before` = transforms whose source timepoint is earlier than the
  common timepoint. `after` = the others.
- Notation: timepoints `t0 < t1 < ... < t(n-1)`, common timepoint `tk`,
  `Xi` = level 2 transform `T(ti) -> T(t(i+1))`. In MINC, `xfmconcat A B`
  applies `A` first, then `B` (`registration` L750-783; the same order is used
  for `[lsq12, nlin]` at L1695).
- `xfm_to_common` per timepoint
  (`tamarack` [L177-187](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_tamarack.py#L177-L187)):

| Timepoint | Transform to `T(tk)` | Name in pydpiper |
|---|---|---|
| `ti`, `i < k` | `xfmconcat Xi X(i+1) ... X(k-1)` | `<group>_to_common` |
| `tk` | none (`None`, used as identity) | — |
| `ti`, `i > k` | `invert(xfmconcat Xk ... X(i-1))` | `<group>_from_common`, then inverted |

For timepoints before the common timepoint, the code uses the level 2
transforms forward. For timepoints after it, the code composes the forward
chain from the common template and inverts the result. The code never runs a
registration in the reverse time direction.

### 4.2 Bug: wrong composition after the common timepoint

The helper that builds the `after` lists does not return prefixes.
`tamarack` [L170-175](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_tamarack.py#L170-L175):

```python
def prefixes(xs):
    if len(xs) == 0:
        return [[]]
    else:
        ys = prefixes(xs[1:])
        return ys + [ys[-1] + [xs[0]]]
```

`prefixes([a, b, c])` returns `[[], [c], [c, b], [c, b, a]]`. The correct
result is `[[], [a], [a, b], [a, b, c]]`. For this research, `suffixes` and `prefixes` were copied
verbatim and run for 5 timepoints with common timepoint `t2`:

```
t0: [X0, X1]   correct
t1: [X1]       correct
t2: None       correct
t3: [X3]       wrong, expected [X2]      (X3 is T(t3) -> T(t4); it does not touch T(t2))
t4: [X3, X2]   wrong, expected [X2, X3]  (wrong order, and the chain is not connected)
```

- The result is correct only when zero or one timepoints come after the
  common timepoint.
- `concat_xfmhandlers` does not check that the target of one transform is the
  source of the next (`registration` [L792-814](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/registration.py#L792-L814)).
  Thus the pipeline runs and gives wrong outputs with no error.
- The wrong source template also breaks the join in `resampled_determinants`
  (L194-199 join on `source`). Level 1 determinants of one timepoint get the
  transform of another timepoint.
- The test (`test_cli` [L247-254](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/test/test_cli.py#L247-L254))
  uses 3 timepoints and each one as common timepoint, but it runs with
  `--no-execute` (L122-125) and checks only `ret.success`. It cannot find this
  bug.
- The Registration Chain does the same composition correctly: it inverts each
  step and then concatenates, moving away from the common timepoint
  (`chain` [L783-795](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_chain.py#L783-L795)).

**For the spec: implement the intended topology of Section 4.1, not the
shipped list builder.**

## 5. Determinants and transform compositions

`determinants_at_fwhms()` (`analysis` [L142-193](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/analysis.py#L142-L193))
is used at both levels. For each transform and for each FWHM in
`--stats-kernels` ([`arguments.py` L591](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/core/arguments.py#L591)) plus 0 (unblurred), it makes:

- `full_det` / `log_full_det` (file suffix `_abs`): convert the transform to a
  displacement field (`minc_displacement`), optionally blur the field
  (`smooth_vector`), compute the determinant (`mincblob -determinant`, plus 1),
  take the log (L66-88, L196-213).
- `nlin_det` / `log_nlin_det` (file suffix `_rel`): same, but first remove the
  linear part. `nlin_part()` first inverts the transform (template to scan
  becomes scan to template). `lin_from_nlin -lsq12` fits a 12-parameter affine
  to that inverse. Then `nlin_part()` applies the forward transform followed by
  this affine, which cancels the linear part (L17-26, L91-139).

The input transforms go from the template to the scan
(docstring L147-166). The determinant images are on the template grid.

### 5.1 Level 1 determinants

`MBM` [L381-387](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/MBM.py#L381-L387):
`xfms = invert(lsq12_nlin_xfm)` (timepoint template to LSQ6-resampled scan),
`inv_xfms = lsq12_nlin_xfm`. The rigid (LSQ6) part is not included. A rigid
transform has determinant 1, so this does not change the determinant values.
These determinants are on the grid of each timepoint template.

### 5.2 Level 1 determinants resampled into common space (`resampled_determinants`)

`tamarack` [L190-210](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_tamarack.py#L190-L210):

- Resample `log_full_det` and `log_nlin_det` of each scan from `T(ti)` into
  `T(tk)` with `xfm_to_common` (`mincresample_new(..., like=common_model)`).
- This is only a resample of the level 1 values. Tamarack does not compute
  level 2 determinants and does not add them to these values. This is
  different from `twolevel_dbm.sh`, which adds the resampled level 1 log
  Jacobian and the level 2 log Jacobian
  ([`twolevel_dbm.sh` L296-306](https://github.com/CoBrALab/optimized_antsMultivariateTemplateConstruction/blob/477735b38736f9ba91f7e6372ab8eb77d8629bed/twolevel_dbm.sh#L296-L306)).
- **The common timepoint is missing from this table.** For `tk`,
  `xfm_to_common` is `None`, so the `source` join key is `None`. The inner
  `pd.merge` on `first_level_avg == source` (L195-199) finds no match and drops
  the rows. The fallback `else row.img` (L204, L209) refers to a column that
  does not exist, so it is dead code. The intended behaviour is to pass these
  determinants through unchanged (identity transform).

### 5.3 Overall determinants (`overall_determinants`)

`tamarack` [L212-222](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_tamarack.py#L212-L222):

```
inverted_overall_xfm(scan s in ti) = xfmconcat lsq12_nlin_xfm(s) xfm_to_common(ti)   # scan -> T(ti) -> T(tk)
overall_xfm(s)                     = invert(inverted_overall_xfm(s))                 # T(tk) -> scan
overall_determinants = determinants_at_fwhms(xfms=overall_xfm, inv_xfms=inverted_overall_xfm)
```

- For `tk`, the overall transform is `lsq12_nlin_xfm(s)` only (L213).
- The chain is: scan (LSQ6 space) -> LSQ12 -> nonlinear -> `T(ti)` ->
  level 2 affine and nonlinear steps -> `T(tk)`. The LSQ6 rigid part is not
  included (the code uses `lsq12_nlin_xfm`, not `overall_xfm`).
- The determinant is computed from the displacement field of the full composed
  transform, on the grid of `T(tk)`. It is not a sum of per-level log
  determinants.
- The "relative" (`nlin`) overall determinant removes one 12-parameter affine,
  fitted to the whole composed transform. It does not remove the affine parts
  of each level one by one.

### 5.4 CSV outputs

`tamarack` [L56-57](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/registration_tamarack.py#L56-L57)
writes `resampled_determinants.csv` and `overall_determinants.csv`. Columns
come from `determinants_at_fwhms` (`xfm`, `inv_xfm`, `fwhm`, `nlin_det`,
`log_nlin_det`, `full_det`, `log_full_det`). The resampled table also has
`first_level_avg`, `group`, `xfm_to_common`, `source`,
`resampled_log_full_det` and `resampled_log_nlin_det` (L231-232 drop
`options`, `build_model`, `files`). There is no `subject` column. The code
does not write a table of level 1 results (L54-55 is commented out).

## 6. Missing data

- Each scan belongs to exactly one timepoint group. Groups can have different
  numbers of scans. A subject with no scan at a timepoint is simply absent from
  that timepoint template. Nothing in the code needs a balanced design, because
  the code has no concept of a subject.
- Each timepoint needs at least one scan (`MBM` L227-228 raises
  `ValueError("Please, some files!")`). A timepoint with one scan gives a
  "template" that is that scan after LSQ6.
- The common timepoint must be one of the `group` values.
- The slides agree: the table on page 11 lists "Requires a balanced design (no
  missing data!)" as a con for Overlapping group-wise, and says it is the "Same
  as Tamarack, except you cannot have any missing data!". This implies Tamarack
  accepts missing data.
- Consequence for analysis: two scans of one subject are never registered to
  each other. Within-subject change is only measured through the level 2
  template-to-template transforms plus the cross-sectional level 1 transforms.

## 7. Output layout

With `--output-dir <out>` and `--pipeline-name <pipe>`:

```
<out>/<pipe>_first_level/
  <group>_processed/                      one per timepoint (tamarack L34, L116-120)
    <group>_lsq6/                         MBM L221
    <group>_lsq12/                        MBM L222
    <group>_nlin/                         MBM L223
      <group>-nlin-<i>.mnc                timepoint templates per generation (strategies L56-57)
      <group>-nlin-<N>/transforms/        level 2 transforms (source = this template),
                                          <group>_to_common / _from_common concatenations
    <scan_basename>/                      per-scan files (inputs use this pipeline_sub_dir, tamarack L44-46)
      transforms/  resampled/  tmp/  stats-volumes/
    <group>_processed/                    MAGeT outputs, only with MAGeT (MBM L416-420)
<out>/<group>_atlases/                    MAGeT masking, only with MAGeT (MBM L307-311)
<cwd>/resampled_determinants.csv
<cwd>/overall_determinants.csv
```

- Registration transforms go to
  `<source.pipeline_sub_dir>/<source.output_sub_dir>/transforms/`
  ([`pydpiper/minc/ANTS.py` L161-174](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/minc/ANTS.py#L161-L174);
  `antsRegistration.py` L211-228 does the same). For level 2, the source is
  the earlier timepoint template.

- New files go to `<pipeline_sub_dir>/<output_sub_dir>/<subdir>/`, where
  `output_sub_dir` defaults to the basename of the parent file
  (`files` [L111-143](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/core/files.py#L111-L143)).
  Thus a derived transform lands in the tree of the first file it derives
  from (`xfmconcat` names its output from `xfms[0]`, `registration` L762-776).
- Log determinant files use subdir `stats-volumes` (`analysis` L84-87).
- The two CSV files use relative paths. The `chdir` to the output directory is
  commented out
  ([`pydpiper/execution/application.py` L144-145](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/execution/application.py#L144-L145)),
  so the CSVs go to the current working directory.

## 8. What Tamarack reuses

- From `registration_chain.py`: only `get_closest_model_from_pride_of_models`
  (`tamarack` L10), for per-timepoint targets with a pride of models.
- From MBM: all of level 1 (`mbm()`, `mk_mbm_parser(with_common_space=False,
  with_maget=True)`, L13, L252-254).
- Shared primitives with the Registration Chain: `lsq12_nlin` (level 2),
  `concat_xfmhandlers`, `invert_xfmhandler`, `determinants_at_fwhms`,
  `mincresample_new` (L18-22).
- `twolevel_model_building.py` has a copy of `group_options()` (its comment:
  "FIXME this is the same as in the 'tamarack'",
  [L126](https://github.com/Mouse-Imaging-Centre/pydpiper/blob/04db1087f685dc54ec43253bb030efc438a2bbd8/pydpiper/pipelines/twolevel_model_building.py#L126)).
- Tamarack does not use the Registration Chain CSV parser, `Subject` class or
  per-subject common timepoint override.

## 9. MINC-specific parts and ANTs equivalents

| pydpiper / MINC | ANTs / this repo | Note |
|---|---|---|
| MBM per timepoint (LSQ6, pairwise LSQ12, iterative nlin) | `modelbuild.sh` per timepoint | `modelbuild.sh` adds shape update and sharpening. pydpiper has no shape update. |
| Pairwise LSQ12 with `xfmavg` | `modelbuild.sh` affine stages with affine averaging | No direct ANTs equivalent of all-pairs affine averaging. |
| LSQ6 with `nu_correct`/`inormalize`, `--lsq6-large-rotations` | `modelbuild.sh` rigid stage / starting target | Preprocessing is outside this repo. |
| Init model with native/standard pair, pride of models | `modelbuild.sh --starting-target` per timepoint | Pride of models = one starting target per timepoint. |
| `lsq12_nlin(T(ti), T(ti+1))` | `antsRegistration` (affine + SyN), fixed = `T(ti+1)`, moving = `T(ti)` | `antsRegistration_affine_SyN` submodule gives this. |
| MINC `.xfm`: maps source to target; `xfmconcat A B` applies A first | ANTs `-t` stack: list the last-applied transform first | The order in `antsApplyTransforms` is the reverse of `xfmconcat`. See below. |
| `xfminvert` of a nonlinear `.xfm` | `[affine.mat,1]` plus `1InverseWarp.nii.gz` | ANTs SyN gives the inverse warp directly. |
| `minc_displacement` | `antsApplyTransforms -o [field.nii.gz,1]` | Collapse a transform stack into one displacement field. |
| `mincblob -determinant` (+1), `mincmath -log` | `CreateJacobianDeterminantImage 3 field out 1 0` | |
| `lin_from_nlin -lsq12` | `ANTSUseDeformationFieldToGetAffineTransform` ([`dbm.sh` L398](https://github.com/CoBrALab/optimized_antsMultivariateTemplateConstruction/blob/477735b38736f9ba91f7e6372ab8eb77d8629bed/dbm.sh#L398)) | This repo's "delin" path. |
| `smooth_vector` (blur displacement field before determinant) | `dbm.sh --jacobian-smooth` blurs the Jacobian image | Different: pydpiper blurs the field, this repo blurs the Jacobian. |

ANTs transform stacks for the intended topology (derived here, not in
pydpiper). `Xi` is the `antsRegistration` output with fixed = `T(t(i+1))`,
moving = `T(ti)`. The stack order follows the pattern that
`twolevel_dbm.sh` already uses (level 2 transforms listed before level 1,
[L273-279](https://github.com/CoBrALab/optimized_antsMultivariateTemplateConstruction/blob/477735b38736f9ba91f7e6372ab8eb77d8629bed/twolevel_dbm.sh#L273-L279)):

```
# ti earlier than tk: move an image from T(ti) space to T(tk) space
antsApplyTransforms -r T(tk) \
  -t X(k-1)_1Warp -t X(k-1)_0GenericAffine ... -t Xi_1Warp -t Xi_0GenericAffine

# ti later than tk: move an image from T(ti) space to T(tk) space
antsApplyTransforms -r T(tk) \
  -t [Xk_0GenericAffine,1] -t Xk_1InverseWarp ... -t [X(i-1)_0GenericAffine,1] -t X(i-1)_1InverseWarp

# overall, scan s in ti: append the level 1 transforms of s at the end
  ... -t s_1Warp -t s_0GenericAffine
```

## 10. Open questions for the spec

1. **After-common composition.** Confirm that we implement the intended
   topology (Section 4.1) and not pydpiper's shipped `prefixes()` behaviour.
2. **Common timepoint determinants.** Pass the level 1 determinants of the
   common timepoint through unchanged (identity), where pydpiper drops them?
3. **Level 2 determinants.** Compute overall determinants from the Jacobian of
   the composed field (pydpiper), or as a sum of resampled level 1 and level 2
   log Jacobians (as `twolevel_dbm.sh` does)? Do we also write explicit level 2
   (template-to-template) determinants?
4. **Relative (delin) overall determinant.** Remove one affine fitted to the
   whole composed transform (pydpiper), or remove the affine part per level?
5. **Level 2 registration symmetry.** Keep one asymmetric forward registration
   per pair, or use a symmetric (midpoint) registration to remove direction
   bias?
6. **Rigid step at level 2.** pydpiper has none (TODO at L141). With
   per-timepoint `--starting-target` or bootstrap targets, the timepoint
   templates are not in one rigid space. Add a rigid stage, or require one
   shared starting target?
7. **Timepoint labels.** pydpiper needs numeric `group` values and sorts them
   numerically. Do we accept text labels with an explicit order?
8. **Default common timepoint.** pydpiper requires the flag. Do we give a
   default (first, last, or middle timepoint)?
9. **Subject identifier.** Tamarack ignores subjects. Do we accept (and carry
   through to outputs) a subject column for downstream statistics, even though
   the topology does not use it?
10. **Final target.** Do we allow a final registration of `T(tk)` to an
    external target, as `modelbuild.sh` and `twolevel_dbm.sh
    --target-space` do?
