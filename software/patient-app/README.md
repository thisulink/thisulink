# THISULINK™ Patient Health Companion

| | |
|---|---|
| **Document** | SW-PAT-001 |
| **User** | Monitored patient, caregiver |
| **Role** | `patient` |
| **Platform** | Mobile (Android / iOS), Web |
| **Status** | **Specified — not implemented.** See §8 |

---

## 1. Purpose

Screening finds the patients who need attention. Between screenings, outcomes
are determined by what happens daily: whether blood pressure and glucose are
logged, whether medication is taken, whether diet holds.

The Patient Health Companion is the daily-adherence half of the platform. It
turns a patient from a subject who is screened every six days into a
participant producing a continuous record.

### Access boundary

A patient sees **their own record only**. The `patient` role is excluded from
every clinical collection by explicit allowlist — it cannot list patients, foot
scans, fundus records or triage results, including its own by collection query.
Patient-facing data is served through scoped views bound to the authenticated
identity.

This is enforced at the backend and verified: a patient account currently
returns **zero records** from every clinical collection. See
[backend/README.md](../../backend/README.md) §4.

---

## 2. Daily routine management

| Property | Specification |
|---|---|
| Scheduler | Platform background task (WorkManager / BGTaskScheduler) |
| Cadence | 15-minute evaluation tick |
| Notifications | **Local, on-device** |
| Push infrastructure | **None** |
| Morning prompt | Blood pressure, fasting glucose |
| Medication prompts | Per prescribed schedule |

```
   background tick (15 min)
          │
          ▼
   read local adherence state
          │
   ┌──────┴──────────────────────────────┐
   │ Is a scheduled item overdue?        │
   └──────┬──────────────────────────────┘
          │ yes
          ▼
   already notified for this item today? ── yes ──► suppress
          │ no
          ▼
   raise local notification
          │
          ▼
   record as fired  ◄── prevents repeat on every subsequent tick
```

Notifications are raised by the device from its own database. No external push
service participates — reminders fire with no connectivity, and the platform
does not disclose a patient's medication schedule to a third-party push
provider.

---

## 3. COTS vitals auto-capture

The companion pairs with the patient's own certified home devices and ingests
readings without manual entry.

| Device | Profile | Characteristic |
|---|---|---|
| Blood pressure monitor | `0x1810` | `0x2A35` (indication) |
| Glucometer | `0x1808` | `0x2A18` (notification) |

```
   patient takes a reading on their own device
                  │
                  ▼
   background BLE listener receives GATT notification
                  │
                  ▼
   decode · normalise units · plausibility gate
                  │
                  ▼
   write to encrypted local store   ← durable immediately
                  │
                  ▼
   push to vitals_records when connectivity permits
                  │
                  ▼
   server-side triage recomputation
```

Backlogged readings taken while unpaired are retrieved through the glucose
Record Access Control Point, in order, without duplication. Full profile
specification: [vitals-monitor/](../../vitals-monitor/README.md).

### Why auto-capture rather than manual entry

Manual transcription is the point where daily monitoring fails. It is
burdensome, and it is the step where a 148 becomes a 184 — a transposition that
crosses a triage threshold and escalates a patient who is fine, or fails to
escalate one who is not.

---

## 4. AI dietary companion — physician-gated

| Property | Specification |
|---|---|
| Model | Groq Llama-3.3-70B |
| Scope | Nutrition and lifestyle guidance only |
| **Gate** | **Constrained to physician-approved dietary boundaries** |
| Prohibited | Medication changes, dose adjustment, diagnosis, triage interpretation |
| Record | `consultations.diet_plan_json`, physician-signed |

### The gate is the design

```
   physician reviews and approves a dietary plan
                  │
                  ▼
   plan stored, signed, versioned
                  │
                  ▼
   ┌──────────────────────────────────────────────┐
   │  Patient asks a nutrition question           │
   │           │                                  │
   │           ▼                                  │
   │  assistant answers WITHIN the approved plan  │
   │           │                                  │
   │  ┌────────┴─────────┐                        │
   │  │ in scope?        │                        │
   │  └────────┬─────────┘                        │
   │      no   │   yes                            │
   │      │    └──► answer                        │
   │      ▼                                       │
   │  refuse + route to the care team             │
   └──────────────────────────────────────────────┘
```

An unconstrained language model in a diabetes application will eventually be
asked whether to skip insulin, and will eventually answer. The assistant is
therefore scoped to a plan a named physician has already approved, and every
question outside that scope routes to the care team rather than being answered.

The assistant explains and applies a clinical decision. It does not make one.

---

## 5. Tele-consultation

| Property | Specification |
|---|---|
| Transport | LiveKit WebRTC |
| Entry | One-touch waiting room from the home screen |
| Token minting | **Server-side only** |
| Participants | Patient, physician, optionally the health worker |

### Tokens are never minted on the client

Signing a join token requires the API secret. A secret embedded in a
distributed application is a published secret — anyone who extracts it can mint
a token for any room, and the rooms carry clinical consultations.

The client requests a token from the token service, which authenticates the
session and issues a credential scoped to one room with a short expiry.

---

## 6. Patient-facing data

What the companion shows:

| View | Content |
|---|---|
| Today | Scheduled items, adherence state |
| Vitals trend | Own blood pressure and glucose over time |
| Care plan | Physician-approved dietary and lifestyle plan |
| Appointments | Scheduled consultations, waiting room entry |
| Profile | Demographics, ABHA linkage, care team |

What it does **not** show:

- Raw shear-wave waveforms or fundus imagery
- Triage tier or `reason_summary`
- Relay alerts raised to the health worker
- Any other patient's data, in any form

Screening outputs are clinical interpretations. A patient seeing 🔴 RED in an
application, without a clinician present to explain it, is an adverse event in
itself. Results reach the patient through the consultation, which is what the
consultation is for.

---

## 7. Offline behaviour

| Operation | Offline |
|---|---|
| Reminders | Fully functional — local scheduler |
| BLE vitals capture | Fully functional — link is local |
| Reading storage | Encrypted local store |
| Care plan review | Cached |
| Vitals trend | Cached plus local readings |
| Upload | Queued, exponential backoff |
| Dietary assistant | Unavailable — requires the model endpoint |
| Tele-consultation | Unavailable |

---

## 8. Implementation status

**This application is not built.** Every section above is specification.

| Component | Status |
|---|---|
| `patient` role, authentication, RBAC exclusion | **Live and verified in production** |
| Patient account and longitudinal record | **Live in production** |
| `vitals_records` collection and triage integration | **Live and verified** |
| Reminder engine (pattern proven in the field client) | Implemented in `thisulink_app` |
| Offline outbox, backoff, two-way sync | Implemented in `thisulink_app` |
| **Patient application shell and screens** | **Not implemented** |
| **COTS BLE auto-capture** | **Not implemented** |
| **Dietary assistant integration** | **Not implemented** |
| **Tele-consultation waiting room** | **Not implemented** |
| **Token service** | **Not deployed** |

### What exists today

The backend is ready: the role exists, access rules exclude it correctly from
clinical collections, and the account and its record are live. The reminder
engine, offline outbox and sync engine are implemented and unit-tested in the
field client and are directly reusable.

### Delivery order

1. Application shell, authentication, role routing, today view
2. Manual vitals entry — establishes the record path end to end
3. Reminder engine port from the field client
4. COTS BLE auto-capture (§3)
5. Token service, then the waiting room (§5)
6. Dietary assistant — **only after** the physician approval and signing flow
   exists in the workstation, since the gate in §4 depends on it

Step 6 must not precede step 5's clinical sign-off path. An assistant with no
approved plan to be constrained by is an unconstrained assistant.
