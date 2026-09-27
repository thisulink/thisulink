# THISULINK™ Infrastructure — Edge, Tunnel & Zero-Trust Operations

| | |
|---|---|
| **Document** | BE-INFRA-001 |
| **Scope** | Network topology, ingress, edge security, operations |
| **Automation** | [`deploy/`](../deploy/) |
| **Status** | Live — see §8 |

---

## 1. Topology

```
                         ┌──────────────┐
                         │   INTERNET   │
                         └──────┬───────┘
                                ▼
                    ┌───────────────────────┐
                    │   CLOUDFLARE EDGE     │
                    │   TLS · DDoS · WAF    │
                    └───────────┬───────────┘
                                │  outbound-initiated tunnel
                                │  (no inbound ports opened)
                                ▼
   ┌─────────────────────────────────────────────────────────────┐
   │  CLINICAL NODE — Linux                                       │
   │                                                              │
   │   ┌──────────────┐                                           │
   │   │ cloudflared  │  tunnel daemon, outbound only             │
   │   └──────┬───────┘                                           │
   │          │                                                   │
   │    ┌─────┴──────┬──────────────────┐                         │
   │    ▼            ▼                  ▼                         │
   │  :8080        :8091            (unrouted)                    │
   │  nginx        nginx                                          │
   │  static       reverse proxy                                  │
   │  web bundle   │  404 /_/                                     │
   │               │  404 /api/admins                             │
   │               │  no buffering on /api/realtime               │
   │               ▼                                              │
   │            :8090  PocketBase ── pb_data (SQLite)             │
   │                        ▲                                     │
   │  ufw: deny all inbound │ except tailscale0 + SSH             │
   └────────────────────────┼─────────────────────────────────────┘
                            │
                   ┌────────┴─────────┐
                   │ TAILSCALE MESH   │  administration console
                   │ 100.x.y.z:8090/_/│  reachable ONLY here
                   └──────────────────┘
```

### Why an outbound tunnel

The node opens **no inbound ports**. `cloudflared` establishes outbound
connections to the edge and traffic returns over them. Consequences:

- No port forwarding, no static IP, no firewall exception
- The origin address is not published and cannot be scanned
- Works behind NAT and on residential or institutional connections
- TLS terminates at the edge on a managed certificate

---

## 2. Public routing

| Hostname | Origin | Serves |
|---|---|---|
| `thisulink.xyz` | `127.0.0.1:8080` | Specialist Clinical Workstation |
| `www.thisulink.xyz` | `127.0.0.1:8080` | Same |
| `doctor.thisulink.xyz` | `127.0.0.1:8080` | Named workstation ingress |
| `pb.thisulink.xyz` | `127.0.0.1:8091` | PocketBase REST + SSE gateway |
| *(catch-all)* | — | `HTTP 404` |

DNS records are proxied CNAMEs to the tunnel. Every origin listens on
**loopback only** — even on the local network, the services are unreachable
except through the tunnel or the mesh.

### Static site configuration

| Requirement | Reason |
|---|---|
| SPA fallback to `index.html` | A refresh on a deep route must not 404 |
| Hashed assets: `immutable`, 30 days | Build artefacts never change |
| `index.html`: `no-store` | Otherwise a deploy leaves browsers on the old bundle |
| Service worker: `no-store` | Same |
| gzip on JS/CSS/WASM/SVG | The bundle is ~4.2 MB uncompressed; deployments are bandwidth-constrained |

---

## 3. Backend gateway — `:8091`

PocketBase is **not** exposed directly. A reverse proxy sits between the tunnel
and the service.

| Path | Behaviour |
|---|---|
| `/_/`, `/_/*` | **404** |
| `/api/admins` | **404** |
| `/api/realtime` | Proxied, **buffering disabled**, 3600 s read timeout |
| everything else | Proxied, 120 s timeout, 12 MB body limit |

### Administration console

Blocked at the proxy, not hidden by obscurity. The console is reachable **only**
over the Tailscale mesh, by connecting to `:8090` directly:

```
   http://100.x.y.z:8090/_/
```

`/api/admins` is blocked alongside it — blocking the console while leaving the
admin authentication API reachable would be theatre.

### Realtime buffering

The SSE stream must not be buffered. A buffered stream produces the platform's
most deceptive failure: the physician queue stops updating while every health
check reports normal and no error appears anywhere. Deployment verification
asserts that the stream delivers its connection frame end to end.

### Body limit

12 MB accommodates fundus images at the 10 MB collection limit plus multipart
overhead.

---

## 4. Firewall

| Rule | Scope |
|---|---|
| Default | **Deny all inbound** |
| Allow | `tailscale0` interface — the private mesh |
| Allow | UDP 41641 — Tailscale direct connections |
| Allow | SSH |
| Outbound | Permitted |

The mesh interface is allowed as a whole rather than per-port, because mesh
membership is itself the authentication boundary.

> **Operational practice.** Enabling a default-deny firewall over a remote
> session can sever that session. The production change was applied behind a
> timed rollback: a scheduled `ufw disable` five minutes out, cancelled only
> after connectivity was independently re-verified. Any future firewall change
> should use the same pattern.

---

## 5. Service topology

```
/opt/thisulink/
├── backend/
│   ├── pocketbase            binary, v0.22.21
│   ├── pb_data/              SQLite database and file storage
│   ├── pb_migrations/        schema
│   └── pb_hooks/
│       ├── triage.pb.js        handler registrations
│       └── thisulink_triage.js triage engine module
└── doctor_portal/build/web/  Flutter Web bundle
```

| Unit | Function |
|---|---|
| `thisulink-pocketbase` | Backend service |
| `nginx` | Static site and backend gateway |
| `cloudflared` | Tunnel daemon |

### Hardening

| Directive | Effect |
|---|---|
| `User` / `Group` | Dedicated non-root service account |
| `ProtectSystem=strict` | Filesystem read-only except `ReadWritePaths` |
| `ProtectHome=true` | No access to user home directories |
| `NoNewPrivileges=true` | No privilege escalation |
| `PrivateTmp=true` | Isolated temporary directory |
| `ProtectKernelTunables` / `Modules` | No kernel surface |
| `RestrictSUIDSGID`, `LockPersonality` | Reduced attack surface |

The service holds patient records; a compromise should reach its own directory
and nothing else.

### Watchdog

| Directive | Value |
|---|---|
| `Restart` | `always` |
| `RestartSec` | 5 s |
| `WantedBy` | `multi-user.target` — starts on boot |

The tunnel daemon reconnects automatically after network loss; no intervention
is required after a connectivity interruption.

> **Diagnostic note.** A restart loop with `Restart=always` is silent unless
> looked for. During deployment, a pre-existing PocketBase instance bound to
> loopback held port 8090; the new unit failed `address already in use` and
> restarted **228 times** while the health endpoint answered — from the *other*
> process. `systemctl is-active` reported `activating`, not `failed`. Check
> `NRestarts`, not just active state.

---

## 6. Deployment automation

| Script | Function |
|---|---|
| [`bootstrap.sh`](../deploy/bootstrap.sh) | Provisions instance, unit, nginx, tunnel ingress |
| [`finish.sh`](../deploy/finish.sh) | Installs bundle, applies firewall, verifies schema |
| [`seed.sh`](../deploy/seed.sh) | Provisions accounts and clinical dataset (idempotent) |
| [`fix_rbac.sh`](../deploy/fix_rbac.sh) | Repairs role schema and rewrites rules as allowlists |
| [`verify.sh`](../deploy/verify.sh) | Post-deploy assertions |

### Verification assertions

- Local origins answer — backend, static site
- All service units active
- Public hostnames resolve and answer through the edge
- **`/_/` is NOT publicly reachable** — hard failure if it is
- **SSE stream delivers its connection frame** through the tunnel
- All eight collections exist

The console-exposure and SSE assertions exist because both are silent failures:
one exposes an administration surface with no visible symptom, the other breaks
the physician queue while appearing healthy.

---

## 7. Availability & backup

### Current posture — honest assessment

| Property | State |
|---|---|
| Host | **Single node. No redundancy.** |
| Uptime dependency | Node powered on and connected |
| Tunnel reconnection | Automatic |
| Service restart | Automatic |
| **Database backup** | **Not configured** |

> **Observed.** During commissioning the node went offline mid-session; both
> public hostnames returned HTTP 530 until it returned, then recovered
> automatically with no intervention. A single node is a single point of
> failure, and a platform positioned for clinical networks needs this addressed
> before carrying real patient data.

### Required backup strategy

PocketBase exposes a consistent snapshot API rather than requiring a file copy
of a live SQLite database — copying `pb_data` while the service runs can
capture a torn write.

| Element | Specification |
|---|---|
| Method | PocketBase backup API — consistent snapshot |
| Frequency | Nightly, plus before every migration |
| Retention | 30 daily, 12 monthly |
| Off-node copy | **Mandatory** — a backup on the failing disk is not a backup |
| Encryption | At rest; snapshots contain PHI |
| **Restore drill** | Quarterly — an untested backup is a hypothesis |

### Recommended hardening

1. Automated encrypted off-node backups — **highest priority**
2. Migrate off the laptop to always-on hardware or a managed host
3. External uptime monitoring with alerting on the 530 condition
4. Log shipping — journal-only logs are lost with the node
5. Documented restore runbook with a measured recovery time

---

## 8. Status

| Item | State |
|---|---|
| Tunnel and public routing | **Live** — 4 hostnames |
| TLS | Managed at the edge |
| Administration console isolation | **Verified — 404 public, mesh-only** |
| Firewall default-deny | **Active** |
| Service hardening | **Applied** |
| Watchdog and auto-restart | **Active** |
| Deployment automation | Complete |
| Verification suite | Complete |
| **Automated backups** | **Not configured** |
| **Redundancy** | **None — single node** |
| **External monitoring** | **Not configured** |

The security posture is production-grade. The **availability** posture is not,
and the gap is deliberate to state plainly: backups and redundancy are the two
items standing between this deployment and one that can hold real patient
records.
