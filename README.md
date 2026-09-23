# THISULINK — Multimodal Diabetic Complication Screening Platform

<p align="center">
  <img src="https://img.shields.io/badge/SIH%202026-%20-orange?style=for-the-badge" alt="SIH 2026"/>
  <img src="https://img.shields.io/badge/Domain-MedTech%20%26%20BioTech-red?style=for-the-badge" alt="Domain"/>
</p>

<p align="center">
  <b>AI-driven daily vital monitoring. Three modalities. One triage colour.</b><br/>
  Designed for community health worker delivery in rural India.
</p>

---

## What is THISULINK?

THISULINK is a multimodal diabetic complication early-detection system built for **Smart India Hackathon 2026**. It addresses two of the most common — and most preventable — complications of diabetes:

| Complication | Leading cause of | THISULINK detection method |
|---|---|---|
| **Diabetic foot / peripheral neuropathy** | Lower-limb amputation | Plantar shear-wave elastography (SWE) via custom VCA probe |
| **Diabetic retinopathy** | Preventable blindness | AI fundus grading (EfficientNet-B0, APTOS 2019, AUC 0.976) |

Both are screened continuously by the patient at home with daily AI reminders, supported by community health workers (ASHA, VHN, ANM, CHO) who are alerted only when triage turns Orange or Red. The system tracks **blood pressure** and **blood glucose** in a single handheld device. All data flows to a **4-tier triage engine** (🟢 Green / 🟡 Yellow / 🟠 Orange / 🔴 Red) running on a self-hosted PocketBase server at `thisulink.xyz`.

> [!IMPORTANT]
> All outputs are **research and screening-assistance results**. 

---

## Platform at a glance

```
Patient (home — self-monitoring with AI daily reminders)
│
├─ Every day ──► AI reminder → BP + Glucose reading (THISULINK-VM device)
│                ├─ PPG waveform → SBP / DBP (cuffless, XGBoost on ESP32-S3)
│                └─ Electrochemical strip → Blood glucose (mg/dL)
│
├─ When available ──► THISULINK Foot Probe (VCA + dual ADXL355 + thermometer)
│                     ├─ 10–300 Hz sweep → c_s → E (kPa) → Tissue class A/B/C
│                     └─ Contact thermometry → ΔT °C → flag if ≥ 2.2°C
│
├─ Periodic ──► Smartphone fundus photo → EfficientNet-B0 → DR grade 0–4
│
└─ All channels → BLE → Flutter app → PocketBase (thisulink.xyz)
                                            │
                               Triage engine (PocketBase JS hook)
                                            │
                    🟢 Green / 🟡 Yellow → patient self-manages
                    🟠 Orange → ASHA / VHN / ANM alerted
                    🔴 Red   → Health Worker + PHC Medical Officer alerted
```

**Community health workers** (ASHA, VHN, ANM, CHO) are alerted **only when triage turns Orange or Red**. No fixed visit schedule — visit happens when the data says it's needed.

**AI reminder system** (no FCM): WorkManager + BGTaskScheduler check daily whether BP and glucose have been recorded. Unacknowledged reminders after 4 hours trigger a health worker relay alert.


---

## Repository map

| Folder | What it contains | Key file |
|---|---|---|
| [`platform matlab simulation and proofs/`](platform%20matlab%20simulation%20and%20proofs/) | 12 MATLAB simulation experiments proving SWE physics — Kelvin-Voigt model, dual-pickup phase delay, shear-wave dispersion, tremor suppression, 120-patient triage cohort | [`README.md`](platform%20matlab%20simulation%20and%20proofs/README.md) |
| [`Clinical_Datasets_and_Parameter_Conversion/`](Clinical_Datasets_and_Parameter_Conversion/) | Literature provenance for all physical constants (ρ, c_s, ΔT threshold) and 5-step mechanical-to-clinical conversion pipeline | [`README.md`](Clinical_Datasets_and_Parameter_Conversion/README.md) |
| [`retinal-screening/`](retinal-screening/) | EfficientNet-B0 retinal DR grading module — APTOS 2019 results, research protocol, evaluation contract, all figures | [`README.md`](retinal-screening/README.md) |
| [`vitals-monitor/`](vitals-monitor/) | Cuffless BP + blood glucose in one ESP32-S3 handheld — PPG/IMU/XGBoost pipeline, electrochemical strip AFE, BLE packet spec | [`README.md`](vitals-monitor/README.md) |
| [`hardware/`](hardware/) | THISULINK foot probe BOM and PCB spec — VCA actuator, dual ADXL355, HX711 load cell, contact thermometer, Velcro stabilisation | [`README.md`](hardware/README.md) |
| [`firmware/`](firmware/) | ESP32-S3 + ADXL345 Arduino firmware POC — ring buffer, IIR biquad DSP, radix-2 FFT, feature extraction | [`README.md`](firmware/thisulink-esp32s3-adxl345/arduino/thisulink_firmware/README.md) |
| [`software/`](software/) | Flutter app architecture — dual-role (ASHA worker + Mentor), BLE probe connect, AI vital reminder system, 5-tab shell | [`README.md`](software/README.md) |
| [`backend/`](backend/) | Self-hosted infra — Cloudflare Tunnel + Tailscale + PocketBase + Node.js/Express — full deployment guide | [`README.md`](backend/README.md) |

---

## Key results (measured, not claimed)

### Retinal DR grading — EfficientNet-B0 on APTOS 2019 (677 held-out test images)

| Metric | Result | 95% CI |
|---|---|---|
| Quadratic weighted kappa | **0.860** | 0.828 – 0.888 |
| 5-grade accuracy | **76.7%** | 73.6 – 79.6% |
| Referable DR: ROC-AUC | **0.976** | — |
| Referable DR: specificity | **96.3%** | 94.4 – 98.0% |
| Calibration error (ECE) | **0.046** | — |

### Plantar SWE — MATLAB simulation (12 experiments)

| Result | Value | Experiment |
|---|---|---|
| Shear-wave speed reconstruction error | < 5% RMSE | Exp 10 |
| Tissue class separation (A/B/C) | E: 43.5 / 96 / 204 kPa | Exp 02 |
| Tremor attenuation (Velcro + flexure, 0–5 Hz) | ≥ 97.5% | Exp 11 |
| 120-patient triage cohort (E + ΔT multimodal) | 4-tier classification | Exp 12 |

### Hardware (THISULINK foot probe)

| Parameter | Value |
|---|---|
| VCA drive force | 0.100 N, 10–300 Hz sweep |
| Load cell interlock | 1.40 – 1.60 N acceptance window |
| Dual ADXL355 separation | Δx = 40 mm (x₁=105 mm, x₂=145 mm) |
| Thermometry threshold | ΔT ≥ 2.2°C (Armstrong & Lavery, *Diabetes Care* 1997) |

---

## Technology stack

| Layer | Technology |
|---|---|
| Mobile app | Flutter 3.19+, Riverpod 2, go_router 14, fl_chart |
| BLE | flutter_blue_plus — 73-byte probe packet |
| AI (retinal, on-device) | EfficientNet-B0 ONNX INT8 via onnxruntime-android |
| AI (vitals) | XGBoost int8 via m2cgen → bare-metal ESP32-S3 |
| AI (clinical assistant) | llama-3.3-70b-versatile via Groq (supervised routing) |
| Backend | PocketBase (auth, DB, files, realtime, JS hooks) |
| Infrastructure | Cloudflare Tunnel + Tailscale + Node.js/Express |
| Notifications | WorkManager + BGTaskScheduler — no FCM, no push cloud |
| Probe MCU | ESP32-S3 + dual ADXL355 + HX711 + VCA driver |
| MATLAB simulation | 12 experiments, Kelvin-Voigt ODE, shear-wave propagation |

---

## Community health worker roles

India's NPCDCS programme does not mandate fixed monthly visits for every diabetic patient. THISULINK is designed around this reality — health workers are alerted **when the data demands it**, not on a calendar.

| Role | Full name | Triggered when |
|---|---|---|
| **ASHA** | Accredited Social Health Activist | 🟠 Orange / 🔴 Red triage or 4-hr unacknowledged reminder |
| **VHN** | Village Health Nurse (Tamil Nadu) | 🟠 Orange / 🔴 Red — doorstep visit |
| **ANM** | Auxiliary Nurse Midwife | Sub-centre follow-up for flagged patients |
| **CHO** | Community Health Officer | Health & Wellness Centre review |
| **MO** | Medical Officer at PHC | 🔴 Red — emergency referral pathway |

---

## Triage logic (PocketBase JS hook)

| Colour | Condition |
|---|---|
| 🔴 Red | Tissue class C **or** (referable DR + grade ≥ 3) **or** glucose > 400 mg/dL **or** SBP > 180 |
| 🟠 Orange | (Class B + ΔT ≥ 2.2°C) **or** referable DR **or** glucose > 300 **or** SBP > 140 |
| 🟡 Yellow | Class B **or** ΔT ≥ 2.2°C **or** DR grade ≥ 2 **or** glucose > 180 **or** SBP > 130 |
| 🟢 Green | None of the above |

---

## Deployment

```bash
# Self-hosted on a Linux laptop, exposed via Cloudflare Tunnel
# No cloud VM, no open ports, no static IP required

# 1. PocketBase at thisulink.xyz (direct)
# 2. Express API at api.thisulink.xyz (ONNX retinal grading)
# 3. Tailscale for SSH and admin panel access

# Health check
curl https://api.thisulink.xyz/api/health
```

Full deployment guide → [`backend/README.md`](backend/README.md)

---

## Safety statement

This system is a **research and screening-assistance prototype**. It is not a certified medical device. All outputs (triage colours, DR grades, BP estimates, glucose readings) are research results that a qualified clinician must review before any clinical decision is made. The platform is not approved by CDSCO, FDA, or CE for diagnostic use.

---

## References

| Reference | Used for |
|---|---|
| Armstrong & Lavery, *Diabetes Care* 1997 | Thermometry threshold ΔT ≥ 2.2°C |
| Raman et al., *Indian J Ophthalmol* 2019 | Referable DR = ICDR grade ≥ 2 (Indian consensus) |
| APTOS 2019, Aravind Eye Hospital, Kaggle | Retinal training dataset (3,385 images) |
| PubMed PMID 40030275 | PPG-only cuffless BP — 25-study systematic review |
| FDA Draft Guidance, January 2026 | Cuffless BP clinical performance testing requirements |
| WHO South-East Asia DR Report | Rural screening motivation |

---

## License

MIT — see [`LICENSE`](LICENSE)

---

<p align="center">
  Built for <b>Smart India Hackathon 2026</b> — Healthcare &amp; BioMedical Track<br/>
  <a href="https://thisulink.xyz">thisulink.xyz</a> · <a href="https://github.com/thisulink/thisulink">github.com/thisulink/thisulink</a>
</p>
