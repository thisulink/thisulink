# THISULINK — Multimodal Diabetic Complication Screening: Research Protocol

**Document status:** Preregistered development protocol and final-report template.  
**System version:** THISULINK v1 (SIH 2026 Grand Finale).  
**Evidence status:** Plantar SWE results are from MATLAB simulation (experiments 01–12, 120-patient synthetic cohort). Retinal DR results are from APTOS 2019 internal evaluation. Every empirical field is `Measured (M)` or `Not measured (NM)` as indicated.

---

## 1. Abstract

THISULINK is a multimodal diabetic complication screening platform designed for rural Indian primary care and ASHA-worker delivery. It integrates three complementary screening channels — **Plantar Shear-Wave Elastography (SWE)**, **contact thermometry**, and **retinal fundus DR grading** — and fuses their outputs into a single **4-tier triage colour** (Green / Yellow / Orange / Red) for each 6-day screening cycle.

The central claims to test — not assume:
1. Dual-pickup SWE can classify plantar tissue into three pathological stages (Healthy / Early Glycation / Diabetic Neuropathy) with Young's modulus reconstruction error < 5%.
2. The multimodal fusion triage outperforms any single modality alone on the 120-patient synthetic cohort (Experiment 12).
3. The EfficientNet-B0 retinal module achieves QWK ≥ 0.85 and referable-DR AUC ≥ 0.97 on the APTOS 2019 internal test split.
4. On-device ONNX INT8 inference matches server-side FP32 inference within ±0.01 on all grade probabilities (parity gate).

The current deliverable is reproducible software + MATLAB simulation suite + a protocol. Clinical validation on real patients is the next milestone.

---

## 2. Problem Definition

For each 6-day screening cycle, the THISULINK system must produce:

| Output | Source | Threshold / scale |
|---|---|---|
| **Plantar tissue class** | SWE module (VCA + dual ADXL355) | A (Healthy) / B (Early Glycation) / C (Diabetic Neuropathy) |
| **Young's modulus E** | SWE reconstruction | kPa (target: A ≤ 50, B 51–150, C > 150) |
| **Shear-wave speed c_s** | Dual-pickup phase delay | m/s (A: 3.2–4.2, B: 4.2–6.5, C: 6.5–9.5) |
| **Thermometry flag** | Contact thermometer | ΔT ≥ 2.2 °C = positive (Armstrong & Lavery, *Diabetes Care*) |
| **DR grade** | Retinal module (EfficientNet-B0) | ICDR 0–4 |
| **Referable DR probability** | Retinal module | 0.0–1.0; referable = grade ≥ 2 |
| **4-tier triage colour** | Fusion engine (clinic server) | Green / Yellow / Orange / Red |

**Referable DR = ICDR grade ≥ 2 (Moderate NPDR or worse)**, following the Indian consensus screening definition. DME requires a separately validated endpoint and is not inferred from the DR grade alone.

---

## 3. Clinical Motivation

### Diabetic foot and plantar tissue
Peripheral neuropathy in diabetes causes progressive plantar tissue stiffening. The THISULINK VCA probe delivers a calibrated shear-wave sweep (10–300 Hz) and reconstructs tissue stiffness via dual ADXL355 pickups at 105 mm and 145 mm from the actuator. Thermometry adds a complementary vascular channel: a plantar temperature asymmetry ≥ 2.2 °C predicts ulceration risk with reported sensitivity ~97% and specificity ~68% (Armstrong & Lavery, *Diabetes Care* 1997).

### Diabetic retinopathy
The ICDR scale separates No DR, Mild NPDR (microaneurysms only), Moderate NPDR, Severe NPDR, and PDR. The Indian consensus (Raman et al., *Indian J Ophthalmol*) considers No DR / Mild NPDR non-referable and Moderate NPDR or worse referable, with urgent pathways for Severe NPDR / PDR and DME. The WHO South-East Asia report identifies trained primary-level screening and clear referral routes as central needs in the rural context.

### ASHA-worker delivery
THISULINK is designed for ASHA (Accredited Social Health Activist) delivery: the ASHA worker carries the foot probe to the patient's home, guides the 6-day measurement cycle, and receives relay alerts when patients miss vitals or when a triage result escalates. No cloud messaging (FCM) is used — all notifications run on-device via WorkManager (Android) and BGTaskScheduler (iOS).

**References:** [Indian consensus](https://pmc.ncbi.nlm.nih.gov/articles/PMC7942107/), [WHO South-East Asia](https://www.who.int/publications/i/item/9789290227946), [Armstrong & Lavery 1997](https://doi.org/10.2337/diacare.20.6.855).

---

## 4. Dataset Analysis

| Source | Modality | Role | Available reference standard | Critical caveat |
|---|---|---|---|---|
| THISULINK MATLAB Simulation Suite (Exp 01–12) | Plantar SWE | Primary SWE development and proof | Synthetic ground truth from Kelvin-Voigt model; 120-patient synthetic cohort (Exp 12) | Simulation only — no real patient plantar SWE data yet |
| APTOS 2019 (Kaggle) | Retinal DR | Retinal development, validation, test | Five DR grades 0–4 from Aravind Eye Hospital clinicians | No patient IDs in competition CSV; image-level split limitation must be reported |
| IDRiD | Retinal DR | Indian external grade test; lesion evaluation | 516 grade/DME images; 81 pixel-annotated lesion images | Do not turn missing lesion masks into negative masks |
| Armstrong & Lavery (*Diabetes Care* 1997) | Thermometry | Thermometry threshold provenance | ΔT ≥ 2.2 °C clinical threshold | Single-site RCT; prospective validation needed |
| Messidor-2 | Retinal DR | Acquisition-domain external robustness | 874 two-eye examinations | Labels require separately recorded third-party provenance; research/education use only |

---

## 5. Data Governance and Leakage Prevention

### Plantar SWE
All SWE simulation results are generated from the `simulation_parameters.m` master constants file. Ground-truth tissue classes are defined by the simulation parameters (k, μ, c_s, E) — there is no patient data. Simulation code is version-controlled in `platform matlab simulation and proofs/` and `DIA-TISSUE-MATLAB-SIMULATION/` on the THISULINK GitHub repository.

### Retinal
The canonical manifest records: source dataset, image ID/path, grade, pseudonymous patient/examination group, eye, annotation provenance, split, SHA-256 and dHash fingerprints. Split generation uses stratified sampling with a fixed seed (20260904). Augmentation is loader-only. Fitted preprocessing (temperature scaling, referral threshold) uses the calibration partition, which is independent of test and external data. The data contract is in `docs/DATA_CONTRACT.md`.

### Fusion triage
Triage thresholds (Green/Yellow/Orange/Red cutoffs) are fitted on the calibration split only and never on the external or test partitions.

---

## 6. THISULINK Hardware Parameters (SWE Module)

All simulation experiments use these calibrated constants:

| Parameter | Value | Source |
|---|---|---|
| VCA moving mass | m = 0.045 kg | THISULINK probe spec |
| VCA drive force | F₀ = 0.100 N | THISULINK probe spec |
| Frequency sweep | 10–300 Hz | Experiment 03 |
| Load cell interlock | 1.50 ± 0.10 N (1.40–1.60 N) | Experiment 08 |
| ADXL355 pickup 1 | x₁ = 105 mm from actuator | THISULINK probe spec |
| ADXL355 pickup 2 | x₂ = 145 mm from actuator | THISULINK probe spec |
| Pickup separation | Δx = 40 mm | Derived |
| ADC resolution | 20-bit, ±2.048 g | ADXL355 datasheet |
| Noise floor | 25 μg/√Hz | ADXL355 datasheet |
| Velcro strap stiffness | k_strap = 12,000 N/m | Experiment 11 |
| Lateral flexure stiffness | k_lat = 7,500 N/m | Experiment 11 |
| Tremor attenuation | ≥ 97.5% (0–5 Hz band) | Experiment 11 |

### Tissue classes

| Class | Label | k (N/m) | μ (kPa) | c_s (m/s) | E (kPa) |
|---|---|---|---|---|---|
| A | Healthy | 800 | 14.5 | 3.72 | 43.5 |
| B | Early Glycation | 1,500 | 32.0 | 5.52 | 96.0 |
| C | Diabetic Neuropathy | 2,600 | 68.0 | 8.05 | 204.0 |

---

## 7. THISULINK System Architecture

```text
Patient (6-day cycle)
│
├─ Day 1, Day 4 → Retinal photo (Flutter app camera) → EfficientNet-B0 → DR grade + P(referable)
│
├─ Every day → Foot placed on THISULINK probe
│              └─ VCA sweep 10–300 Hz
│                 ├─ ADXL355 x1 (105 mm)  ┐
│                 └─ ADXL355 x2 (145 mm)  ┘ → Phase delay → c_s → E → Tissue class A/B/C
│                 └─ Contact thermometer → ΔT °C → flag if ≥ 2.2 °C
│
└─ Any time → Blood glucose (manual log or CGM BLE sync)
              └─ mg/dL value stored in Flutter app

All outputs → BLE 73-byte packet → Flutter app → HTTPS → Clinic Node/Express server
                                                           └─ Fusion triage engine
                                                              └─ 4-tier colour: Green / Yellow / Orange / Red
                                                              └─ ASHA worker relay (if Orange/Red)
                                                              └─ Specialist telemedicine (if Red)
```

### BLE packet structure (73 bytes)

| Bytes | Field | Units |
|---|---|---|
| 0–1 | Packet header | `0xTH` |
| 2–3 | Packet sequence number | — |
| 4–7 | Timestamp (Unix epoch) | s |
| 8–11 | ADXL355 x1 acceleration | mg (signed 20-bit) |
| 12–15 | ADXL355 x2 acceleration | mg (signed 20-bit) |
| 16–19 | Phase delay Δφ | mrad |
| 20–23 | Reconstructed c_s | mm/s |
| 24–27 | Load cell force | mN |
| 28–31 | Thermometry ΔT | m°C |
| 32–35 | Blood glucose | mg/dL |
| 36–39 | Triage colour (last known) | enum 0–3 |
| 40–72 | Reserved / CRC | — |

---

## 8. Baseline Models

### SWE module
- **Baseline**: Kelvin-Voigt 1-DOF ODE (`common/tissue_model.m`) — single-frequency amplitude response
- **THISULINK model**: Dual-pickup shear-wave propagation with phase delay reconstruction (`common/shear_wave_propagation_model.m`) — multi-frequency dispersion curve → Young's modulus E

### Retinal module
- **Baseline**: Small CNN trained from scratch at 256 px (QWK 0.462, AUC 0.797)
- **THISULINK model**: EfficientNet-B0 ImageNet-pretrained, dual-head grade + referable (QWK 0.860, AUC 0.976)
- Additional backbones evaluated: DenseNet-121, ConvNeXt-Tiny, compact CNN — all from declared weights with license and possible retinal-data contamination recorded

---

## 9. Target Architecture (beyond current inference)

```text
fundus → quality gate ──ungradable──→ recapture guidance (THISULINK app notification)
              │ gradable
              ▼
   conservative FOV preprocessing (224×224, Lanczos)
              ▼
    EfficientNet-B0 encoder
    ├─ ordinal DR grade head (CORAL cumulative thresholds)
    ├─ referable-DR head (sigmoid, sensitivity-first threshold)
    ├─ lesion segmentation decoder (IDRiD masks — pending)
    ├─ vessel representation branch (DRIVE — pending)
    └─ calibrated probabilities → entropy + conformal set
                                ↓
              THISULINK fusion engine
              ├─ SWE tissue class input
              ├─ thermometry flag input
              ├─ glucose value input
              └─ 4-tier triage output → ASHA relay / specialist referral
```

---

## 10. Image Quality Model (Target)

The target quality gate predicts `gradable` vs `ungradable` before DR classification. Quality reason labels (blur, illumination, incomplete field, centering, artifact) require an independently sourced quality annotation protocol. Until quality labels are available:
- Proxy image statistics (brightness histogram, Laplacian variance) are diagnostic only.
- The current EfficientNet-B0 uses a quality head on the shared encoder — it does not satisfy the upstream-gate requirement.
- The THISULINK app will prompt the patient/ASHA worker to retake if the quality proxy is below threshold.

---

## 11. Retinal Anatomy Model

FOV extraction is enabled by default. Optic-disc/fovea location is learned only from IDRiD-labelled cases. Anatomy locates — not invents — evidence regions (macular, optic-disc, vascular zones). Region labels in explanation text are derived from validated geometry, not a language model.

---

## 12. Lesion Segmentation Model

Compare U-Net-family decoder, DeepLabV3+-family decoder, and compact decoder on the 81 IDRiD lesion-mask images. Outputs: microaneurysms, haemorrhages, hard exudates, soft exudates. Report per-lesion Dice/IoU, lesion-level recall/precision, and false-positive burden. Blank mask paths are excluded from the loss and metrics.

---

## 13. DR Classification Model

Grade severity is modelled as ordinal with CORAL-style cumulative thresholds and compared with the current flat softmax. Report per-class sensitivity/precision, balanced accuracy, macro/weighted F1, QWK, and confusion matrices. The referable head is trained and evaluated separately from the grade-derived mapping; disagreement is a human-review signal. H1 and the ordinal-learning claim are assessed by paired predictions on the same held-out cases.

---

## 14. Multi-task Learning

Multi-task loss masks non-annotated lesion/vessel/quality cases to avoid false-negative labels.

| Arm | Heads | Purpose |
|---|---|---|
| A | grade + referable | strong single-stage baseline |
| B | A + lesion | test lesion supervision |
| C | B + quality + vessel + anatomy | test component value |
| D | C + SWE fusion | test multimodal improvement over retinal-only |

Loss weights, missing-label handling, and which dataset supervises each task are frozen before the primary test.

---

## 15. Explainable AI

Every retained classifier is evaluated with Grad-CAM, Grad-CAM++, integrated gradients, and occlusion/deletion/insertion maps. Heatmaps are presented with colour-scale, target class, preprocessing version, and map method. Lesion masks and anatomy are evidence channels, not post-hoc decoration. The THISULINK AI assistant (llama-3.3-70b-versatile via Groq) may only receive structured `TriageOutput` fields — it cannot generate lesion statements or clinical diagnoses directly.

---

## 16. Uncertainty Estimation

Compare calibrated softmax, MC dropout, deep ensembles, and split conformal prediction under a fixed compute budget. Absent a singleton conformal set, high entropy, a failed quality gate, or contradictory grade/referable heads yields `human_review` — it is never silently resolved to a high-confidence negative. In THISULINK's workflow, `human_review` routes to the ASHA worker relay.

---

## 17. Calibration

Temperature scaling is fitted on the calibration partition only. Report NLL, Brier score, ECE, and reliability diagrams by grade, quality stratum, and dataset. Pre- and post-calibration numbers are always shown together with bootstrap CIs. A calibration model trained on APTOS is not silently transferred to an external cohort.

---

## 18. External Validation

| Dataset | Role | Allowed actions |
|---|---|---|
| APTOS 2019 | Primary development | Train, val, calibration, test — all on internal split |
| IDRiD | Indian external DR test; lesion evaluation | Grading + lesion metrics — never used for training or threshold tuning |
| Messidor-2 | Acquisition-domain robustness | Classification metrics only — label provenance must be listed in the manifest |

Never tune models, thresholds, or preprocessing on external data. Report absolute and relative performance change by dataset.

---

## 19. Rural India Robustness

Simulate blur, under/over-exposure, compression, resolution loss, FOV shift, and illumination variation on development data only. Evaluate real portable/smartphone images only after ethics/consent and site-specific validation.

THISULINK deployment test matrix:
- Low-power CPU latency (Android Arm64, INT8 ONNX)
- Offline queueing — BLE packets buffered when no HTTPS connectivity
- Encrypted local storage (AES-256)
- Intermittent sync recovery
- Multilingual ASHA worker instructions (Tamil, Hindi, English)
- Recapture guidance for poor-quality fundus photos
- Referral hand-off to ophthalmology / vascular surgery
- Operator and device subgroup results

---

## 20. Ablation Study

| # | Experiment | MATLAB ref | Data | Model | Primary metric | Status |
|---|---|---|---|---|---|---|
| 1 | Baseline plantar SWE (single pickup) | Exp 01–02 | Simulation | Kelvin-Voigt 1-DOF | Frequency response RMSE | M |
| 2 | Dual-pickup SWE, phase delay reconstruction | Exp 10 | Simulation | Shear-wave propagation model | c_s error < 5%, E RMSE | M |
| 3 | Velcro + flexure tremor suppression | Exp 11 | Simulation | Mechanical stabilisation model | Tremor attenuation ≥ 97.5% | M |
| 4 | Multimodal triage (SWE + ΔT + glucose) | Exp 12 | Synthetic 120-patient cohort | Fusion scoring | 4-tier accuracy | M |
| 5 | Load cell interlock state machine | Exp 08 | Simulation | HX711 model | Acceptance rate within 1.40–1.60 N | M |
| 6 | Retinal baseline (plain CNN) | — | APTOS 2019 | Small CNN 256 px | QWK, AUC | M (QWK 0.462, AUC 0.797) |
| 7 | Retinal EfficientNet-B0 (ImageNet) | — | APTOS 2019 | EfficientNet-B0 dual-head | QWK, AUC, ECE | M (QWK 0.860, AUC 0.976, ECE 0.046) |
| 8 | Ordinal grade head (CORAL) | — | APTOS 2019 | EfficientNet-B0 ordinal | QWK vs. flat softmax | NM |
| 9 | Image quality gate | — | APTOS + quality labels | Quality head | Unsafe-error rate | NM |
| 10 | Lesion segmentation | — | IDRiD 81 masks | U-Net decoder | Per-lesion Dice/IoU | NM |
| 11 | Vessel branch | — | DRIVE | Vessel decoder | Vessel Dice | NM |
| 12 | Lesion-aware retinal grading | — | APTOS + IDRiD | Multi-task B | QWK + lesion overlap | NM |
| 13 | Multimodal retinal + SWE fusion | — | APTOS + Simulation | Multi-task D | Joint triage accuracy | NM |
| 14 | IDRiD external validation | — | IDRiD 516 graded | Best retinal model | All primary metrics | NM |
| 15 | Messidor-2 domain shift | — | Messidor-2 | Best retinal model | Robustness metrics | NM |
| 16 | Edge inference parity (INT8 ONNX) | — | APTOS test | INT8 ONNX vs. FP32 | Max grade-probability delta | NM (target ≤ 0.01) |

---

## 21. Failure Analysis

Predefine review bins: missed referable/severe/PDR; false referral; ungradable passed through quality gate; correct grade with wrong lesion map; high-confidence error; cross-domain failure; false abstention; SWE tissue class mismatch; thermometry false positive. Two retina specialists independently review a stratified retinal sample. SWE simulation failures are reviewed against ground-truth tissue parameters.

---

## 22. Statistical Analysis

For every metric: report point estimate, 95% patient/examination-level bootstrap CI, denominator, dataset, split, and threshold. Compare models using paired bootstrap differences. Report mean ± SD across at least three fixed seeds for selected model variants. Thresholds are chosen on calibration/development data; external tests are evaluated exactly once.

---

## 23. Deployment Architecture

THISULINK offline-first edge screening:
- Encrypted local image/metadata store (AES-256, Android Keystore)
- Quality gate and INT8 ONNX retinal model on device (`onnxruntime-android`)
- SWE firmware on THISULINK probe (ESP32 + ADXL355 + HX711)
- BLE 73-byte packet → Flutter app → queue → HTTPS sync to clinic server
- Structured result + Grad-CAM thumbnail + triage colour stored in clinic DB
- ASHA worker relay notification (WorkManager, 15-min floor, no FCM)
- Clinician review and referral integration
- Audit log with model version, data manifest hash, preprocessing version
- Append-only `reports/experiment_registry.jsonl`; dashboard and model card generated from registered evidence

Edge benchmark plan: compare FP32 / FP16 / INT8 ONNX on model size, RAM, warm/cold latency, grade/referral performance, calibration, and abstention on a mid-range Android Arm64 device.

---

## 24. Limitations

- Plantar SWE results are from synthetic simulation — no real patient plantar data yet.
- APTOS 2019 lacks patient IDs — image-level split limitation must be reported.
- Smartphone fundus capture not yet validated against desktop fundus cameras.
- IDRiD lesion masks are small in number (81 images).
- DRIVE is not a DR grading source.
- Messidor-2 labels are not assumed official.
- DME / vision-threatening disease need their own reference standards.
- Thermometry threshold (Armstrong & Lavery) is from a single-site 1997 RCT.
- Saliency methods cannot establish causal clinical reasoning alone.

---

## 25. Final Results (current state)

| Modality | Metric | Result | Evidence status |
|---|---|---|---|
| Plantar SWE — E reconstruction | RMSE vs. ground truth | < 5% (simulation) | M — Experiment 10 |
| Plantar SWE — tissue class | 3-class accuracy | Simulation cohort Exp 12 | M |
| Tremor suppression | Attenuation 0–5 Hz | ≥ 97.5% | M — Experiment 11 |
| Retinal DR — QWK | 0–4 scale agreement | **0.860** (95% CI 0.828–0.888) | M — APTOS 2019 test split |
| Retinal DR — AUC (referable) | ROC-AUC | **0.976** | M — APTOS 2019 test split |
| Retinal DR — ECE | Calibration error | **0.046** | M — APTOS 2019 test split |
| Multimodal triage — IDRiD | External Indian validation | NM | Pending |
| Edge INT8 inference parity | Max delta vs. FP32 | NM | Target ≤ 0.01 |
| Smartphone camera validation | QWK on real capture | NM | Pending |

---

## 26. Conclusion

THISULINK is a credible research prototype rather than a validated clinical device. It operationalises the required evidence trail for SIH 2026 — MATLAB-proven SWE physics, APTOS-validated retinal grading, multimodal fusion architecture, and an offline-first Flutter delivery platform. The next meaningful milestones are: (1) licensed real plantar dataset for SWE validation, (2) sensitivity-first threshold tuning on the retinal calibration split, (3) IDRiD external retinal validation, and (4) edge INT8 parity tests on a real Android device.
