# THISULINK™ Clinical Diagnostic Suite — Frontline Screening

| | |
|---|---|
| **Document** | SW-DAQ-001 |
| **Operator** | Community health worker, field nurse |
| **Role** | `health_worker` |
| **Platform** | Android tablet / phone |
| **Source** | `thisulink_app/` (Android APK / tablet build) |
| **Status** | Implemented, device-verified — see §7 |

---

## 1. Purpose

The Clinical Diagnostic Suite is the data acquisition end of the platform. It
is operated by a health worker at the bedside, in a village home, or at a
screening camp — frequently with no network connectivity — and it produces a
complete screening encounter: foot biomechanics, plantar thermography, fundus
grading, vitals, and an automated triage tier.

The design constraint that shapes everything: **the operator is not a
clinician, and the network is not available.** Every interaction either
succeeds unambiguously or refuses unambiguously. There is no interpretation
asked of the operator, and no step that requires a server.

---

## 2. Patient identification

An encounter must bind to exactly one patient. Three entry paths, one outcome.

| Method | Input | Notes |
|---|---|---|
| **ABHA ID** | 14 digits | National Digital Health ID, unique index |
| **Phone number** | Mobile | Household devices may match several patients |
| **Barcode / QR** | Scanned | Printed on the patient's screening card |

```
   patient identification
            │
     ┌──────┴──────┬────────────┐
     ▼             ▼            ▼
  ABHA ID     phone number   QR scan
     │             │            │
     └──────┬──────┴────────────┘
            ▼
     local roster lookup  ◄── works offline; roster is cached
            │
     ┌──────┴───────┐
   found        not found
     │              │
     ▼              ▼
  confirm       enrol new patient
  identity      (ABHA, name, age, gender,
     │           village, diabetes type)
     └──────┬───────┘
            ▼
   open screening encounter
   • bound to patient id
   • bound to operator id
   • bound to device id
   • cycle day assigned
```

### Unique identity

`abha_id` carries a unique index. A duplicate enrolment is rejected at the
backend, not merged — two records for one person would split their longitudinal
history and show the same patient twice in the physician's queue, each with
half the evidence.

Identification and enrolment both work offline against the cached roster. A
camp in a dead zone enrols patients normally; the records reconcile on sync.

---

## 3. Acquisition workflow

Five steps, in order. Each is independently skippable — a patient may receive a
foot scan without a fundus photograph — but the triage tier is computed from
whatever was captured, and the summary states what was omitted.

### Step 1 — Probe connection

| Element | Behaviour |
|---|---|
| Discovery | Name prefix `THISULINK-PROBE` **and** advertised service `0xFFE0` |
| Connection | GATT, subscribe to telemetry characteristic `0xFFE1` |
| Tare | `TARE` command issued at rest before acquisition |
| **Live force indicator** | Continuous readout with the **1.40 – 1.60 N** window drawn as a band |

The force indicator is the single most important widget in the application. The
operator's entire job during acquisition is to hold the reading inside the
band, and the display makes that a target to hit rather than a number to
interpret.

```
   contact force

   0 N        1.40        1.60         3 N
   ├───────────┬═══════════┬────────────┤
                    ▲
                  1.52 N   ✓ in range
```

### Step 2 — Shear-wave sweep

| Parameter | Value |
|---|---|
| Sweep | 10 – 300 Hz, 200 ms |
| Telemetry | 73-byte frames, notify |
| Display | Live dual-pickup acceleration waveforms |
| Derived | Phase delay Δφ → cₛ → Young's modulus E |

Frames failing length, header or CRC validation are discarded silently.
Frames failing the **contact gate** are counted and shown:

```
   accepted 274   ·   rejected 19
```

Rejected samples are never averaged. Surfacing the count is deliberate: a probe
that is subtly misapplied produces a high rejection ratio, and the operator can
see that before accepting a scan rather than discovering it in review.

### Step 3 — Plantar thermography

| Parameter | Value |
|---|---|
| Sensor | MLX90621, 16 × 4 = 64 pixels |
| Capture | **Both feet, same session** |
| Derived | Contralateral ΔT per corresponding region |
| Alert threshold | **ΔT ≥ 2.2 °C** |

A single-foot capture cannot produce a contralateral asymmetry and is rejected.
Absolute plantar temperature is not clinically actionable; the difference
between feet, measured under identical conditions minutes apart, is.

### Step 4 — Fundus capture

| Parameter | Value |
|---|---|
| Optics | +20 D adapter, non-mydriatic |
| Eyes | Both, recorded separately |
| Quality gate | Blur, illumination, disc centring — before inference |
| Inference | On-device EfficientNet-B0 INT8 |
| Output | ICDR grade 0–4, P(referable), referable flag at grade ≥ 2 |

Scheduled on days 1 and 4 of the six-day screening cycle. Full specification:
[retinal-screening/](../../retinal-screening/README.md).

### Step 5 — Encounter summary

All captured modalities consolidated, with the automated triage tier:

```
  ┌────────────────────────────────────────────────────┐
  │  ENCOUNTER SUMMARY          Ravi Kumar · Day 2/6   │
  │  ABHA 9145-2388-9100-21                            │
  ├────────────────────────────────────────────────────┤
  │  Foot biomechanics    E 61.8 kPa   cₛ 4.62 m/s     │
  │                       Tissue class B                │
  │  Thermography         ΔT 1.9 °C    below threshold  │
  │  Blood glucose        168 mg/dL    fasting          │
  │  Retinal              not captured — due day 4      │
  ├────────────────────────────────────────────────────┤
  │            🟡  YELLOW — MODERATE                   │
  │  Tissue class B (early glycation)                  │
  ├────────────────────────────────────────────────────┤
  │  [ Save encounter ]     [ Dispatch tele-triage ]   │
  └────────────────────────────────────────────────────┘
```

The tier is computed **on-device** so it is available with no connectivity. It
is provisional: the server recomputes authoritatively on upload, and the
corrected tier returns on the next sync.

---

## 4. Tele-triage dispatch

When the encounter evaluates to 🟠 **ORANGE** or 🔴 **RED**, a dispatch action
is presented.

```
   encounter triage = ORANGE or RED
            │
            ▼
   [ Dispatch Tele-Triage Alert ]
            │
            ▼
   ┌────────────────────────────────────────┐
   │  create consultation ticket            │
   │  • patient, operator, encounter refs   │
   │  • triage tier and reason summary      │
   │  • LiveKit room reserved               │
   │  • status = scheduled                  │
   └────────────────────────────────────────┘
            │
            ▼
   PocketBase realtime event
            │
            ▼
   Specialist Workstation queue — audible and visual alert
```

### Escalation is offered, not automatic

The health worker is present with the patient and holds context the sensors do
not: whether the patient can travel, whether a relative is available, whether
there is already an appointment. Automatic dispatch on every threshold crossing
would flood the physician queue and train them to dismiss it.

A separate **automatic** escalation exists at the backend: an unacknowledged
priority tier raises a relay alert after four hours. The clinician-in-the-loop
path is the primary one; the timeout is the safety net.

---

## 5. Offline behaviour

| Operation | Offline |
|---|---|
| Patient lookup | Cached roster |
| Patient enrolment | Queued, reconciles on sync |
| Probe acquisition | Fully functional — BLE is local |
| Thermography | Fully functional |
| Fundus capture and grading | Fully functional — inference is on-device |
| Triage tier | Computed locally, provisional |
| Encounter storage | Written to encrypted local database |
| Upload | Queued, retried with backoff |
| Tele-triage dispatch | Queued; ticket created on reconnection |

The only capability requiring connectivity is the dispatch reaching a
physician. Everything clinical completes without a network.

The home screen shows a persistent count of queued encounters, so the operator
always knows how much work is not yet safely uploaded.

---

## 6. Reminder engine

Six-day screening cycles are tracked per patient, on-device.

| Property | Value |
|---|---|
| Scheduler | Platform background task, 15-minute cadence |
| Notifications | Local, on-device |
| **Push infrastructure** | **None — no FCM, no external push service** |
| Retinal schedule | Cycle days 1 and 4 |
| Escalation | Unacknowledged priority tier → relay alert after 4 hours |

Reminders are raised by the device from its own local database. The platform
carries no dependency on an external push service, which is both a privacy
property and an operational one: reminders fire in a dead zone.

---

## 7. Implementation status

| Component | Status |
|---|---|
| Patient identification, enrolment, roster cache | Implemented, device-verified |
| BLE decoder and contact gate | Implemented, 18 conformance tests |
| Acquisition workflow and live force indicator | Implemented, device-verified |
| Encounter summary and on-device triage | Implemented, device-verified |
| Offline outbox, backoff, two-way sync | Implemented, unit-tested |
| Reminder engine and relay escalation | Implemented |
| Charts — SWE trend, thermography, glucose | Implemented, device-verified |
| Role-protected routing | Implemented, verified against production |
| **Probe hardware acquisition** | **Not validated — no physical probe** |
| **Thermography capture UI** | **Sensor path not implemented** |
| **Retinal model asset** | **Not bundled** |
| **Tele-triage dispatch action** | **Not implemented** |

Eleven screens are verified on a physical Android device with seeded data.
The acquisition workflow is complete in software; what is unproven is its
behaviour against real sensors, because no probe hardware has been available.
