# THISULINK production deployment

Everything needed to stand the backend up on the Linux laptop and put it
behind `thisulink.xyz`. **None of this has been executed** — it was authored
on a Windows workstation with no access to the host, so treat the first run as
a real deployment, not a replay.

---

## Ingress map

| Public hostname | Origin | Serves |
|---|---|---|
| `thisulink.xyz` | Nginx `127.0.0.1:8080` | Doctor portal (Flutter Web bundle) |
| `pb.thisulink.xyz` | PocketBase `127.0.0.1:8090` | Auth, records, files, realtime SSE |
| `api.thisulink.xyz` | Express `127.0.0.1:8787` | ONNX retinal inference, LiveKit tokens |
| — | Tailscale `100.x.y.z:8090/_/` | PocketBase admin UI — **never routed publicly** |

Every origin listens on loopback. The only way in is the tunnel, or the
Tailscale mesh for the admin UI. `verify.sh` fails the deploy if `/_/` ever
answers on the public hostname.

## Files

| File | Install to |
|---|---|
| [`systemd/pocketbase.service`](systemd/pocketbase.service) | `/etc/systemd/system/` |
| [`systemd/thisulink-api.service`](systemd/thisulink-api.service) | `/etc/systemd/system/` |
| [`nginx/doctor-portal.conf`](nginx/doctor-portal.conf) | `/etc/nginx/sites-available/doctor-portal` |
| [`cloudflared/config.yml`](cloudflared/config.yml) | `/etc/cloudflared/config.yml` |
| [`pocketbase/1727000000_thisulink_unified_schema.js`](pocketbase/) | `/opt/thisulink/backend/pb_migrations/` |
| [`../thisulink_app/pb_hooks/triage.pb.js`](../thisulink_app/pb_hooks/triage.pb.js) | `/opt/thisulink/backend/pb_hooks/` |
| [`install.sh`](install.sh) | run as root |
| [`verify.sh`](verify.sh) | run after, and after every deploy |

## Order of operations

```bash
# 1. Put the payloads in place on the Linux laptop
#    /opt/thisulink/backend/pocketbase          (binary, chmod +x)
#    /opt/thisulink/api/src/index.js            (Express service)
#    /opt/thisulink/doctor_portal/build/web/    (flutter build web --release)
#    /etc/thisulink/api.env                     (LiveKit key + secret, mode 0600)

# 2. Schema and triage hook
sudo cp deploy/pocketbase/*.js /opt/thisulink/backend/pb_migrations/
sudo cp thisulink_app/pb_hooks/triage.pb.js /opt/thisulink/backend/pb_hooks/

# 3. Services, Nginx, firewall
sudo ./deploy/install.sh

# 4. Cloudflare tunnel
sudo cp deploy/cloudflared/config.yml /etc/cloudflared/config.yml
sudo sed -i "s/YOUR_TUNNEL_UUID/<uuid>/g" /etc/cloudflared/config.yml
cloudflared tunnel route dns thisulink thisulink.xyz
cloudflared tunnel route dns thisulink pb.thisulink.xyz
cloudflared tunnel route dns thisulink api.thisulink.xyz
sudo systemctl restart cloudflared

# 5. CORS — admin UI over Tailscale only
#    Settings -> Application -> CORS allowed origins: https://thisulink.xyz

# 6. Verify
./deploy/verify.sh
```

## Notes that will bite you otherwise

**PocketBase version.** The migration is written against the v0.22.x API
(`Dao`, `new Collection({...})`). v0.23 renamed these to `app.findCollection*`.
Check `pocketbase --version` before the first boot — a migration that throws
halfway leaves a partial schema.

**Realtime through the tunnel.** `/api/realtime` is a long-lived SSE stream.
If it is cut, the doctor's triage queue stops updating and nothing in the UI
says so — it just looks quiet. `verify.sh` checks for the `PB_CONNECT` frame
specifically for this reason.

**CORS looks like an outage.** Without the portal origin in PocketBase's CORS
list the browser blocks every request, and the portal reports "cannot reach
the server". Check CORS before you start debugging the tunnel.

**Secrets.** The LiveKit API secret lives in `/etc/thisulink/api.env`, mode
0600, read by the Express unit through `EnvironmentFile`. It must never reach
a browser — the portal asks the server to mint join tokens precisely so the
secret stays here.

**The services do not run as root.** `install.sh` creates a `thisulink` system
account and both units are confined with `ProtectSystem=strict` and an
explicit `ReadWritePaths`. If you move the data directory, move that too or
PocketBase will fail to write.

## Verification

`verify.sh` covers Section 4.1 of the deployment spec and a few things it did
not ask for:

- local origins answer (PocketBase, Nginx, Express)
- all four systemd units are active
- the three public hostnames answer through Cloudflare
- **`/_/` is not publicly reachable** (a hard failure if it is)
- the SSE realtime stream delivers `PB_CONNECT` through the tunnel
- PocketBase returns a CORS header for the portal origin
- all eight collections exist

Sections 4.2 and 4.3 — the airplane-mode offline round trip and the live
triage-queue update — need a phone, a browser and a running backend, so they
stay manual. The app side of 4.2 is implemented and unit-tested; what has
never been observed is the round trip itself.
