# THISULINK™ — Enterprise Diabetic Complication Screening & Tele-Triage Platform

THISULINK™ is a closed-loop clinical network for diabetic complication
screening. It connects routine home monitoring, frontline point-of-care
diagnostics and specialist tele-consultation into one continuous pathway, with
an automated four-tier triage engine deciding where scarce clinical attention
goes.

The platform screens for the two complications that cause the most avoidable
harm and are the least visible on examination: **diabetic foot ulceration**,
detected through plantar shear-wave elastography and contralateral
thermography, and **diabetic retinopathy**, detected through non-mydriatic
fundus imaging with on-device AI grading.

**Status: deployed and operational**, with a hardened backend, verified
role-based access control and an end-to-end validated triage loop.

---

## 1. System architecture

```
 ┌──────────────────────────── TIER 1 · HOME ───────────────────────────────┐
 │  Patient Health Companion                                                │
 │  COTS BP cuff (0x1810) · glucometer (0x1808) · adherence · AI diet       │
 └────────────────────────────────┬─────────────────────────────────────────┘
                                  │ daily vitals
                                  ▼
 ┌──────────────────────── TIER 2 · POINT OF CARE ──────────────────────────┐
 │  Clinical Diagnostic Suite — community health worker                     │
 │                                                                          │
 │   Plantar probe (BLE 0xFFE0)        20D retinal adapter                  │
 │   • VCA 10–300 Hz sweep             • non-mydriatic, 60 s                │
 │   • dual ADXL355, Δx = 40 mm        • EfficientNet-B0 INT8 on-device     │
 │   • TAL221 interlock 1.40–1.60 N    • ICDR grade 0–4                     │
 │   • MLX90621 16×4 FIR, ΔT ≥ 2.2 °C                                       │
 │                                                                          │
 │   Offline-first · encrypted local store · queue and retry                │
 └────────────────────────────────┬─────────────────────────────────────────┘
                                  │ encounter upload
                                  ▼
 ┌──────────────────────── TIER 3 · CLOUD ENGINE ───────────────────────────┐
 │  PocketBase enterprise core — https://pb.thisulink.xyz                   │
 │                                                                          │
 │   Authentication & zero-trust RBAC   Automated triage engine             │
 │   Realtime event bus (SSE)           Immutable audit trail               │
 │   Clinical file storage              Escalation dispatch                 │
 └────────────────────────────────┬─────────────────────────────────────────┘
                                  │ realtime, risk-ranked
                                  ▼
 ┌──────────────────────── TIER 4 · SPECIALIST ─────────────────────────────┐
 │  Clinical Workstation — https://thisulink.xyz                            │
 │                                                                          │
 │   🔴 Critical → 🟠 Priority → 🟡 Moderate → 🟢 Stable                     │
 │   Waveform & FFT review · fundus grading & override                      │
 │   Signed prescriptions · diet approval · LiveKit consultation            │
 └──────────────────────────────────────────────────────────────────────────┘
```

The loop closes: every reading triggers a server-side triage recomputation,
which updates the patient's tier, writes an audit row, and — on escalation into
a priority tier — dispatches an alert back to the health worker in the field.

---

## 2. Production endpoints

| Endpoint | Serves | TLS | Status |
|---|---|---|---|
| **https://thisulink.xyz** | Specialist Clinical Workstation | Cloudflare edge | **200** |
| **https://doctor.thisulink.xyz** | Workstation, named ingress | Cloudflare edge | **200** |
| **https://pb.thisulink.xyz** | Backend REST + realtime gateway | Cloudflare edge | **200** |
| `https://pb.thisulink.xyz/_/` | Administration console | — | **404 — blocked at edge** |
| `http://<tailscale-ip>:8090/_/` | Administration console | Private mesh | Mesh only |

### Edge security rules

| Rule | Enforcement |
|---|---|
| `/_/*` returns 404 publicly | Reverse proxy at the origin |
| `/api/admins` returns 404 publicly | Reverse proxy at the origin |
| No inbound ports on the origin | Outbound-initiated Cloudflare tunnel |
| Default-deny firewall | Mesh interface and SSH only |
| Administration access | Private Tailscale mesh exclusively |

Full topology and operations: **[backend/INFRASTRUCTURE.md](backend/INFRASTRUCTURE.md)**

---

## 3. Access credentials

| Role | Endpoint | Email | Password |
|---|---|---|---|
| **Physician** | https://thisulink.xyz | `doctor@thisulink.xyz` | `Doctor@Thisu2026` |
| **Health worker** | Clinical Diagnostic Suite (Android) | `healthworker@thisulink.xyz` | `Worker@Thisu2026` |
| **Patient** | Health Companion *(roadmap)* | `patient@thisulink.xyz` | `Patient@Thisu2026` |
| **Administrator** | `http://<tailscale-ip>:8090/_/` | `admin@thisulink.xyz` | `AdminSecure#2026` |

**Patient ABHA:** `9145-2388-9100-21`

> The administration console is unreachable from the public internet by design.
> Rotate every credential above before any deployment carrying real patient
> data — they are published here for evaluation.

### Verified access isolation

| Account | patients | plantar | vitals | retinal |
|---|---|---|---|---|
| `doctor` | 4 | 24 | 24 | 4 |
| `health_worker` | 4 | 24 | 24 | 4 |
| **`patient`** | **0** | **0** | **0** | **0** |

---

## 4. Documentation index

| # | Document | Subsystem |
|---|---|---|
| 1 | **This file** | Master architecture & deployment directory |
| 2 | [hardware/README.md](hardware/README.md) | Foot platform — actuator, interlock, sensor geometry, thermal array |
| 3 | [hardware/BLE_SPECIFICATION.md](hardware/BLE_SPECIFICATION.md) | 73-byte telemetry contract, GATT profile, CRC |
| 4 | [vitals-monitor/README.md](vitals-monitor/README.md) | COTS BLE vitals — `0x1810` / `0x1808` |
| 5 | [retinal-screening/README.md](retinal-screening/README.md) | 20D adapter, quality gate, edge AI pipeline |
| 6 | [software/README.md](software/README.md) | Cross-platform client architecture |
| 7 | [software/daq-dashboard/README.md](software/daq-dashboard/README.md) | Frontline screening suite |
| 8 | [software/patient-app/README.md](software/patient-app/README.md) | Patient companion & daily compliance |
| 9 | [doctor-portal/README.md](doctor-portal/README.md) | Specialist workstation & triage workflows |
| 10 | [backend/README.md](backend/README.md) | Schema, RBAC, event engine |
| 11 | [backend/INFRASTRUCTURE.md](backend/INFRASTRUCTURE.md) | Tunnel, mesh, edge operations |
| 12 | [prototype-outputs/README.md](prototype-outputs/README.md) | Screen-by-screen prototype outputs & verification gallery |
| 13 | [firmware/README.md](firmware/README.md) | Embedded MCU firmware architecture (ESP32-S3 + DSP pipeline) |
| 14 | [platform matlab simulation and proofs/README.md](platform%20matlab%20simulation%20and%20proofs/README.md) | Plantar SWE simulation suite & mathematical proofs (12 experiments) |
| 15 | [Clinical_Datasets_and_Parameter_Conversion/README.md](Clinical_Datasets_and_Parameter_Conversion/README.md) | Clinical data sourcing, Kelvin-Voigt physics & parameter conversion |

### Specification ↔ source

The documentation tree is organised by **subsystem**; the source tree is
organised by **build artefact**. They map as follows:

| Specification | Implementation |
|---|---|
| `software/daq-dashboard/` | `thisulink_app` (Flutter, Android client) |
| `doctor-portal/` | `doctor_portal` (Flutter, Web workstation) |
| `backend/` | [`deploy/`](deploy/) — provisioning, schema, automation |
| `hardware/`, `vitals-monitor/`, `retinal-screening/` | Hardware & clinical telemetry contracts |

---

## 5. Resolved specification conflicts

Four conflicts across earlier drafts are closed. These resolutions are binding.

| # | Conflict | Resolution |
|---|---|---|
| 1 | **BLE frame header** | **`0x5448`** (ASCII `"TH"`). The draft value `0xDA 0x7A` is **permanently deprecated** and must not appear in firmware, clients, fixtures or documentation. |
| 2 | **Blood pressure sensing** | **COTS oscillometric devices** over Bluetooth SIG `0x1810`, ISO 81060-2 validated. The cuffless optical PPG model is **removed** — it has no accepted validation standard and fails by returning a plausible wrong number. |
| 3 | **Thermal sensing** | **Melexis MLX90621**, 16 × 4 = 64-pixel FIR array. Alert on contralateral asymmetry **ΔT ≥ 2.2 °C** (Lavery et al., 2007). |
| 4 | **Authorisation model** | **Explicit allowlist** on `@request.auth.role`. Negative exclusion rules are prohibited — see below. |

### Why the authorisation model is a resolution, not a preference

A negative exclusion (`role != "patient"`) evaluates **true** when `role` is
absent. During production verification this admitted every authenticated
account to every clinical collection, because a schema defect meant no account
had a role at all. A patient account could read all 24 plantar records, 24
vitals, 4 fundus evaluations and 8 triage results.

An allowlist denies the same account. The two forms behave **oppositely**
under exactly the condition nobody writes a test for. Full incident analysis:
[backend/README.md §4.1](backend/README.md).

---

## 6. Clinical triage specification

| Tier | Condition — first match wins | Action |
|---|---|---|
| 🔴 **RED** | Tissue class C, **or** P(referable) ≥ 0.50 with ICDR ≥ 3, **or** glucose > 400 mg/dL | Refer urgently |
| 🟠 **ORANGE** | Class B with ΔT ≥ 2.2 °C, **or** P(referable) ≥ 0.50, **or** glucose > 300 | Escalate to specialist |
| 🟡 **YELLOW** | Class B, **or** ΔT ≥ 2.2 °C, **or** ICDR ≥ 2, **or** glucose > 180 | Monitor, recheck next cycle |
| 🟢 **GREEN** | None of the above | No action |

### Clinical constants

| Constant | Value | Governs |
|---|---|---|
| Preload interlock | **1.40 – 1.60 N** | Scan validity |
| Thermal asymmetry alert | **ΔT ≥ 2.2 °C** | Ulcer-risk escalation |
| Referable DR threshold | **P ≥ 0.50** | Retinal escalation |
| Excitation sweep | **10 – 300 Hz** | Shear-wave acquisition |
| Pickup baseline | **Δx = 40 mm** (x₁ 105 mm, x₂ 145 mm) | Phase velocity |
| Screening cycle | **6 days** | Fundus on days 1 and 4 |
| Relay escalation | **4 hours** | Unacknowledged priority tier |

---

## 7. Verification status

### Verified against the live deployment

| Check | Result |
|---|---|
| Static analysis — both shipped clients | Clean |
| Automated tests — field client | **63 passing** |
| Schema provisioning | 8 collections, rules confirmed in database |
| **Role-based access isolation** | **Verified — patient sees zero clinical records** |
| **Triage engine, end to end** | **Correct tier for every patient** |
| **Escalation dispatch** | **Alert raised on tier entry with clinical reasoning** |
| Administration console exposure | 404 public, mesh-only |
| Public endpoints | 3 hostnames serving |

### Verified tier assignment

| Patient | Tissue | ΔT | Glucose | ICDR | Tier |
|---|---|---|---|---|---|
| Meena Devi | C | 2.7 °C | 262 | 4 | 🔴 RED |
| Saravanan S | B | 2.4 °C | 216 | 2 | 🟠 ORANGE |
| Ravi Kumar | B | 1.9 °C | 168 | 1 | 🟡 YELLOW |
| Arjun Prakash | A | 1.2 °C | 138 | 0 | 🟢 GREEN |

### Outstanding before clinical use

| Item | Status |
|---|---|
| **Probe firmware validation** | Decoder byte-exact and tested; never run against physical hardware |
| **Retinal model asset** | Inference pipeline implemented; trained INT8 model not bundled |
| **Retinal image quality gate** | Not implemented — required before grading is trusted |
| **Tele-consultation token service** | Not deployed; consultations cannot start |
| **Patient Health Companion** | Not implemented; backend role and record are live |
| **Database backups** | **Not configured** |
| **Redundancy** | **Single node** |

---

## 8. Quickstart

### Backend

```bash
curl -s https://pb.thisulink.xyz/api/health
sudo systemctl status thisulink-pocketbase
```

### Specialist Clinical Workstation

```bash
cd doctor_portal
flutter pub get && cp .env.example .env
flutter run -d chrome --web-port=8080
flutter build web --release
```

### Clinical Diagnostic Suite

```bash
cd thisulink_app
flutter pub get
dart run build_runner build
flutter run                           # live backend
flutter run --dart-define=DEMO=true   # seeded, no backend required
flutter test                          # 63 tests
```

### Provisioning a new node

```bash
sudo ./deploy/bootstrap.sh --purge-existing --apply-ingress
sudo ./deploy/finish.sh
sudo ./deploy/seed.sh
./deploy/verify.sh
```

---

## 9. Regulatory positioning

THISULINK™ is **clinical decision support**. It stratifies risk and presents
evidence; a licensed clinician makes every clinical decision. That boundary is
enforced in the product — the intended-use notice is present on every page of
the workstation, physician override supersedes every AI output, and no tier is
communicated to a patient without a clinician.

Documentation is structured for **IEC 62304** alignment: each subsystem carries
a controlled specification, interfaces are contract-specified before
implementation, and verification status is stated per component rather than in
aggregate.

---

<div align="center">

**THISULINK™** · Clinical decision support for diabetic complication screening
Screening outputs are authorised by a licensed clinician.

</div>
