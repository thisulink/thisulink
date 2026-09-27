# THISULINK™ Vitals Integration — COTS BLE Architecture

| | |
|---|---|
| **Document** | VIT-SPEC-001 |
| **Subsystem** | Routine vitals capture (blood pressure, blood glucose) |
| **Integration model** | Commercial off-the-shelf devices, Bluetooth SIG standard profiles |
| **Status** | Architecture specified — see §7 |

---

## 1. Design position

THISULINK does **not** manufacture a blood pressure monitor or a glucometer. It
integrates with certified commercial devices over the standard Bluetooth SIG
profiles they already implement.

### Why COTS, and why the cuffless optical model was removed

An earlier design explored cuffless optical (PPG-based) blood pressure
estimation. **That approach is removed from the platform.**

| | Cuffless optical BP | COTS oscillometric cuff |
|---|---|---|
| Regulatory status | No accepted validation standard | ISO 81060-2 validated |
| Calibration | Per-patient, drifts within days | Factory, stable |
| Failure mode | Plausible wrong number | Error code or no reading |
| Clinical acceptance | Not accepted for diagnosis | Standard of care |

The deciding factor is the failure mode. A cuff that fails tells the patient it
failed. A cuffless estimator that drifts returns a number that looks exactly
like a good number — and in a platform whose entire purpose is to escalate
patients on threshold crossings, a silently biased input corrupts triage
without ever appearing broken.

Building an unvalidated measurement device is also the slowest possible route
to market: it converts a software product into a regulated hardware product.
Integrating certified devices inherits their validation.

---

## 2. Supported profiles

### 2.1 Blood Pressure

| Attribute | UUID | Operation |
|---|---|---|
| Blood Pressure Service | `0x1810` | — |
| Blood Pressure Measurement | `0x2A35` | **Indication** |
| Intermediate Cuff Pressure | `0x2A36` | Notify (optional, live display) |
| Blood Pressure Feature | `0x2A49` | Read |

**Conformance target:** ISO 81060-2 validated devices.

`0x2A35` uses **indication**, not notification — it is acknowledged at the ATT
layer. A blood pressure reading is a clinical record; the protocol guarantees
delivery rather than assuming it.

#### Measurement structure

| Field | Presence | Notes |
|---|---|---|
| Flags | Mandatory | Unit selection, optional field presence |
| Systolic / Diastolic / MAP | Mandatory | IEEE-11073 16-bit SFLOAT |
| Timestamp | Optional | Device clock — see §4.2 |
| Pulse rate | Optional | SFLOAT |
| Measurement status | Optional | Body-movement, cuff-fit, irregular-pulse flags |

Values are **SFLOAT**, not integers. The special value `NaN` is a valid
transmission indicating the device could not obtain a reading — it must be
surfaced as a failed measurement, never coerced to zero.

The measurement status bits are retained, not discarded. A reading flagged for
body movement or improper cuff fit is stored with that flag, so a clinician
reviewing an outlier can see the device's own assessment of it.

### 2.2 Glucose

| Attribute | UUID | Operation |
|---|---|---|
| Glucose Service | `0x1808` | — |
| Glucose Measurement | `0x2A18` | **Notify** |
| Glucose Measurement Context | `0x2A34` | Notify (optional) |
| Record Access Control Point | `0x2A52` | Write / Indicate |

**Conformance target:** ISO 15197 validated devices.

#### Record Access Control Point

Glucometers store readings taken while unpaired. The RACP is how the backlog is
retrieved:

```
   Client                                    Glucometer
     │                                            │
     ├── write RACP: "report records > seq N" ───►│
     │                                            │
     │◄── notify 0x2A18: record N+1 ──────────────┤
     │◄── notify 0x2A18: record N+2 ──────────────┤
     │◄── notify 0x2A18: record N+3 ──────────────┤
     │                                            │
     │◄── indicate RACP: "N records reported" ────┤
     │                                            │
```

The sequence number of the last ingested record is persisted per device. A
patient who tests for a week without their phone nearby syncs the full week on
next connection, in order, with no duplicates and no gaps.

### 2.3 Transparent UART bridge — legacy clinic meters

Clinic meters predating BLE GATT profiles expose a serial interface. A
transparent UART BLE bridge module carries that stream.

| Aspect | Handling |
|---|---|
| Transport | Vendor-specific transparent UART service |
| Framing | Per meter model — no standard exists |
| Parser | Per-model adapter behind a common interface |
| Provenance | Record tagged `bridge:<model>` |

Bridged readings carry a provenance marker distinguishing them from readings
obtained over a standard profile. The transport is not certified and the
parsing is model-specific; a clinician reviewing the record is entitled to know
which path a number arrived by.

---

## 3. Acquisition flow

```
  [ COTS device ]
        │ BLE GATT — 0x1810 indication / 0x1808 notification
        ▼
  ┌─────────────────────────────────────────────┐
  │  Companion client — background BLE listener │
  │  • profile decode (SFLOAT, flags, status)   │
  │  • unit normalisation                       │
  │  • plausibility gate                        │
  └─────────────────────────────────────────────┘
        │
        ▼
  ┌─────────────────────────────────────────────┐
  │  Local encrypted SQLite — written FIRST     │
  │  status = PENDING                           │
  └─────────────────────────────────────────────┘
        │
        ├── offline ──► remains queued, patient sees the reading
        │
        └── online ───► PUSH to vitals_records
                             │
                        ┌────┴────┐
                     success    failure
                        │           │
                  status=SYNCED   exponential backoff
                  server id        2, 4, 8 … 60 min
                  recorded
```

The device is the source of truth for the measurement; the local database is
the source of truth for whether it has been delivered. A reading is durable the
instant it is decoded, before any network operation is attempted.

---

## 4. Data handling

### 4.1 Normalisation

| Quantity | Stored as | Wire source |
|---|---|---|
| Systolic / diastolic | Integer mmHg | SFLOAT, kPa converted where flagged |
| Blood glucose | Integer mg/dL | SFLOAT, mmol/L converted where flagged |
| Reading context | `fasting` / `post_prandial` / `random` | Measurement Context, else patient-declared |

Unit flags are honoured per reading, never assumed per device. A device may be
reconfigured between readings, and a kPa value stored as mmHg is a fourfold
error in a field that drives escalation.

### 4.2 Timestamp authority

Device clocks drift and are frequently unset after a battery change. Every
record therefore carries:

| Field | Source | Purpose |
|---|---|---|
| `measured_at` | Device timestamp when present, else ingestion time | Clinical ordering |
| `created` | Server, at insert | Immutable audit ordering |

Where a device timestamp is implausible — future-dated, or preceding the
device's own last sync — ingestion time is used and the record is flagged. A
misordered glucose series changes which readings are read as fasting.

### 4.3 Plausibility gate

Readings outside physiological bounds are stored and flagged, never silently
dropped:

| Quantity | Accepted range |
|---|---|
| Systolic | 40 – 300 mmHg |
| Diastolic | 20 – 200 mmHg |
| Blood glucose | 0 – 1000 mg/dL |

A rejected-looking value may be a device fault or a genuine emergency. The
platform is not entitled to decide which by discarding it.

---

## 5. Backend contract

Readings land in `vitals_records`:

| Field | Type | Notes |
|---|---|---|
| `patient_id` | relation → `patients` | Required |
| `operator_id` | relation → `users` | Self for home readings |
| `systolic_bp` | number | mmHg |
| `diastolic_bp` | number | mmHg |
| `blood_glucose` | number | mg/dL |
| `reading_type` | select | `fasting` \| `post_prandial` \| `random` |
| `measured_at` | date | Clinical time |
| `cycle_day` | number | 1–6 screening cycle position |

Insertion triggers server-side triage recomputation. Glucose thresholds
(>180 / >300 / >400 mg/dL) participate directly in tier assignment — see
[backend/README.md](../backend/README.md).

---

## 6. Pairing and security

| Requirement | Specification |
|---|---|
| Pairing | LE Secure Connections where the device supports it |
| Bonding | Persisted per patient device |
| Multi-user | Bonds scoped to the authenticated account |
| Shared devices | Reading attributed to the signed-in patient at ingestion |

A shared household or clinic device is a real deployment case. Attribution is
resolved at ingestion against the authenticated session — never inferred from
which device transmitted.

---

## 7. Implementation status

| Component | Status |
|---|---|
| Profile specification and record contract | Specified |
| `vitals_records` collection | **Live in production** |
| Triage integration on glucose thresholds | **Live and verified** |
| Manual vitals entry (Clinical Diagnostic Suite) | Implemented |
| Offline queue, backoff, two-way sync engine | Implemented and unit-tested |
| **COTS BLE auto-capture (`0x1810` / `0x1808`)** | **Not implemented** |
| **RACP backlog retrieval** | **Not implemented** |
| **Transparent UART bridge adapters** | **Not implemented** |

The backend, storage, sync and triage paths for vitals are live today, carrying
seeded clinical data. The automatic BLE capture path described in §2 is
specified but not yet built; vitals currently reach the platform through manual
entry in the Clinical Diagnostic Suite.
