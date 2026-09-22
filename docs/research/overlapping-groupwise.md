# Overlapping group-wise: definition and topology

Research for [#141](https://github.com/CoBrALab/optimized_antsMultivariateTemplateConstruction/issues/141) and [#145](https://github.com/CoBrALab/optimized_antsMultivariateTemplateConstruction/issues/145), part of map [#138](https://github.com/CoBrALab/optimized_antsMultivariateTemplateConstruction/issues/138). #145 added sources S5–S8 (see "What the new sources add" and "pydpiper branches and forks").

Question: what is the Overlapping group-wise longitudinal strategy, where is it defined, and how do we re-implement it with ANTs?

Vocabulary follows `CONTEXT.md`: **Template**, **Longitudinal strategy**, **Level 1 / Level 2**. The words "atlas", "average" and "consensus average" appear only in quotes, titles, file names and the paper's `Avg(...)` notation.

## Answer in brief

- The primary source is **Szulc et al. 2015**, "4D MEMRI atlas of neonatal FVB/N mouse brain development", *NeuroImage* 118:49–62, [doi:10.1016/j.neuroimage.2015.05.029](https://doi.org/10.1016/j.neuroimage.2015.05.029) (author manuscript [PMC4554969](https://pmc.ncbi.nlm.nih.gov/articles/PMC4554969/)). The definition is in *Materials and Methods → Image Analysis → Developmental Time-Series Registration*, Fig. 2, and Eq. (1). [S1]
- The MISS 2017 slides reuse Fig. 2 of that paper. The slides are a summary of the paper, not a second source. Lerch and Friedel (MICe) are co-authors of the paper. [S1, S2]
- No code implements the strategy. pydpiper has no pipeline for it on any branch. The MICe wiki has no page for it. [S3, S4]
- Level 1: in each cohort, build one Template for each pair of adjacent timepoints. The inputs are all scans of that cohort at the two timepoints. [S1 §Developmental Time-Series Registration, Fig. 2]
- Level 2: build one Template from the last-timepoint scans of all cohorts. This Template is the common space. [S1 §Developmental Time-Series Registration, Fig. 2]
- The paper registers no Template to another Template. A subject's own scan at the shared timepoint connects two adjacent Templates. Transforms are concatenated through that scan. [S1 Eq. (1)]
- The paper computes one Jacobian determinant per scan, in Level 2 space, from the inverse of the full concatenated transform. [S1 §Developmental Time-Series Registration]
- No primary source defines separate "Level 1" and "Level 2" determinants. The slides name them, but give only one sentence each. [S2 p. 34]
- The published PDF prints the Eq. (1) typo (`T_{Avg(P9+P11)→P9}`). The typo is in the record, not in the PMC transcription. Only the reading `→P11` composes. [S5 p. 52, Eq. (1)]
- Friedel 2014 gives the nearest primary text for two kinds of determinant in a chained MICe strategy: "from a space common to all subjects, or between individual subject pairs". [S7 §4.1.5] Inference: this is the likely origin of the slides' Level 1 / Level 2 names.
- Wong 2015 is not Overlapping group-wise. It links adjacent Templates by Template-to-Template registration (the link that Szulc avoids), and it uses Gaussian-weighted, overlapping time windows to make Templates. [S6 pp. 3584–3585, 3590]
- No pydpiper branch, tag, pull-request ref or fork has code for Overlapping group-wise. No ref has a fix to Tamarack composition, symmetric links, or missing-data handling that `main` does not have. [S8]

## Sources

| ID | Source | Pin |
|----|--------|-----|
| S1 | Szulc KU, Lerch JP, Nieman BJ, Bartelle BB, Friedel M, Suero-Abreu GA, Watson C, Joyner AL, Turnbull DH. 4D MEMRI atlas of neonatal FVB/N mouse brain development. *NeuroImage* 2015;118:49–62. | [doi:10.1016/j.neuroimage.2015.05.029](https://doi.org/10.1016/j.neuroimage.2015.05.029), PMID 26037053, PMC4554969 (NIHMS696093). Text read from the PMC OAI JATS XML. |
| S2 | MICe Summer School 2017, "Longitudinal Registration" slides. | [`longitudinal_slides/MISS_Longitudinal_Registration.pdf`](https://github.com/Mouse-Imaging-Centre/summer_school2017/blob/371f5520ee01b903c2d542001bce07bc6efaf708/longitudinal_slides/MISS_Longitudinal_Registration.pdf) at `Mouse-Imaging-Centre/summer_school2017@371f552`. Page numbers are PDF pages. |
| S3 | pydpiper source code. | `Mouse-Imaging-Centre/pydpiper@04db1087f685dc54ec43253bb030efc438a2bbd8` (`main`) and all 13 remote branches. |
| S4 | MICe wiki, "Longitudinal Registration Tools". | Wayback snapshots [20240615075028](https://web.archive.org/web/20240615075028/https://wiki.mouseimaging.ca/display/MICePub/Longitudinal+Registration+Tools) and 20191118072520. The live host `wiki.mouseimaging.ca` does not resolve. |
| S5 | S1, published version (Elsevier typeset PDF). | NeuroImage 118 (2015) 49–62, local PDF `1-s2.0-S1053811915004097-main.pdf` (not in git). Page numbers are journal pages. The supplementary files (NIHMS696093 supplement 1–7; Elsevier mmc) were not retrieved: PMC and `ars.els-cdn.com` returned an HTML or XML access page. |
| S6 | Wong MD, van Eede MC, Spring S, Jevtic S, Boughner JC, Lerch JP, Henkelman RM. 4D atlas of the mouse embryo for precise morphological staging. *Development* 2015;142:3583–3591. | [doi:10.1242/dev.125872](https://doi.org/10.1242/dev.125872), local PDF `dev125872.pdf` (not in git). Page numbers are journal pages. |
| S7 | Friedel M, van Eede MC, Pipitone J, Chakravarty MM, Lerch JP. Pydpiper: a flexible toolkit for constructing novel registration pipelines. *Front. Neuroinform.* 2014;8:67. | [doi:10.3389/fninf.2014.00067](https://doi.org/10.3389/fninf.2014.00067), local PDF `fninf-08-00067.pdf` (not in git). |
| S8 | pydpiper, all refs, and its forks. | Mirror clone of `Mouse-Imaging-Centre/pydpiper` on 2026-09-22: 13 branches, 44 tags, 31 `refs/pull/*`, 1801 commits. `main` = `04db1087f685dc54ec43253bb030efc438a2bbd8`. 10 forks, compared with the GitHub compare API. |

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
- **`stage_embryos_in_4D_atlas.py`** is not related. It stages one embryo scan against an existing set of embryo reference images, one for each stage (the script calls it a "4D atlas"): it finds the stage with the closest volume, registers the scan to the stages within ±7 of that match, and scores each registration by deformation magnitude. [S3 `pydpiper/pipelines/stage_embryos_in_4D_atlas.py` docstring lines 22–62, `match_embryo_to_4D_atlas` lines 112–150]
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
4. `T_{Avg(P9+P11)→P9}`: **as printed, this term ends at P9.** The next term starts at P11. For the chain to compose, this term must be `T_{Avg(P9+P11)→P11}`. Inference: the printed "P9" is a typo for "P11". The typeset journal PDF prints the same "→P9" [S5 p. 52, Eq. (1)], so the typo is in the published record. Fig. 2 draws no P9 → P11 edge, so no other reading composes. [S5 Fig. 2]
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
  - (d) Level 1 = determinant of one adjacent hop: scan (s, t_i) → A_i → scan (s, t_{i+1}). This follows the Friedel 2014 "between individual subject pairs" kind [S7 §4.1.5] and the pydpiper Registration Chain pair stats [S8 `025455d`]. Added in #145.

### Resampling labels (subject space and common space)

- S1 draws labels on the "average P11 image" and on the "average P10+P11 image", then maps them to every scan "via inverse transforms". [S1 §Automated Time-Series Analyses: "Since all the images in the developmental time series (including the P11 images) from both the even and odd cohorts of mice were registered to the average P10+P11 image, once a region was defined in P11 space it could be mapped to each earlier time point via inverse transforms."] This is subject-space resampling through the inverse chain.
- S1 also tracks points placed on the "averaged P11 image" back through the registrations to earlier stages. [S1 §Quantitative analysis of cerebellum development, Fig. 12]
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

## What the new sources add (#145)

### Szulc et al. 2015, published PDF [S5]

- **Eq. (1).** The typeset equation is the same as the manuscript: `T_{P7→P10.5} = T_{P7→Avg(P7+P9)} ⊕ T_{Avg(P7+P9)→P9} ⊕ T_{P9→Avg(P9+P11)} ⊕ T_{Avg(P9+P11)→P9} ⊕ T_{P11→P10.5}`. [S5 p. 52, Eq. (1)] The typo is in the published record.
- **Fig. 2.** Same figure as the manuscript. Arrows go from the scans to "P1+P3 avg" … "P9+P11 avg" (odd cohort), "P2+P4 avg" … "P8+P10 avg" (even cohort), and from the P10 and P11 scans to "P10+P11 avg". The figure has no Template-to-Template arrow and no scan-to-scan arrow. [S5 p. 52, Fig. 2]
- **Methods.** The text is the same as the manuscript. "Each scan can be mapped to any other scan in the series by using appropriate forward and inverse transformations." [S5 pp. 51–52] The paper uses ANTs SyN. [S5 p. 51]
- **Per-timepoint images.** "Registration of the data was employed to generate averaged 3D MEMRI images at each stage." [S5 p. 54] Fig. 4 shows "registered and averaged images" every other day, P1 to P11. [S5 Fig. 4] For Fig. 6, "we aligned average images from each day to every other day". [S5 p. 52] The paper does not say how it made one image for each day. This does not answer Q8.
- **Supplementary material.** Not retrieved (see S5 in Sources). The text cites Suppl. Fig. 1 (body weights), Suppl. Fig. 2 (P11 and P21 brain volumes), Suppl. Fig. 3 (individual and averaged images), Suppl. Table 1 (regional growth), and Suppl. Videos 1–5 (animations of growth, DBM, folia tracking). [S5 pp. 53–56] All are results. No citation points to a method in the supplement.
- **Software.** "The registration pipelines are implemented in pydpiper (Friedel et al., 2014) (source code: https://github.com/Mouse-Imaging-Centre/pydpiper)". [S5 p. 53] S8 finds no Overlapping group-wise code there.

### Wong et al. 2015 [S6]

Wong 2015 is **not** Overlapping group-wise. The data is cross-sectional: each embryo is imaged once, at one of six ages, 8 embryos for each age. [S6 p. 3590, Sample preparation] So the paper has no subject chains and no missing-data concept. It cites Szulc 2015 only as a related study. [S6 p. 3589]

What it adds:

- **Template-to-Template links between adjacent timepoints.** First iteration: one group-wise Template for each age ("population average image of the eight randomly selected mouse embryo images"). [S6 p. 3584, Fig. 2] Second iteration: "each of these model images was registered to its adjacent time point, using source-to-target registration, in the order of increasing time". [S6 pp. 3584–3585] Methods: "Source-to-target image registrations were conducted between image models in the direction of increasing developmental time." [S6 p. 3590] This is the link that Szulc does not use. It is the Tamarack topology (one Template for each timepoint, adjacent Templates registered together). Inference: it is MICe precedent for Tamarack, not for Overlapping group-wise.
- **Adjacency limit.** Registration failed "between embryo images differing by more than half a day due to insufficient anatomical homology (data not shown)". [S6 p. 3585] This is the same reason Szulc gives for pairs of adjacent days. [S1 Fig. 6]
- **Weighted, overlapping time windows.** Third iteration: for each of 26 stages at 0.1 dpc intervals, one group-wise Template from the embryos "staged within a range of ±0.2 dpc" of that stage. "Gaussain [sic] weighted (σ=0.08 dpc) group-wise registration was performed by weighting the transforms of the pair-wise affine registration and then applying the weights to the image intensities of each corresponding embryo image when generating population average images for each non-linear iteration." [S6 p. 3585] The windows are 0.4 dpc wide with a 0.1 dpc stride, so one embryo is an input to up to four Templates. This is the only MICe source with a window wider than two timepoints. It needs a weight for each input in the affine average and in the image average. `modelbuild.sh` has no such weights (inference from `CLAUDE.md` "Pipeline Flow"; not checked in code for this ticket).
- **Time interpolation.** Displacements between adjacent Templates are fitted with cubic B-splines over time, then evaluated to make images every 0.1 dpc (second iteration) and 0.05 dpc (third iteration, 51 images). [S6 pp. 3584–3585] Outside the scope of Overlapping group-wise.
- **Validation pattern.** Re-staging the 48 input embryos with the second and third iterations: "97% drifted in stage by no more than 0.1 dpc". [S6 p. 3586] This is a self-consistency check. Inference: a similar check (do the scans stay at the same place when we rebuild) could serve Q9.
- **No determinants.** Wong 2015 computes no Jacobian determinants. Staging uses normalized cross-correlation (global) and displacement magnitude fitted with a quadratic over time (voxel-wise). [S6 pp. 3586–3587]
- **Registration.** MINC tools (6-parameter, then pairwise 12-parameter, then a six-generation non-linear registration; Collins and Evans 1997), not ANTs. [S6 p. 3590]
- **Code.** The paper gives a data URL for the 51 images (mouseimaging.ca), not code. [S6 p. 3585] `pydpiper/pipelines/stage_embryos_in_4D_atlas.py` (van Eede, first commit `d4c00bd`, 2017-10-31) stages new embryos against an existing set of images, one for each stage. It does not build that set. [S8] A search of the `Mouse-Imaging-Centre` GitHub organisation found no builder for the Wong atlas.

### Friedel et al. 2014 [S7]

Friedel 2014 has **no** Overlapping group-wise section and no Tamarack. It describes four pipelines: iterative group-wise registration, Registration Chain, two-level registration, and MAGeT. [S7 §2 p. 3, §4.2–4.5]

What it adds:

- **Adjacent timepoints and concatenation.** "it is often possible to accurately register adjacent time points together if the time-series was densely sampled (Lerch et al., Manuscript in preparation). The resulting transforms can be concatenated and used to calculate shape changes from a common coordinate space." [S7 §1 pp. 2–3] Inference: the manuscript in preparation is Szulc 2015 (Lerch is second author; Szulc 2013 is cited separately in the same sentence).
- **Two kinds of determinant in a chain.** "the transform concatenation often necessary to get the appropriate average-to-subject transform would happen in a modular way, independent of determinant calculation ... motivated in part by differences between iterative group-wise registration (section 4.2) and the registration chain (section 4.3). In the latter, deformation fields can be calculated both from a space common to all subjects, or between individual subject pairs". [S7 §4.1.5 p. 10] pydpiper implemented both: 2013 commits `025455d` ("stats are now calculated from each subject to the average time point. This is in addition to the existing calculations between pairs") and `d361f3c` (stats "from average to each other time point"). [S8] Inference: "between pairs" (a local, adjacent-hop determinant) and "from a common space" (a full-chain determinant) are the two kinds the slides later call Level 1 and Level 2. This narrows Q1.
- **Determinant recipe.** "Once a common space has been identified, the full transform from this common space back to each individual subject is used to calculate a deformation field. After smoothing and taking the Jacobian determinant of this deformation field ... we can use DBM". [S7 §4.1.5 p. 10] The worked example also computes the "pure non-linear" field (linear part removed) and blurs it before the determinant. [S7 §5 p. 14] This matches Szulc: invert the chain, then take the determinant in common space. [S1]
- **Chain direction and common timepoint.** Registration Chain registers "source (timepoint i) to target (timepoint i + 1)". "one time point is chosen as the common time point"; "Alternatively, a different timepoint could be chosen as the common space." [S7 §4.3 p. 12, Fig. 10] With Wong (increasing time) [S6] and Tamarack (compose forward, then invert after the common timepoint) [S8], every MICe chained method goes forward in time. Inference: this supports Eq. (1)'s choice of the later Template for a middle scan (Q2) as a convention. It is not a rule.
- **Nothing on** cohorts, schedules, window width, missing data, or per-timepoint images.
- **Code location.** The paper gives `https://github.com/mfriedel/pydpiper` [S7 p. 3]; this URL now returns an HTTP 301 redirect; the maintained repository is `Mouse-Imaging-Centre/pydpiper` (S8).

## pydpiper branches and forks

Findings for Overlapping group-wise, Registration Chain and Tamarack. [S8]

### Overlapping group-wise: nothing on any ref

- `git log --all` over 1801 commits (13 branches, 44 tags, 31 pull-request refs). Commit-message search for overlap, sliding, window, adjacent, embryo, 4D, P10, cohort, pair: hits are only about staging embryos, pairwise LSQ12 and MAGeT options.
- Content search (`git log --all -G`) over `*.py` for `[Oo]verlap|[Ss]liding|[Aa]djacent|[Cc]ohort|P10|[Ww]indow`: hits are the windowed-sinc interpolators, the ANTs convergence window, the server/client "overlap" comment in the executor, and the Registration Chain functions `avgToNonAdjacentTimePt` / `nonAdjacentTimePtToAvg` (2013). None builds pairs of timepoint Templates.
- `pairwise_nlin.py` (2013, `f54dc06`, removed later) registers all pairs of input images. It is not a timepoint window.
- The old layout (`applications/`, `pydpiper_apps/`) has no commits off `main` except merge commits of pull-request refs.

### Registration Chain and Tamarack: branches that differ from `main`

`develop` (`b98663009ceb`) is the same as `main` for both files. Only these refs have commits to `pydpiper/pipelines/registration_chain.py` or `registration_tamarack.py` that `main` does not have:

| Ref | Tip | What differs from `main` |
|-----|-----|--------------------------|
| `itk-conversion` | `567f06248df449e339a44f6e2082b9e42872881c` (2022-09-06) | WIP ITK port. Renames `source/target` to `moving/fixed` and calls through an `algorithms` object. Tamarack: the inter-Template registration uses the full LSQ12 protocol module. **Drops** `resampled_log_nlin_det` (commented out, line 227) and the blurred `determinants_at_fwhms`; computes only an unblurred `log_full_det` when `calc_stats` is on, with "FIXME blurring, nlin det, etc." (lines 245–250). Adds "TODO we can improve the logic here to remove the use of 'invert' by choosing which direction to go in prior based on whether we're before/after the common time point" (line 196). This is a regression in progress, not a fix. |
| `makeflow` | `a6103f051560d19e0816a34c01d413b6705ab65c` (2022-06-21) | Older state of the same WIP work (a subset of `itk-conversion`). |
| `lsq7` | `ea193fc57625f119a166dcb427ab85752a9d39bb` (2018-10-23) | One import refactor in `registration_chain.py` (`5ee651c`). The rest of the diff is `main` being newer. |
| `beast` | `7444556eecf2ef41b6a6f403cf0416fc6cd83efa` (2017-04-18) | A 2017 merge of `develop`. It predates Tamarack (first commit `4c35b5f`, 2017-11-27). |

The composition logic is the same on all refs. On `main`, Tamarack composes the adjacent Template-to-Template transforms towards the common timepoint and inverts the composed transform for groups at or after it (`registration_tamarack.py` line 181 at `04db108`). It then concatenates each scan's first-level transform with that and inverts the result for determinants (lines 212–222). It also resamples each first-level log determinant (full and non-linear) into common space (lines 194–210).

Fixes that are already on `main` (so a re-implementation should not copy the older behaviour):

- `62f4339` (2020-04-14, "registration tamarack: unbreak and install"): before this, the inter-Template non-linear registration used only the last level of the protocol ("FIXME no good can come of this"), and the overall determinants were not added to the pipeline stages (no `s.defer`).
- `dfa1b5d` (2021-01-25): simplifies the Tamarack CSV outputs.
- `4c35b5f` added Tamarack with "needs testing etc.".

**Symmetric links** (registering adjacent Templates in both directions, or to a midpoint): none on any ref. **Missing-data handling** in Chain or Tamarack: no change on any ref.

### Forks

10 forks. Compared with `main` by the GitHub compare API on each fork's default branch and on each branch that exists only in the fork.

- Ahead of upstream: `psteadman/pydpiper` `master` (+2: masks and blurs in `NLIN.py` and `minc/registration.py`), `dorkylever/pydpiper` `patch-1`..`patch-3` (+1 each: tests and `minc/registration.py`), `gdevenyi/pydpiper` `develop` (+1: `atoms_and_modules/minc_atoms.py`).
- All other fork branches are 0 commits ahead.
- No fork changes `registration_chain.py` or `registration_tamarack.py`, and no fork has Overlapping group-wise code.

## Mapping to this repository (inference)

These are notes for the spec, not findings.

- Each Level 1 Template and the Level 2 Template is one `modelbuild.sh` run. The Level 1 runs are independent and can run in parallel. The Level 2 run only needs the last-timepoint scans, so it can also run in parallel with Level 1.
- Chain composition can use `antsApplyTransforms -o [composite.nii.gz,1]` with the Level 2 Template as reference, then `CreateJacobianDeterminantImage` on the composite field. This follows S1 (compose, then take the determinant). The alternative is the `twolevel_dbm.sh` pattern: compute a determinant at one level, then resample it into the next space with the next level's transforms (`twolevel_dbm.sh`, the `resampled-dbm` block near line 250).
- The chain goes through inverse transforms (Template → scan). The spec must decide how to get them: inverse warps and inverted affines from `modelbuild.sh`, or composition in the other direction and a single inversion as in S1.
- A chain crosses up to T hops. S1 inverts the concatenated forward chain; composing many hops can accumulate interpolation error.

## Open questions for the spec

Status after #145. "Answered" means a primary source settles it. "Narrowed" or "informed" means a source helps, but the spec must still decide.

1. **Level 1 / Level 2 determinants. Narrowed.** S1 defines only one determinant per scan (full chain, Level 2 space). The slides name Level 1 and Level 2 determinants with no method. Friedel 2014 names two kinds for a chain: "from a space common to all subjects" and "between individual subject pairs" [S7 §4.1.5], and pydpiper Registration Chain computed both (`025455d`, `d361f3c`) [S8]. Add option (d) to the list in "Determinants": Level 1 = determinant of one adjacent hop (a scan to the same subject's scan at the next timepoint, through their shared Level 1 Template). Which definition do we ship (a–d)?
2. **Canonical Level 1 transform. Corroborated as convention, still a decision.** A middle scan belongs to two Level 1 Templates. S1 Eq. (1) uses the later Template (P7 → Avg(P7+P9)) [S5 Eq. (1)]. Every MICe chained method goes forward in time (Registration Chain i → i+1 [S7 §4.3]; Wong "increasing time" [S6 p. 3590]; Tamarack composes forward [S8]). No source gives a rule. Do we follow Eq. (1)?
3. **Eq. (1) typo. Answered.** The typeset PDF prints `T_{Avg(P9+P11)→P9}` [S5 p. 52], and Fig. 2 has no P9 → P11 link. Only `→P11` composes. Author confirmation is optional.
4. **More than two cohorts. Open.** No new source adds anything. The slides say "Register last timepoint in each cohort together". Is Level 2 one Template of all cohorts' last timepoints, even if these timepoints are far apart?
5. **Cohort definition. Open.** No new source adds anything (Wong 2015 has no cohorts; Friedel 2014 has no cohorts). Do we accept any cohort schedule, or must cohort timepoints interleave and end on adjacent days?
6. **Window width. Informed.** S1 uses pairs (width 2, stride 1). Wong 2015 used Gaussian-weighted windows (σ = 0.08 dpc, ±0.2 dpc, stride 0.1 dpc), with weights on the affine average and on image intensities [S6 p. 3585]. That needs per-input weights in `modelbuild.sh`. It is also a cross-sectional design, so it does not show how chains cross a wider window. Do we allow wider windows, and if so, weighted or not?
7. **Missing data. Open.** No new source adds anything. No pydpiper ref changes missing-data handling [S8]. Do we reject the input, drop the subject, or bridge the gap another way (for example with another subject's scan, or a Template-to-Template registration as in Wong 2015 and Tamarack, which S1 does not do)?
8. **Per-timepoint images. Open.** The published text says "Registration of the data was employed to generate averaged 3D MEMRI images at each stage" [S5 p. 54] and uses "average images from each day" for Fig. 6 [S5 p. 52], but does not say how it made them. The supplement was not retrieved. Do we produce per-timepoint images, and how?
9. **Cohort bias. Open, one idea.** The slides list "May introduce cohort biases" [S2 p. 36]. S1 models cohort as a fixed effect. Wong 2015 used a rebuild-and-restage self-consistency check (97% of inputs moved ≤ 0.1 dpc) [S6 p. 3586]. Inference: a similar rebuild check could be one part of the validation plan. What does the plan check?
