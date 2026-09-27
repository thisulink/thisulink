# THISULINK™ Backend — Schema, RBAC & Event Engine

| | |
|---|---|
| **Document** | BE-SPEC-001 |
| **Platform** | PocketBase 0.22.21 (embedded SQLite, REST, SSE, JSVM hooks) |
| **Live** | **https://pb.thisulink.xyz** |
| **Infrastructure** | [INFRASTRUCTURE.md](INFRASTRUCTURE.md) |
| **Status** | Live in production — see §7 |

---

## 1. Role

One backend serves every client: authentication, role-based authorisation,
clinical record storage, file storage, realtime event delivery, and the
authoritative triage engine.

The triage engine runs **here**, not in the clients. Clients compute a
provisional tier so a field device works offline, but the server's computation
is the one that counts and the one that persists.

---

## 2. Collection architecture

```
                    ┌─────────────┐
                    │    users    │  auth · role · RBAC anchor
                    └──────┬──────┘
                           │ assigned_health_worker
                           ▼
                    ┌─────────────┐
                    │  patients   │  ABHA · demographics · active tier
                    └──────┬──────┘
                           │ patient_id
        ┌──────────────────┼──────────────────┬─────────────┐
        ▼                  ▼                  ▼             ▼
┌───────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────┐
│ plantar_swe_  │  │  retinal_    │  │   vitals_    │  │ teleconsult
│   records     │  │  records     │  │   records    │  │ _sessions │
└───────┬───────┘  └──────┬───────┘  └──────┬───────┘  └──────────┘
        │                 │                 │
        └────────┬────────┴─────────────────┘
                 ▼  triggers triage recomputation
        ┌─────────────────┐        ┌───────────────┐
        │ triage_results  │───────►│ relay_alerts  │
        │ audit trail     │        │ escalation    │
        └─────────────────┘        └───────────────┘
```

### Canonical names

Earlier drafts used shorter names. **The live schema is authoritative**; both
frontends and the hook engine bind to it.

| Draft name | Live collection |
|---|---|
| `vitals` | `vitals_records` |
| `plantar_scans` | `plantar_swe_records` |
| `retinal_scans` | `retinal_records` |
| `triage_records` | `triage_results` |
| `consultations` | `teleconsult_sessions` |

Field names differ correspondingly — `sbp` → `systolic_bp`, `triage_color` →
`overall_tier`. These collections are live, populated and bound; renaming them
is a breaking migration with a data backfill, not a cosmetic edit.

---

## 3. Schema

### `users` — auth collection

| Field | Type | Notes |
|---|---|---|
| `email`, `password` | system | Email auth; 8-character minimum |
| `role` | select | `health_worker` \| `doctor` \| `patient` \| `admin` |
| `name` | text | |
| `phone` | text | |
| `assigned_phc` | text | Primary health centre |
| `district` | text | |
| `specialisation`, `hospital` | text | Clinician fields |

One auth collection with a role field, not one collection per role. Four roles
extend without a schema change, and a login is one request.

### `patients`

| Field | Type | Notes |
|---|---|---|
| `abha_id` | text | 14 digits, **unique index** |
| `name`, `age`, `gender`, `village` | | Demographics |
| `assigned_health_worker` | relation → `users` | Caseload anchor |
| `active_triage_status` | select | `green` \| `yellow` \| `orange` \| `red` |
| `current_cycle_day` | number | 1–6 |
| `diabetes_type` | text | |

**Indexes:** unique on `abha_id`; on `assigned_health_worker`; on
`active_triage_status` (the physician queue's primary filter).

`current_cycle_day` drives the entire reminder engine — which vital is due,
when the fundus photograph is taken, what a missed day means.

### `plantar_swe_records`

| Field | Type | Notes |
|---|---|---|
| `patient_id` | relation, cascade delete | |
| `operator_id` | relation → `users` | |
| `contact_force_n` | number | Stored as measured, including out-of-window |
| `shear_wave_speed_mps` | number | cₛ |
| `youngs_modulus_kpa` | number | E |
| `tissue_class` | select | `A_healthy` \| `B_early_glycation` \| `C_diabetic_neuropathy` |
| `thermal_asymmetry_delta_t` | number | °C |
| `resonance_peak_hz` | number | fₙ |
| `raw_packet_hex` | text | 73-byte frame as transmitted — audit trail |
| `cycle_day`, `measured_at` | | |

Contact force is stored even when invalid, so a reviewer can see *why* a scan
was rejected rather than finding it absent.

### `retinal_records`

| Field | Type | Notes |
|---|---|---|
| `patient_id`, `operator_id` | relation | |
| `image_file` | file | JPEG/PNG, 10 MB max |
| `eye_side` | select | `left` \| `right` |
| `predicted_dr_grade` | number | ICDR 0–4 |
| `referable_dr_prob` | number | 0.0–1.0 |
| `doctor_confirmed_grade` | number | **Nullable — absent means unreviewed** |
| `doctor_notes` | text | |

Nullability of `doctor_confirmed_grade` is load-bearing: it is how the sign-off
queue distinguishes unreviewed from reviewed-as-normal.

### `vitals_records`

| Field | Type |
|---|---|
| `patient_id`, `operator_id` | relation |
| `systolic_bp`, `diastolic_bp` | number, mmHg |
| `blood_glucose` | number, mg/dL |
| `reading_type` | select — `fasting` \| `post_prandial` \| `random` |
| `cycle_day`, `measured_at` | |

### `triage_results` — audit trail

| Field | Type |
|---|---|
| `patient_id` | relation |
| `overall_tier` | select — `green` \| `yellow` \| `orange` \| `red` |
| `reason_summary` | text — human-readable clinical justification |
| `computed_at` | date |

A row per computation, **including no-change computations**. The history must
show that a patient was assessed and found stable, not fall silent.

### `relay_alerts`

| Field | Type |
|---|---|
| `patient_id`, `health_worker_id` | relation |
| `status` | select — `pending` \| `acknowledged` \| `resolved` |
| `message` | text — tier and reason |

### `teleconsult_sessions`

| Field | Type |
|---|---|
| `patient_id`, `doctor_id` | relation |
| `room_name` | text |
| `status` | select — `scheduled` \| `in_progress` \| `completed` \| `cancelled` |
| `notes`, `prescription` | text |
| `started_at`, `ended_at` | date |

---

## 4. Zero-trust RBAC

### Rule model

| Constant | Expression |
|---|---|
| `CLINICIAN` | `@request.auth.role = "doctor" \|\| @request.auth.role = "admin"` |
| `STAFF` | `@request.auth.role = "health_worker" \|\| ... = "doctor" \|\| ... = "admin"` |
| `PATIENT_SCOPED` | `(CLINICIAN) \|\| (@request.auth.id = assigned_health_worker.id)` |

| Collection | list / view | create | update |
|---|---|---|---|
| `users` | self, or clinician | admin only | self, or clinician |
| `patients` | `PATIENT_SCOPED` | `STAFF` | `PATIENT_SCOPED` |
| `plantar_swe_records` | `STAFF` | `STAFF` | `CLINICIAN` |
| `retinal_records` | `STAFF` | `STAFF` | `CLINICIAN` |
| `vitals_records` | `STAFF` | `STAFF` | `CLINICIAN` |
| `triage_results` | `STAFF` | `STAFF` | `CLINICIAN` |
| `relay_alerts` | `STAFF` | `STAFF` | `STAFF` |
| `teleconsult_sessions` | `STAFF` | `CLINICIAN` | `CLINICIAN` |

A health worker sees their own caseload. Clinicians see the network. The
`patient` role appears in **no** allowlist and therefore reaches no clinical
collection.

---

### 4.1 Incident: cross-tenant PHI exposure

A real defect, found during production verification and fixed. It is recorded
here because the failure mode generalises.

#### What happened

PocketBase creates a default `users` auth collection on first run. The schema
migration guarded collection creation with an "already exists" check — correct
for every other collection, wrong for this one. The check passed, creation was
skipped, and the collection retained only PocketBase's own `name` and `avatar`
fields.

**The `role` field was never created.** No account had a role.

#### Why it was invisible

The original access rules used a negative exclusion:

```
   @request.auth.id != "" && @request.auth.role != "patient"
```

With `role` undefined, `role != "patient"` evaluates **true**. Every
authenticated account passed. Account provisioning succeeded and returned
identifiers; PocketBase silently discards unknown fields on create, so
`"role":"doctor"` was accepted and dropped without error.

#### Impact

Verified before the fix: the patient account could list **all 24 plantar
records, all 24 vitals records, all 4 retinal evaluations and all 8 triage
results** — every other patient's clinical data.

The defect surfaced only because the physician queue rendered empty: the
`patients` rule used a positive check (`role = "doctor"`), which correctly
failed closed. One collection failing closed is what exposed seven failing
open.

#### Fix

1. **Schema repaired** — `role` and the staff fields added; the migration now
   *extends* an existing `users` collection instead of skipping it.
2. **Rules rewritten as explicit allowlists.** An account whose role is
   missing, or carries a value added after the rules were written, is now
   **denied by construction**.

```
   ✗ negative exclusion              ✓ explicit allowlist
   role != "patient"                 role = "health_worker"
                                  || role = "doctor"
   unknown role → ADMITTED        || role = "admin"
                                     unknown role → DENIED
```

#### Verified after the fix

| Account | patients | plantar | vitals | retinal |
|---|---|---|---|---|
| `doctor` | 4 | 24 | 24 | 4 |
| `health_worker` | 4 | 24 | 24 | 4 |
| **`patient`** | **0** | **0** | **0** | **0** |

#### Generalisation

An exclusion rule fails **open** when the field it tests is absent. An
allowlist fails **closed**. In any system holding protected health
information, authorisation must be expressed as an allowlist — not because it
reads better, but because the two behave oppositely under exactly the
condition nobody tests for.

---

## 5. Realtime event engine

### Triage recomputation

```
   record created in plantar_swe_records | vitals_records | retinal_records
   ── or ── retinal_records updated (physician sign-off)
                       │
                       ▼
   load the patient's LATEST record of EACH modality
                       │
                       ▼
   compute tier (first match wins, most severe first)
                       │
        ┌──────────────┼──────────────────┐
        ▼              ▼                  ▼
   write audit    update patient     if ENTERING red/orange
   row (always)   tier if changed    and no alert pending:
                       │              raise relay_alert
                       ▼
                 SSE event → Specialist Workstation queue
```

### Tier rules

| Tier | Condition — first match wins |
|---|---|
| 🔴 RED | Tissue class C, **or** P(referable) ≥ 0.50 with grade ≥ 3, **or** glucose > 400 mg/dL |
| 🟠 ORANGE | Class B with ΔT ≥ 2.2 °C, **or** P(referable) ≥ 0.50, **or** glucose > 300 |
| 🟡 YELLOW | Class B, **or** ΔT ≥ 2.2 °C, **or** grade ≥ 2, **or** glucose > 180 |
| 🟢 GREEN | None of the above |

### Engine properties

| Property | Rationale |
|---|---|
| Computed from the latest of **each** modality | A glucose reading hours after a foot scan must not discard that scan |
| `doctor_confirmed_grade` supersedes prediction, **including 0** | A physician's "no retinopathy" is never reverted by null-coalescing |
| Audit row on every computation | History shows assessment, not silence |
| Alert only on **entering** a priority tier, and only if none pending | A patient who remains unwell must not bury their health worker |
| Failure never rolls back the clinical record | The reading matters; a tier can be recomputed |

### Manual recomputation

`POST /api/thisulink/retriage` — admin authenticated. Recomputes every patient
and reports `{recomputed, total, failures}`. Used after a rule change or to
backfill.

---

### 5.1 Incident: silent hook failure

A second real defect, also found in production verification.

**PocketBase executes every JSVM hook handler in its own isolated context.**
Declarations at the top level of a hook file are not visible inside the handler
body — referencing one throws `ReferenceError` at request time, not at load.

The handlers were registered correctly and called on schedule, but every
invocation threw on its first line. Because the hook catches its own errors to
protect the clinical write, records saved normally, the API returned 200, and
`triage_results` stayed empty. The only evidence was a line in the service
journal.

**Fix:** the engine is a separate module, `require()`d from **inside** each
handler body rather than closed over.

**Generalisation:** a hook that swallows its own errors to protect a write must
be monitored on its *output*, not its status code. The check that caught this
was noticing that `triage_results` had zero rows after seeding data that must
produce eight.

---

## 6. API surface

| Operation | Endpoint |
|---|---|
| Health | `GET /api/health` |
| Authenticate | `POST /api/collections/users/auth-with-password` |
| Refresh | `POST /api/collections/users/auth-refresh` |
| Records | `GET|POST|PATCH /api/collections/{name}/records` |
| Files | `GET /api/files/{collection}/{id}/{filename}` |
| Realtime | `GET /api/realtime` (SSE) |
| Recompute triage | `POST /api/thisulink/retriage` (admin) |
| **Administration console** | `/_/` — **mesh only; 404 at the public edge** |

### Query safety

Filter strings are **not parameterised**. Every user-supplied value is escaped
before interpolation — backslash and double-quote — in all clients. A quote
that terminates a filter literal is an authorisation bypass, not a syntax
error.

---

## 7. Implementation status

| Component | Status |
|---|---|
| Deployment | **Live at https://pb.thisulink.xyz** |
| Eight collections, indexes, relations | **Live** |
| RBAC allowlists | **Live and verified** — patient isolation confirmed |
| Triage engine | **Live and verified end to end** |
| Relay escalation | **Verified** — alert raised on tier entry with clinical reason |
| Realtime SSE | Live |
| Manual recompute endpoint | Live |
| Seeded clinical dataset | 4 accounts · 4 patients · 24 plantar · 24 vitals · 4 retinal |
| Administration console exposure | **404 publicly, mesh-only** |
| **Tele-consultation token service** | **Not deployed** |
| **Automated backups** | **Not configured** — see INFRASTRUCTURE.md |

### Verified tier assignment

| Patient | Tissue | ΔT | Glucose | ICDR | Tier |
|---|---|---|---|---|---|
| Meena Devi | C | 2.7 °C | 262 | 4 | 🔴 RED |
| Saravanan S | B | 2.4 °C | 216 | 2 | 🟠 ORANGE |
| Ravi Kumar | B | 1.9 °C | 168 | 1 | 🟡 YELLOW |
| Arjun Prakash | A | 1.2 °C | 138 | 0 | 🟢 GREEN |
