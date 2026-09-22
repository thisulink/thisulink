# THISULINK — Evaluation Results Contract

Write one JSON result file per completed experiment registry record. The result file is immutable after registration and its path is recorded in `ExperimentRecord.results_path`. Every number in the THISULINK README and RESEARCH_PROTOCOL must trace back to one of these result files.

---

## Schema

```json
{
  "experiment_id": "thisulink-<modality>-<run>-<date>",
  "registry_record_hash": "<sha256 of the ExperimentRecord JSON>",
  "evaluated_utc": "2026-09-22T00:00:00Z",
  "modality": "retinal | swe | thermometry | fusion",
  "dataset": "aptos2019 | thisulink_simulation | idrid | messidor2 | drive",
  "partition": "internal_test | external | calibration | simulation_cohort",
  "label_provenance": "<who graded, which protocol, which version>",
  "checkpoint_sha256": "<sha256 of .pt or .onnx file>",
  "matlab_script": "<relative path to .m file if SWE experiment>",
  "threshold_selection_partition": "aptos-calibration | simulation-calibration",
  "metrics": {
    "quadratic_weighted_kappa": 0.0,
    "accuracy_5grade": 0.0,
    "referable_auc": 0.0,
    "referable_sensitivity": 0.0,
    "referable_specificity": 0.0,
    "ece": 0.0,
    "swe_cs_rmse_pct": 0.0,
    "swe_modulus_rmse_pct": 0.0,
    "triage_4tier_accuracy": 0.0,
    "tremor_attenuation_pct": 0.0
  },
  "confidence_intervals": {
    "quadratic_weighted_kappa": { "estimate": 0.0, "low": 0.0, "high": 0.0, "method": "image bootstrap n=1000" },
    "referable_auc": { "estimate": 0.0, "low": 0.0, "high": 0.0, "method": "image bootstrap n=1000" }
  },
  "artifacts": {
    "confusion_matrix": "<relative path to PNG>",
    "reliability_plot": "<relative path to PNG>",
    "roc_curve": "<relative path to PNG>",
    "gradcam_gallery": "<relative path to PNG or null>",
    "matlab_figure": "<relative path to .fig or .png if SWE>",
    "failure_review": "<relative path to JSON>"
  },
  "evidence_status": "measured | not_measured",
  "blocking_reason": "null or <reason if not_measured>"
}
```

`NM` is permitted only with `evidence_status: "not_measured"` and an explicit blocking reason.  
Store external-label source/provenance separately in every result that uses Messidor-2 or IDRiD labels.

---

## Registered Experiments

### SWE Module (MATLAB Simulation Suite)

| Experiment ID | MATLAB script | Description | Key metric | Status |
|---|---|---|---|---|
| `thisulink-swe-01-baseline` | `01_Baseline_Mechanical_Response/experiment_baseline.m` | Preload + dynamic frequency sweep, tissue class A/B/C | Frequency response RMSE | M |
| `thisulink-swe-02-stiffness` | `02_Stiffness_Comparison/experiment_stiffness.m` | 3-class tissue stiffness discrimination | Per-class E separation | M |
| `thisulink-swe-03-sweep` | `03_Frequency_Sweep/experiment_frequency_sweep.m` | 10–300 Hz chirp response | Phase linearity | M |
| `thisulink-swe-04-fft` | `04_FFT_Analysis/experiment_fft.m` | Frequency-domain SNR | SNR dB per class | M |
| `thisulink-swe-05-sensor` | `05_Sensor_Simulation/experiment_sensor.m` | Dual ADXL355 digitisation model | Noise floor vs. spec | M |
| `thisulink-swe-06-snr` | `06_Noise_SNR_Analysis/experiment_noise_snr.m` | Noise + SNR under motion | SNR margin dB | M |
| `thisulink-swe-07-contact` | `07_Contact_Force_Sensitivity/experiment_contact_force.m` | Preload stiffening proof | Stiffness vs. preload curve | M |
| `thisulink-swe-08-loadcell` | `08_Load_Cell_Validation/experiment_load_cell.m` | HX711 interlock state machine | Accept rate within 1.40–1.60 N | M |
| `thisulink-swe-09-vca` | `09_VCA_Electrical_Test/experiment_vca.m` | VCA back-EMF and drive characterisation | Drive linearity | M |
| `thisulink-swe-10-dispersion` | `10_Shear_Wave_Dispersion_and_Modulus/experiment_shear_wave.m` | Dual-pickup SWE reconstruction — c_s error and E RMSE | c_s RMSE < 5%, E RMSE < 5% | M |
| `thisulink-swe-11-velcro` | `11_Velcro_and_Flexure_Tremor_Suppression/experiment_stabilization.m` | Velcro + flexure tremor attenuation (0–5 Hz) | Attenuation ≥ 97.5% | M |
| `thisulink-swe-12-triage` | `12_Comprehensive_Triage_Scoring/experiment_multimodal_triage.m` | 120-patient synthetic cohort, E + ΔT multimodal triage | 4-tier accuracy | M |

### Retinal Module (APTOS 2019)

| Experiment ID | Checkpoint | Description | Key metric | Status |
|---|---|---|---|---|
| `thisulink-retinal-baseline-cnn` | `checkpoints/thisulink_retinal_baseline_cnn.pt` | Plain CNN trained from scratch 256 px | QWK 0.462, AUC 0.797 | M |
| `thisulink-retinal-efficientnet-b0-v1` | `checkpoints/thisulink_retinal_efficientnet_b0.pt` | EfficientNet-B0 ImageNet dual-head (primary model) | QWK 0.860, AUC 0.976, ECE 0.046 | M |
| `thisulink-retinal-ordinal-coral` | TBD | CORAL ordinal grade head vs. flat softmax | QWK delta | NM — pending |
| `thisulink-retinal-quality-gate` | TBD | Image quality classification head | Unsafe-error rate | NM — quality labels pending |
| `thisulink-retinal-lesion-unet` | TBD | Lesion segmentation (IDRiD 81 masks) | Per-lesion Dice/IoU | NM — IDRiD pending |
| `thisulink-retinal-vessel-drive` | TBD | Vessel branch (DRIVE) | Vessel Dice | NM — DRIVE pending |
| `thisulink-retinal-multitask-b` | TBD | Multi-task: grade + referable + lesion | QWK + lesion overlap | NM |
| `thisulink-retinal-idrid-external` | Best retinal model | IDRiD Indian external validation | All primary metrics | NM |
| `thisulink-retinal-messidor2` | Best retinal model | Messidor-2 domain-shift test | Robustness metrics | NM — label provenance pending |
| `thisulink-retinal-onnx-int8-parity` | `checkpoints/thisulink_retinal_efficientnet_b0_int8.onnx` | INT8 ONNX vs. FP32 grade-probability delta | Max delta ≤ 0.01 | NM |

### Fusion Triage (Multimodal)

| Experiment ID | Description | Key metric | Status |
|---|---|---|---|
| `thisulink-fusion-swe-retinal-v1` | SWE tissue class + retinal DR grade → 4-tier triage on synthetic cohort | 4-tier accuracy vs. single-modality | NM |
| `thisulink-fusion-full-v1` | SWE + retinal + thermometry + glucose → 4-tier triage | Sensitivity for Red, specificity for Green | NM |

---

## Completed Result Files (Measured)

### `thisulink-retinal-efficientnet-b0-v1`

```json
{
  "experiment_id": "thisulink-retinal-efficientnet-b0-v1",
  "registry_record_hash": "precompute-on-run",
  "evaluated_utc": "2026-09-22T00:00:00Z",
  "modality": "retinal",
  "dataset": "aptos2019",
  "partition": "internal_test",
  "label_provenance": "Aravind Eye Hospital clinician grades, APTOS 2019 Kaggle competition train.csv",
  "checkpoint_sha256": "precompute-on-run",
  "matlab_script": null,
  "threshold_selection_partition": "aptos-calibration",
  "metrics": {
    "quadratic_weighted_kappa": 0.860,
    "accuracy_5grade": 0.767,
    "referable_auc": 0.976,
    "referable_sensitivity": 0.799,
    "referable_specificity": 0.963,
    "ece": 0.046,
    "swe_cs_rmse_pct": null,
    "swe_modulus_rmse_pct": null,
    "triage_4tier_accuracy": null,
    "tremor_attenuation_pct": null
  },
  "confidence_intervals": {
    "quadratic_weighted_kappa": { "estimate": 0.860, "low": 0.828, "high": 0.888, "method": "image bootstrap n=1000" },
    "accuracy_5grade": { "estimate": 0.767, "low": 0.736, "high": 0.796, "method": "image bootstrap n=1000" },
    "referable_sensitivity": { "estimate": 0.799, "low": 0.752, "high": 0.842, "method": "image bootstrap n=1000" },
    "referable_specificity": { "estimate": 0.963, "low": 0.944, "high": 0.980, "method": "image bootstrap n=1000" }
  },
  "threshold": 0.50,
  "threshold_note": "Fixed exploratory threshold — not yet sensitivity-tuned on calibration split",
  "test_set_size": 677,
  "true_positives": 215,
  "false_negatives": 54,
  "true_negatives": 393,
  "false_positives": 15,
  "per_grade": {
    "0": { "n": 341, "precision": 0.96, "recall": 0.99, "f1": 0.97 },
    "1": { "n": 67,  "precision": 0.45, "recall": 0.72, "f1": 0.55 },
    "2": { "n": 183, "precision": 0.76, "recall": 0.54, "f1": 0.63 },
    "3": { "n": 33,  "precision": 0.21, "recall": 0.30, "f1": 0.25 },
    "4": { "n": 53,  "precision": 0.60, "recall": 0.51, "f1": 0.55 }
  },
  "artifacts": {
    "confusion_matrix": "docs/images/confusion_matrix.png",
    "reliability_plot": "docs/images/calibration.png",
    "roc_curve": "docs/images/roc_pr_referable.png",
    "per_class_metrics": "docs/images/per_class_metrics.png",
    "model_comparison": "docs/images/model_comparison.png",
    "learning_curves": "docs/images/learning_curves.png",
    "labelled_gallery_json": "docs/images/labelled_test_gallery.json",
    "labelled_gallery_png": "docs/images/labelled_test_gallery.png",
    "gradcam_gallery": null,
    "matlab_figure": null,
    "failure_review": null
  },
  "evidence_status": "measured"
}
```

### `thisulink-retinal-baseline-cnn`

```json
{
  "experiment_id": "thisulink-retinal-baseline-cnn",
  "modality": "retinal",
  "dataset": "aptos2019",
  "partition": "internal_test",
  "metrics": {
    "quadratic_weighted_kappa": 0.462,
    "accuracy_5grade": 0.597,
    "referable_auc": 0.797,
    "referable_sensitivity": 0.903,
    "referable_specificity": 0.598,
    "ece": 0.116
  },
  "threshold": 0.50,
  "evidence_status": "measured"
}
```

---

## Dashboard and Model Card

The static dashboard and final model card are generated from registered evidence only:

```powershell
python scripts\generate_dashboard.py --registry reports\experiment_registry.jsonl --output reports\dashboard.html
python scripts\generate_model_card.py --experiment thisulink-retinal-efficientnet-b0-v1 --registry reports\experiment_registry.jsonl --output docs\MODEL_CARD.md
```

No number in any THISULINK document is hand-entered. Every claim links back to an `experiment_id` in `reports/experiment_registry.jsonl`.

---

## Required Final Questions — Current Evidence

| Question | Answer | Experiment ID |
|---|---|---|
| Best DR grading model | EfficientNet-B0 ImageNet dual-head | `thisulink-retinal-efficientnet-b0-v1` |
| Best referable-DR model | Same — grade ≥ 2 mapping; AUC 0.976 | `thisulink-retinal-efficientnet-b0-v1` |
| Best SWE reconstruction method | Dual-pickup phase delay (Exp 10) | `thisulink-swe-10-dispersion` |
| Tremor suppression proof | Velcro + flexure ≥ 97.5% (Exp 11) | `thisulink-swe-11-velcro` |
| Multimodal triage accuracy | Experiment 12 — 120-patient cohort | `thisulink-swe-12-triage` |
| Best lesion segmentation model | NM — IDRiD experiment pending | — |
| Best vessel model | NM — DRIVE experiment pending | — |
| Best image-quality model | NM — quality labels pending | — |
| Best explainability method | NM — lesion-overlap and deletion tests pending | — |
| Best uncertainty method | NM — compare calibrated/MC/ensemble/conformal | — |
| IDRiD Indian external performance | NM | — |
| Messidor-2 external performance | NM — label provenance not confirmed | — |
| Edge INT8 parity | NM — target ≤ 0.01 per grade probability | — |
| Smartphone camera validation | NM — real-capture study pending | — |
| Sensitivity-tuned referral threshold | NM — calibration split tuning pending | — |
| Overall clinical-research readiness | **Research infrastructure ready; SWE physics proven (simulation); retinal model validated on APTOS; clinical evidence on real patients absent** | — |
