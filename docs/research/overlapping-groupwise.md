# Overlapping group-wise: definition and topology

Research for [#141](https://github.com/CoBrALab/optimized_antsMultivariateTemplateConstruction/issues/141), part of map [#138](https://github.com/CoBrALab/optimized_antsMultivariateTemplateConstruction/issues/138).

Question: what is the Overlapping group-wise longitudinal strategy, where is it defined, and how do we re-implement it with ANTs?

Vocabulary follows `CONTEXT.md`: **Template**, **Longitudinal strategy**, **Level 1 / Level 2**. The words "atlas", "average" and "consensus average" appear only inside quotes.

## Answer in brief

- The primary source is **Szulc et al. 2015**, "4D MEMRI atlas of neonatal FVB/N mouse brain development", *NeuroImage* 118:49–62, [doi:10.1016/j.neuroimage.2015.05.029](https://doi.org/10.1016/j.neuroimage.2015.05.029) (author manuscript [PMC4554969](https://pmc.ncbi.nlm.nih.gov/articles/PMC4554969/)). The definition is in *Materials and Methods → Image Analysis → Developmental Time-Series Registration*, Fig. 2, and Eq. (1). [S1]
- The MISS 2017 slides reuse Fig. 2 of that paper. The slides are a summary of the paper, not a second source. Lerch and Friedel (MICe) are co-authors of the paper. [S1, S2]
- No code implements the strategy. pydpiper has no pipeline for it on any branch. The MICe wiki has no page for it. [S3, S4]
- Level 1: in each cohort, build one Template for each pair of adjacent timepoints. The inputs are all scans of that cohort at the two timepoints. [S1 §Developmental Time-Series Registration, Fig. 2]
- Level 2: build one Template from the last-timepoint scans of all cohorts. This Template is the common space. [S1 §Developmental Time-Series Registration, Fig. 2]
- The paper registers no Template to another Template. A subject's own scan at the shared timepoint connects two adjacent Templates. Transforms are concatenated through that scan. [S1 Eq. (1)]
- The paper computes one Jacobian determinant per scan, in Level 2 space, from the inverse of the full concatenated transform. [S1 §Developmental Time-Series Registration]
- No primary source defines separate "Level 1" and "Level 2" determinants. The slides name them, but give only one sentence each. [S2 p. 34]

## Sources

| ID | Source | Pin |
|----|--------|-----|
| S1 | Szulc KU, Lerch JP, Nieman BJ, Bartelle BB, Friedel M, Suero-Abreu GA, Watson C, Joyner AL, Turnbull DH. 4D MEMRI atlas of neonatal FVB/N mouse brain development. *NeuroImage* 2015;118:49–62. | [doi:10.1016/j.neuroimage.2015.05.029](https://doi.org/10.1016/j.neuroimage.2015.05.029), PMID 26037053, PMC4554969 (NIHMS696093). Text read from the PMC OAI JATS XML. |
| S2 | MICe Summer School 2017, "Longitudinal Registration" slides. | [`longitudinal_slides/MISS_Longitudinal_Registration.pdf`](https://github.com/Mouse-Imaging-Centre/summer_school2017/blob/371f5520ee01b903c2d542001bce07bc6efaf708/longitudinal_slides/MISS_Longitudinal_Registration.pdf) at `Mouse-Imaging-Centre/summer_school2017@371f552`. Page numbers are PDF pages. |
| S3 | pydpiper source code. | `Mouse-Imaging-Centre/pydpiper@04db1087f685dc54ec43253bb030efc438a2bbd8` (`main`) and all 13 remote branches. |
| S4 | MICe wiki, "Longitudinal Registration Tools". | Wayback snapshots [20240615075028](https://web.archive.org/web/20240615075028/https://wiki.mouseimaging.ca/display/MICePub/Longitudinal+Registration+Tools) and 20191118072520. The live host `wiki.mouseimaging.ca` does not resolve. |

## Where the strategy is (and is not) defined

### The primary definition: Szulc et al. 2015

The design has two cohorts of six FVB/N mice. "Mice in the first group were imaged 6 times, every other day at the 'odd-day' stages from postnatal day (P)1 to P11 ... Mice in the second group were imaged 5 times, every other day at the 'even-day' stages from P2 to P10." [S1 §Animals]

The paper states the strategy in one paragraph [S1 §Developmental Time-Series Registration]:

> Our chosen registration strategy relies on group-wise registrations, taking advantage of the balanced study design of the data. [...] Overlapping group-wise registrations are performed on all scans from adjacent days within the odd day cohort and even day cohort as illustrated in Figure 2. For example, a group-wise average is created from all P3 and P5 scans, and a separate group-wise average from all P5 and P7 scans. The two cohorts are brought into a common space by a group-wise registration of the P10 and P11 scans.

Fig. 2 caption [S1]:

> The analysis strategy employed in this study takes advantage of the improved registration performance and numerical stability of groupwise registrations. Adjacent days for each cohort are aligned together, so that every brain, with the exception of those at the beginning of the series, participates in two groupwise registrations. For example, the P5 scans are incorporated in both a registration of all P3 and P5 scans and in another registration of all P5 and P7 scans. The even- and odd-day cohorts are joined by registering the P10 and P11 scans together.

The paper also gives the reason for the strategy: "it is not possible to accurately register a P1 scan to a P11 scan, even for the same mouse". [S1 §Developmental Time-Series Registration] Fig. 6 measures this. "Accurate registrations (Kappa > 0.75) were only obtained within two days for the early scans (P1-P5), but could be obtained over a larger range for later days (P6-P11)." [S1 §Results, Registration accuracy; Fig. 6]

### The slides (secondary)

The slides [S2] use the same figure as S1 Fig. 2 (same panels, same labels "Odd day cohort", "Even day cohort", "P1+P3 avg" ... "P10+P11 avg"). The slides add these statements:

- "Register adjacent timepoints of each cohort. Register last timepoint in each cohort together." [S2 p. 32]
- "Level 1 determinants tell us intra-cohort spatiotemporal volumetry. Level 2 determinants tell us inter-cohort spatiotemporal volumetry." [S2 p. 34]
- An 11-step path "from mouse 1 P1 to mouse 6 P2": "Mouse 1 P1 → P1+3 avg → P3+5 avg → P5+7 avg → P7+9 avg → P9+11 avg → P10+11 avg → P8+10 avg → P6+8 avg → P4+6 avg → P2+4 avg → Mouse 6 P2". [S2 p. 35]
- Disadvantages: "Balanced Design", "May introduce cohort biases". [S2 p. 36]
- Level 1 = "Within cohort; information across time and information across subject within same cohort". Level 2 = "Across cohort; information across time and across subjects in different cohorts". [S2 p. 37]
- Con: "Requires a balanced design (no missing data!)". When to use: "Same as Tamarack, except you cannot have any missing data!" [S2 p. 38]

The slides give no command, script name or wiki link for this strategy. The Registration Chain section has both (`registration_chain.py` and the wiki URL). [S2 p. 15, compare p. 32]

### Negative results

- **pydpiper.** `pydpiper/pipelines/` at S3 contains `asymmetry.py`, `cortical_thickness.py`, `LSQ12.py`, `LSQ6.py`, `MAGeT.py`, `MBM.py`, `NLIN.py`, `registration_chain.py`, `registration_tamarack.py`, `stage_embryos_in_4D_atlas.py`, `twolevel_model_building.py`. `git grep -i overlap` over all 13 remote branches matches only a comment in `pydpiper/execution/queueing.py` (about server/client overlap). `git log --all -G "overlapping|adjacent time"` returns nothing. No commit message names the strategy. [S3]
- **`stage_embryos_in_4D_atlas.py`** is not related. It stages one embryo scan against an existing 4D embryo atlas: it finds the atlas timepoint with the closest volume, registers the scan to the atlas timepoints within ±7 of that match, and scores each registration by deformation magnitude. [S3 `pydpiper/pipelines/stage_embryos_in_4D_atlas.py` docstring lines 22–62, `match_embryo_to_4D_atlas` lines 112–150]
- **MICe wiki.** The "Longitudinal Registration Tools" page describes only Registration Chain. It has zero matches for "overlap" in the 2019 and 2024 snapshots. No other archived MICePub page name refers to it (checked "Workflow Diagrams", "Registration Chain Workflow", "Mouse Brain Imaging for Neurodevelopmental Disorders"). [S4]
- **GitHub search** of the `Mouse-Imaging-Centre` organisation for "overlapping" and "groupwise" code and issues finds nothing relevant. The companion slides `MISS_Longitudinal_Analysis.pdf` do not mention the strategy.
- **Literature.** A search for "overlapping group-wise" finds only S1 (and a ResearchGate copy of its Fig. 2). S1 says "The registration pipelines are implemented in pydpiper" [S1 §Software], but that refers to the group-wise registration itself (inference: probably one pydpiper model build for each Template). The overlap orchestration was not released.

## Topology

### Registration primitive: one "group-wise registration"

Each Template in this strategy is one "group-wise registration" [S1 §Developmental Time-Series Registration]:

> after rigidly aligning all scans into the same coordinate space with a 6-parameter transform and correcting for non-uniformity artifacts using the N3 algorithm, each scan is aligned with all other scans in the data set via uniform scales, shears, rotations and translations. From these alignments, the best possible linear average (atlas) of all subjects is created. This atlas provides the starting point for an iterative non-linear registration process; all scans are aligned towards this atlas, resampled with the resulting transforms, and averaged to create a newer, more accurate atlas. This process is repeated three times.

The non-linear step is ANTs SyN. [S1 §Developmental Time-Series Registration]

Inference: this is the pydpiper model-build sequence (LSQ6 → pairwise LSQ12 → iterative NLIN). In this repository, one `modelbuild.sh` run gives an equivalent Template and one transform pair (scan ↔ Template) for each input scan.

### Level 1: within-cohort Templates of adjacent timepoint pairs

- Group scans by cohort. A cohort is a set of subjects with the same scan schedule. In S1, the cohorts are "odd day" and "even day". [S1 §Animals, Fig. 2]
- Sort the cohort's timepoints: t₁ < t₂ < … < t_T.
- For each i = 1 … T−1, build one Template from all scans of the cohort at t_i and t_{i+1}. With N subjects, each Template has 2N inputs. [S1 §Developmental Time-Series Registration: "a group-wise average is created from all P3 and P5 scans"]
- The window is two timepoints and moves one timepoint at a time. All adjacent pairs are used. [S1 Fig. 2]
- Level 1 Templates never mix cohorts. [S1 Fig. 2; S2 p. 37 "Within cohort"]
- A cohort with T timepoints gives T−1 Level 1 Templates. In S1: odd cohort P1+P3, P3+P5, P5+P7, P7+P9, P9+P11 (5); even cohort P2+P4, P4+P6, P6+P8, P8+P10 (4). [S1 Fig. 2]

Inference: the paper names a Template after its time midpoint. The Level 2 Template is "P10.5" [S1 Eq. (1)]. The Level 1 Templates would then be P2, P4, … (odd cohort) and P3, P5, … (even cohort). The paper uses this name only for P10.5.

### Level 2: one cross-cohort Template of the last timepoints

- Build one Template from the scans at the last timepoint of every cohort. In S1: all P10 scans (even cohort) and all P11 scans (odd cohort), 12 scans. [S1 §Developmental Time-Series Registration: "a group-wise registration of the P10 and P11 scans"; S2 p. 32 "Register last timepoint in each cohort together"]
- This Template is the common space, "P10.5". [S1 Eq. (1)]
- The last-timepoint scans are inputs to two Templates: the last Level 1 Template of their cohort, and the Level 2 Template. This agrees with the Fig. 2 caption: every scan except the first-timepoint scans is in two group-wise registrations. [S1 Fig. 2]
- Total Templates: Σ_c (T_c − 1) + 1. In S1: 5 + 4 + 1 = 10, which matches the ten Templates in Fig. 2.
- In S1, the last timepoints of the two cohorts are adjacent days (P10, P11). The paper does not say whether this is a requirement.

Inference: the choice of the last timepoint agrees with MICe guidance for Registration Chain: "concatenating the transformations from the smaller subject towards the larger subject behaves well. However, we often see that concatenating transformation from the later (larger subject) time points towards the earlier ones results in very ill defined transformations." [S4] That text is about Registration Chain, not about this strategy.

### How Level 1 and Level 2 connect: transform concatenation through the subject's own scans

The paper gives one worked example, Eq. (1). Verbatim from the JATS MathML (subscripts flattened) [S1 Eq. (1)]:

```
T_{P7→P10.5} = T_{P7→Avg(P7+P9)} ⊕ T_{Avg(P7+P9)→P9} ⊕ T_{P9→Avg(P9+P11)} ⊕ T_{Avg(P9+P11)→P9} ⊕ T_{P11→P10.5}
```

"Transform concatenation is indicated by ⊕." [S1]

Reading of Eq. (1):

1. `T_{P7→Avg(P7+P9)}`: the scan's own transform into the first Level 1 Template it belongs to.
2. `T_{Avg(P7+P9)→P9}`: from that Template to the **same mouse's** P9 scan. Inference: this is the inverse of that P9 scan's transform into Avg(P7+P9). S1 does not say "same mouse" in words, but the chain is a single subject's time series ("The ability to analyze each subject's time series is maintained through overlapping adjacent scans"). [S1]
3. `T_{P9→Avg(P9+P11)}`: the same P9 scan's forward transform into the next Level 1 Template.
4. `T_{Avg(P9+P11)→P9}`: **as printed, this term ends at P9.** The next term starts at P11. For the chain to compose, this term must be `T_{Avg(P9+P11)→P11}`. Inference: the printed "P9" is a typo for "P11".
5. `T_{P11→P10.5}`: the same mouse's last-timepoint scan into the Level 2 Template.

Consequences:

- **The paper registers no Template to another Template.** The bridge between two adjacent Templates is a scan that is an input to both. [S1 Eq. (1)]
- Inference: all transforms in the chain are outputs of the Template builds (forward or inverse). The strategy needs no extra pairwise registration.
- The slide path in S2 p. 35 ("P1+3 avg → P3+5 avg → …") is a short form of this chain. Inference: each "avg → avg" hop is "avg → this mouse's shared scan → next avg". The path from mouse 1 (odd cohort) to mouse 6 (even cohort) goes up the odd chain to P10.5, then down the even chain with inverse transforms.
- General form (inference from Eq. (1)): for subject s in cohort c, scan at t_k, write A_i for the Level 1 Template of (t_i, t_{i+1}) and C for the Level 2 Template. Then

  ```
  T_{s,t_k → C} = T_{s,t_k → A_k} ⊕ T_{A_k → s,t_{k+1}} ⊕ T_{s,t_{k+1} → A_{k+1}} ⊕ … ⊕ T_{A_{T−1} → s,t_T} ⊕ T_{s,t_T → C}
  ```

  For k = T (last timepoint) the chain is only `T_{s,t_T → C}`. For k < T, the chain uses the forward transform into A_k, not into A_{k−1}. Eq. (1) shows this choice for P7 (it starts with Avg(P7+P9), not Avg(P5+P7)).

### Determinants

The paper [S1 §Developmental Time-Series Registration]:

> Although we explicitly constructed T_{p7→p10.5}, for much of our analysis we also require T_{p10.5→p7}, which can be attained simply by applying the inverse of the transform constructed in Equation (1). From these inverted transforms (encoded by displacement fields), we can compute the Jacobian determinant (in P10.5 space) for each transform. This gives a measure of growth or shrinkage at every voxel for every image in the dataset.

- So S1 defines **one determinant per scan**: the Jacobian determinant of the inverse of the full chain (Level 2 Template → scan), sampled in Level 2 space. Scans of all subjects and timepoints are then in one space for voxel-wise mixed-effects models with cohort as a fixed effect. [S1 §Developmental Time-Series Registration; §Automated Time-Series Analyses]
- The slides name "Level 1 determinants" (intra-cohort) and "Level 2 determinants" (inter-cohort). [S2 p. 34] No primary source defines how to compute them.
- Problem for any Level 1 definition: each scan in the middle of a cohort is an input to two Level 1 Templates. So "the" Level 1 determinant of that scan is not unique.
- Possible definitions (all inference, for the spec to decide):
  - (a) Level 1 = determinant of the scan's transform to one Level 1 Template, in that Template's space (like `dbm.sh` on each Level 1 Template).
  - (b) Level 1 = determinant of the chain up to the cohort's last Level 1 Template (A_{T−1}), in that space. This is "intra-cohort" and gives one space for each cohort.
  - (c) Level 2 = determinant of the full chain in Level 2 space (the S1 definition), or only of the last hop `T_{A_{T−1} → C}` resampled into Level 2 space (like two-level "level 2" determinants).

### Resampling labels (subject space and common space)

- S1 draws labels on the P11 average and on the "P10+P11 average image", then maps them to every scan "via inverse transforms". [S1 §Automated Time-Series Analyses: "Since all the images in the developmental time series (including the P11 images) from both the even and odd cohorts of mice were registered to the average P10+P11 image, once a region was defined in P11 space it could be mapped to each earlier time point via inverse transforms."] This is subject-space resampling through the inverse chain.
- S1 also tracks points placed on the average P11 image back through the registrations to earlier stages. [S1 §Quantitative analysis of cerebellum development, Fig. 12]
- Common-space resampling uses the forward chain of Eq. (1). [S1 Eq. (1)]

### Balanced design

- S1: the strategy is chosen "taking advantage of the balanced study design of the data". [S1 §Developmental Time-Series Registration] In S1, every mouse is scanned at every timepoint of its cohort, and each day has 6 scans. [S1 Abstract, §Animals]
- S2: "Requires a balanced design (no missing data!)". [S2 p. 38] "Balanced Design" is listed as a disadvantage. [S2 p. 36]
- S1 does not require equal timepoint counts across cohorts: the odd cohort has 6 timepoints and the even cohort has 5. [S1 §Animals]
- Why missing data breaks the strategy (inference from Eq. (1)): the chain for subject s crosses from A_i to A_{i+1} through the scan (s, t_{i+1}). If that scan is missing, the chain for s breaks at t_{i+1}. Scans of s before the gap cannot reach the Level 2 Template. A missing last-timepoint scan also removes the link from s to Level 2.
- Inference: unequal numbers of subjects per timepoint also change the weight of each timepoint in a two-timepoint Template.
- The missing-data policy is outside this ticket (see #138, "Not yet specified").

### Worked example from S1 (two cohorts, 6 + 6 mice)

| Level | Template | Inputs | Count |
|-------|----------|--------|-------|
| 1 (odd) | P1+P3, P3+P5, P5+P7, P7+P9, P9+P11 | 6 mice × 2 timepoints | 12 each |
| 1 (even) | P2+P4, P4+P6, P6+P8, P8+P10 | 6 mice × 2 timepoints | 12 each |
| 2 | P10+P11 ("P10.5") | 6 even-cohort P10 + 6 odd-cohort P11 | 12 |

[S1 §Animals, §Developmental Time-Series Registration, Fig. 2]

## Mapping to this repository (inference)

These are notes for the spec, not findings.

- Each Level 1 Template and the Level 2 Template is one `modelbuild.sh` run. The Level 1 runs are independent and can run in parallel. The Level 2 run only needs the last-timepoint scans, so it can also run in parallel with Level 1.
- Chain composition can use `antsApplyTransforms -o [composite.nii.gz,1]` with the Level 2 Template as reference, then `CreateJacobianDeterminantImage` on the composite field. This follows S1 (compose, then take the determinant). The alternative is the `twolevel_dbm.sh` pattern: compute a determinant at one level, then resample it into the next space with the next level's transforms (`twolevel_dbm.sh`, the `resampled-dbm` block near line 250).
- The chain goes through inverse transforms (Template → scan). The spec must decide how to get them: inverse warps and inverted affines from `modelbuild.sh`, or composition in the other direction and a single inversion as in S1.
- A chain crosses up to T hops. S1 inverts the concatenated forward chain; composing many hops can accumulate interpolation error.

## Open questions for the spec

1. **Level 1 / Level 2 determinants.** S1 defines only one determinant per scan (full chain, Level 2 space). The slides name Level 1 and Level 2 determinants with no method. Which definition do we ship (options a–c above)?
2. **Canonical Level 1 transform.** A middle scan belongs to two Level 1 Templates. Which one starts its chain? S1 Eq. (1) uses the later Template (P7 → Avg(P7+P9)). Do we follow that?
3. **Eq. (1) typo.** We read `T_{Avg(P9+P11)→P9}` as `→P11`. Confirm with the authors (Lerch, Friedel) if possible.
4. **More than two cohorts.** The slides say "Register last timepoint in each cohort together". Is Level 2 one Template of all cohorts' last timepoints, even if these timepoints are far apart?
5. **Cohort definition.** In S1, cohorts are interleaved in time (odd/even days). Do we accept any cohort schedule, or must cohort timepoints interleave and end on adjacent days?
6. **Window width.** S1 uses pairs (width 2, stride 1). Do we allow wider windows?
7. **Missing data.** The strategy has no rule for a missing scan. Do we reject the input, drop the subject, or bridge the gap another way (for example with another subject's scan or a Template-to-Template registration, which S1 does not do)?
8. **Per-timepoint averages.** S1 shows "registered and averaged images" at every day P1–P11 (Fig. 4, Fig. 7), but does not say how it made them (resample through the chain into one space, or take them from the pair Templates). Do we produce per-timepoint images?
9. **Cohort bias.** The slides list "May introduce cohort biases" [S2 p. 36]. S1 models cohort as a fixed effect. What does the validation plan check for this?
