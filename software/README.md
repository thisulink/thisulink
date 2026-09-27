# THISULINK™ Client Architecture — Cross-Platform Flutter

| | |
|---|---|
| **Document** | SW-ARCH-001 |
| **Scope** | All client applications — Android, iOS, Web |
| **Source** | `thisulink_app/` (field client), `doctor_portal/` (web workstation) |
| **Status** | Two of three clients shipped — see §8 |

---

## 1. Client matrix

| Client | Role served | Platform | Specification |
|---|---|---|---|
| **Clinical Diagnostic Suite** | `health_worker` | Android tablet / phone | [daq-dashboard/](daq-dashboard/README.md) |
| **Specialist Clinical Workstation** | `doctor`, `admin` | Web | [../doctor-portal/](../doctor-portal/README.md) |
| **Patient Health Companion** | `patient` | Mobile / Web | [patient-app/](patient-app/README.md) |

All three are Flutter. Sharing a language and widget layer across a tablet
acquisition app and a desktop review workstation is only worthwhile because the
**clinical logic** is shared — the triage rules, the packet contract, the unit
conventions and the threshold constants exist once and are compiled into every
client.

---

## 2. Layered architecture

```
  ┌─────────────────────────────────────────────────────────┐
  │  PRESENTATION                                            │
  │  Screens · charts · status badges · shimmer loaders      │
  │  Role-specific shells, shared design system              │
  └────────────────────────┬────────────────────────────────┘
                           │ watches providers
  ┌────────────────────────▼────────────────────────────────┐
  │  STATE — Riverpod 2                                      │
  │  AsyncNotifier · FutureProvider.family · overrides       │
  └────────────────────────┬────────────────────────────────┘
                           │ calls repositories
  ┌────────────────────────▼────────────────────────────────┐
  │  DOMAIN                                                  │
  │  Triage engine · packet decoder · clinical constants     │
  │  Pure, synchronous, fully unit-testable                  │
  └────────────────────────┬────────────────────────────────┘
                           │
  ┌────────────────────────▼────────────────────────────────┐
  │  DATA                                                    │
  │  Repositories → local store ⇄ sync engine ⇄ PocketBase   │
  └──────────┬──────────────────────────────┬───────────────┘
             │                              │
      ┌──────▼──────┐              ┌────────▼────────┐
      │ Drift SQLite│              │  PocketBase SDK │
      │ encrypted   │              │  REST + SSE     │
      └─────────────┘              └─────────────────┘
```

The domain layer holds no I/O. The triage engine takes values and returns a
tier; the packet decoder takes bytes and returns a reading or null. Both are
exhaustively testable without a device, a network or a server — which is why
they are the layers with test coverage.

---

## 3. State management — Riverpod 2

| Pattern | Applied to |
|---|---|
| `AsyncNotifierProvider` | Authentication session, triage feed |
| `FutureProvider.family` | Per-patient history, filtered rosters |
| `Provider` | Repositories, clients, long-lived services |
| `StreamProvider` | Sync status, realtime subscriptions |
| Provider overrides | Demonstration mode, test doubles |

### Overrides as the demonstration mechanism

Demonstration mode is a set of provider overrides applied at startup behind a
compile-time flag. The demonstration repositories **subclass the production
repositories** and override only the methods that would reach the network.

Every screen, widget, chart and clinical rule beneath them is therefore the
shipped code, not a parallel mock implementation. A demonstration exercises the
real triage engine against seeded inputs; the only substituted component is the
transport.

---

## 4. Routing — GoRouter 14

### Role-protected dispatch

```
   cold start
       │
       ▼
   restore session from encrypted token store
       │
       ├── no valid session ──────────────► /login
       │
       ▼
   read `role` from the authenticated record
       │
       ├── health_worker ──► /field/home    (Clinical Diagnostic Suite)
       ├── doctor | admin ──► /queue        (Specialist Workstation)
       ├── patient ────────► /companion     (Patient Health Companion)
       └── absent | unknown ► /login + session cleared
```

### Unknown roles are refused, not defaulted

A role the client does not recognise — absent, misspelled, or added to the
backend after the client shipped — results in **sign-out**, never a fallback
shell.

Defaulting is the same class of error that produced a real PHI exposure in this
platform's own backend: an exclusion rule admitted accounts whose role was
undefined. A client that defaults an unknown role to the field shell would
place an unrecognised account in front of a patient roster. Both layers now
fail closed.

Route guards re-evaluate on every navigation, not only at login. A session that
is invalidated server-side while the application is open redirects on the next
transition.

---

## 5. Offline data engine

The field client is built for a village with no signal. Connectivity is the
exception path, not the assumption.

```
     capture (sensor or manual entry)
              │
              ▼
     ┌─────────────────────────────┐
     │  Drift / SQLite, encrypted  │   ← durable HERE, before any network call
     │  status = PENDING           │
     └─────────────────────────────┘
              │
     ┌────────┴────────┐
     ▼                 ▼
  OFFLINE           ONLINE detected
  stays queued      │
  local triage      ▼
  tier displayed   PUSH outbox → server
                    │
             ┌──────┴──────┐
          success        failure
             │              │
        SYNCED +       backoff 2,4,8…60 min
        server ids     (per-record, persisted)
             │
             ▼
        PULL roster ← server-recomputed tiers
        local cache invalidated
```

### Push, then pull

The pull phase runs **after** the push, so the tiers read back already reflect
what was just uploaded. Without it, a health worker would continue to see the
provisional tier their device computed offline, even after the server had
authoritatively recomputed it.

### Partial-failure resume

A captured encounter fans out into up to three server collections. Each
returned record id is written back to the local row as it lands, so a retry
after a partial failure resumes rather than duplicating. A duplicated
`plantar_swe_records` row is not a cosmetic defect — it is a second foot scan
that never happened, entering the patient's clinical history.

### Sync triggers

| Trigger | Backoff |
|---|---|
| Connectivity transition to online | Ignored — the cause of failure has likely just cleared |
| Background task, 15-minute cadence | Respected |
| Application resumed to foreground | Respected |
| Operator action — "Sync now" | Ignored — the operator has better information |

Re-entrant calls do not stack. A sync requested while one is in flight is
coalesced into a single follow-up run.

---

## 6. Local persistence

| Property | Specification |
|---|---|
| Engine | Drift over SQLite |
| Encryption | At rest, platform keystore |
| Credentials | Platform secure storage, never in the database |
| Schema versioning | Explicit, with migrations |
| Cache tables | Rebuilt on migration |
| **Outbox tables** | **Migrated in place, never dropped** |

Cached server data may be rebuilt freely. The outbox holds captures that exist
nowhere else in the world until they sync — those rows are migrated column by
column, never recreated.

---

## 7. Configuration

No client hardcodes an endpoint. All configuration resolves through
environment files:

| Key | Purpose |
|---|---|
| `PB_BASE_URL` | Backend API gateway |
| `PB_LAN_URL` | Field-camp fallback for deployments with no uplink |
| `API_BASE_URL` | Inference and token services |
| `LIVEKIT_URL` | Tele-consultation signalling |

A runtime toggle allows an operator to switch between the public gateway and a
local server without rebuilding — the field-camp case, where a clinic runs its
own backend on a laptop with no internet at all.

---

## 8. Implementation status

| Component | Status |
|---|---|
| Domain layer — triage engine, packet decoder, constants | Implemented, **63 tests passing** |
| Data layer — repositories, local store, sync engine | Implemented and unit-tested |
| Authentication and role-protected routing | Implemented, verified against production |
| Clinical Diagnostic Suite (Android) | Implemented, verified on device |
| Specialist Clinical Workstation (Web) | **Live in production** |
| Static analysis | Clean on both shipped clients |
| **Patient Health Companion** | **Not implemented** |
| iOS build | Configured, never built |

Two of the three clients are shipped. The Patient Health Companion is specified
in [patient-app/README.md](patient-app/README.md); its backend role,
authentication and longitudinal record already exist in production.
