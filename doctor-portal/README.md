# THISULINK™ Specialist Clinical Workstation

| | |
|---|---|
| **Document** | SW-DOC-001 |
| **User** | Specialist, endocrinologist, medical officer |
| **Roles** | `doctor`, `admin` |
| **Platform** | Web (Flutter) |
| **Live** | **https://thisulink.xyz** · **https://doctor.thisulink.xyz** |
| **Source** | `doctor_portal/` (client build artefact) |
| **Status** | Live in production — see §8 |

---

## 1. Purpose

The workstation is where clinical judgement is applied. Field encounters arrive
continuously, already stratified by the triage engine; the physician's scarce
attention is directed at the cases that warrant it, with the complete evidence
for each in one place.

Its design goal is a short path from *a red case arrived* to *a decision was
recorded*.

### Access boundary

Entry requires `doctor` or `admin`. An authenticated account with any other
role has its session cleared and is refused — health workers use the Clinical
Diagnostic Suite, patients the Health Companion. Authorisation is enforced at
the backend by explicit allowlist, not by hiding routes in the client.

---

## 2. Physician queue

### Realtime delivery

```
   health worker saves an encounter
              │
              ▼
   PocketBase hook recomputes triage
              │
              ▼
   patients.active_triage_status updated
   triage_results audit row written
              │
              ▼
   PocketBase realtime event (SSE)
              │
              ▼
   ┌────────────────────────────────────────┐
   │  WORKSTATION QUEUE                     │
   │  • row inserted in priority position   │
   │  • tier counters increment             │
   │  • audible chime on RED / ORANGE       │
   │  • banner: "New critical encounter"    │
   └────────────────────────────────────────┘
```

Delivery is Server-Sent Events over the same gateway as the REST API. No
polling; the queue updates without a refresh.

> **Operational note.** The SSE stream is long-lived. Any proxy between client
> and backend must not buffer it. A buffered stream fails invisibly — the queue
> simply stops updating while every health check reports normal. The production
> reverse proxy disables buffering on this route specifically.

### Ordering

Strictly by clinical risk, never by arrival time:

| Order | Tier | Meaning |
|---|---|---|
| 1 | 🔴 **RED** | Critical — immediate referral |
| 2 | 🟠 **ORANGE** | Priority — escalate |
| 3 | 🟡 **YELLOW** | Moderate — monitor, recheck next cycle |
| 4 | 🟢 **GREEN** | Stable — no action |

A chronological queue buries a critical case behind twenty routine ones. The
tier filter row carries live counts, so the size of each tier is visible before
any case is opened.

### Search

| Field | Behaviour |
|---|---|
| ABHA ID | Exact or partial |
| Patient name | Substring |
| Village | Substring, for outbreak or camp review |

Search values are escaped before interpolation — backend filter strings are not
parameterised.

---

## 3. Encounter review

### Patient dossier

Demographics, ABHA identifier, assigned health worker, current cycle day, and
full longitudinal history across every modality.

### Plantar biomechanics viewer

| Panel | Content |
|---|---|
| **Interlock banner** | Contact force with the 1.40–1.60 N window; out-of-window capture flagged prominently |
| **Metrics** | cₛ, Young's modulus E, tissue class, ΔT |
| **Time domain** | Dual-pickup acceleration overlay, phase offset visible |
| **Frequency domain** | FFT across the 10–300 Hz sweep with resonance marker fₙ |
| **Thermal** | Contralateral asymmetry gauges against the 2.2 °C threshold |
| **Raw frame** | Hex dump of the 73-byte packet as transmitted |

The interlock banner leads because it determines whether the rest of the panel
means anything. A scan captured outside the force window is not a noisy
measurement — it is a measurement of a different mechanical state, and the
physician must see that before reading the modulus.

The raw frame panel is the audit trail. If a reading is ever disputed, this is
what the probe actually sent.

### Retinal viewer

| Element | Behaviour |
|---|---|
| Presentation | Both eyes side by side, laterality labelled |
| Navigation | Zoom 1×–6×, pan |
| AI output | ICDR grade with P(referable) against the 0.50 threshold |
| **Override** | Physician records `doctor_confirmed_grade` |
| Notes | Free-text clinical annotation |

**A confirmed grade supersedes the prediction, including grade 0.** A physician
recording "no retinopathy" over a model's grade 3 is a clinical decision and is
never silently reverted. This is enforced in the triage engine and covered by
its tests.

### Longitudinal vitals

Blood pressure and glucose over time, with threshold bands drawn. Axes always
extend past the clinical threshold, so a reference line never falls off a chart
whose data sits entirely below it.

---

## 4. Clinical actions

### Tele-consultation

```
   [ Start consultation ]
            │
            ▼
   POST /api/livekit/token   ← server-side minting, authenticated session
            │
            ▼
   join room — patient, physician, optionally the health worker
            │
            ▼
   ┌─────────────────────────┬──────────────────────────┐
   │  Live vitals, history   │   HD video               │
   │  and encounter evidence │                          │
   └─────────────────────────┴──────────────────────────┘
            │
            ▼
   notes · prescription · diet plan recorded against the consultation
```

The token is minted by the server. The signing secret never reaches a browser —
a secret shipped in a web bundle is a published secret, and these rooms carry
clinical consultations.

### Digital prescription

| Element | Behaviour |
|---|---|
| Composition | Structured medication formulary |
| Signature | Physician cryptographic signature |
| Output | Signed PDF, attached to the consultation |
| Mutability | Immutable once signed; amendment creates a new version |

### Dietary plan approval

The AI-generated nutrition plan is presented for review. The physician
approves, modifies, or rejects it; only an approved, signed plan becomes the
boundary within which the patient's dietary assistant is permitted to answer.

This sign-off is the gate described in
[patient-app/](../software/patient-app/README.md) §4. Without it the assistant
has no approved plan to be constrained by.

---

## 5. Closed-loop lifecycle

```
  HEALTH WORKER                 BACKEND                    PHYSICIAN
       │                           │                            │
       │ capture encounter         │                            │
       ├──────────────────────────►│                            │
       │                           │ recompute triage           │
       │                           │ write audit row            │
       │                           │ update patient tier         │
       │                           │                            │
       │                           │ if entering RED/ORANGE:    │
       │                           │   raise relay alert        │
       │                           │                            │
       │                           │ SSE event ────────────────►│
       │                           │                       queue updates
       │                           │                       chime + banner
       │                           │                            │
       │                           │◄── open encounter ─────────┤
       │                           │    review evidence         │
       │                           │                            │
       │                           │◄── confirm/override grade ─┤
       │                           │ recompute triage           │
       │                           │                            │
       │◄─── consultation invite ──┼────────────────────────────┤
       │     (health worker joins) │                            │
       │                           │◄── prescription signed ────┤
       │                           │◄── diet plan approved ─────┤
       │                           │                            │
       │◄── alert acknowledged ────┤                            │
       │    follow-up scheduled    │                            │
```

Every transition is recorded. `triage_results` accumulates one row per
computation — including no-change ones — so the record shows the patient was
assessed and found stable rather than going silent.

---

## 6. Interface conventions

| Convention | Rationale |
|---|---|
| Tier colours are reserved | Amber and crimson appear only for clinical severity, never decoratively |
| Loading states shimmer | Distinguishes "loading" from "empty" — an empty queue and an unloaded queue must never look alike |
| Errors are actionable | "Device disconnected. Check Bluetooth pairing." — states what to do |
| Intended-use notice is persistent | Present on every page; the accountability chain is never ambiguous |
| Desktop-first, responsive | Laid out for a workstation, collapses below 1000 px |

---

## 7. Operating modes

| Mode | Endpoint |
|---|---|
| Production gateway | `https://pb.thisulink.xyz` |
| **Field camp** | Local backend, selected at runtime |

The login screen exposes a backend indicator, a reachability test, and a
field-camp toggle. A clinic running its own backend on a local machine with no
internet switches without a rebuild or a configuration file edit.

---

## 8. Implementation status

| Component | Status |
|---|---|
| Deployment | **Live at https://thisulink.xyz and https://doctor.thisulink.xyz** |
| Authentication, role gate, session handling | **Live and verified** |
| Triage queue, tier filters, live counts | Implemented |
| Realtime SSE subscription | Implemented; buffering disabled at the proxy |
| ABHA / name / village search | Implemented, injection-escaped |
| Plantar waveform, FFT, thermal, raw-frame panels | Implemented |
| Retinal viewer, zoom/pan, override, sign-off | Implemented |
| Longitudinal vitals charts | Implemented |
| Signed report generation | Implemented |
| Static analysis | Clean |
| **Tele-consultation** | **Blocked — token service not deployed** |
| **Structured formulary and cryptographic signature** | **Not implemented** |
| **Dietary plan approval flow** | **Not implemented** |
| **Automated tests** | **None** |

### Honest gaps

**Tele-consultation cannot start.** The `POST /api/livekit/token` endpoint is
not deployed, so session creation reports that no join token was returned.
Every other function is unaffected.

**The workstation has no test suite.** The field client has 63 tests; this
application has none. The triage logic it displays is tested in the shared
domain layer, but its own presentation and state handling are verified only by
inspection and by live use against production data.
