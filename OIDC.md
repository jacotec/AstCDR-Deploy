# Single sign-on (OIDC)

AstCDR supports generic OpenID Connect. It is verified with **Nextcloud**,
**Authentik** and **Keycloak**, but any standards-compliant provider works. You
can run OIDC alongside the local break-glass admin (`auth.mode: both`) — keep at
least one local admin as a fallback.

## How it fits together

1. In your identity provider (IdP) you register AstCDR as an **OIDC client /
   application** and get a **client ID** and **client secret**.
2. The **redirect URI** the IdP must allow is:
   ```
   {base_url}/auth/callback
   ```
   e.g. `https://cdr.example.com/auth/callback`.
3. You put the client details into `config.yaml` (`auth.oidc`) and the secret into
   `.env` (`OIDC_CLIENT_SECRET`).
4. **Who may sign in** is decided in the IdP (by assigning the app to users/groups),
   **not** in AstCDR. AstCDR only decides who becomes an **admin** (via
   `admin_groups`).

## Configuration block

```yaml
auth:
  mode: "both"            # oidc | local | both
  oidc:
    issuer: "https://auth.example.com/application/o/cdr-journal/"
    # server_metadata_url: ""     # see "Discovery URL" below
    client_id: "cdr-journal"
    client_secret: "${OIDC_CLIENT_SECRET}"
    scopes: ["openid", "profile", "email", "groups"]
    username_claim: "preferred_username"
    groups_claim: "groups"
    admin_groups: ["admin"]       # members of these groups become admins
    button_label: "Authentik"     # text on the login button
```

| Key | Meaning |
|-----|---------|
| `issuer` | The IdP issuer URL. |
| `server_metadata_url` | Discovery document URL. Leave empty for the OIDC standard `issuer/.well-known/openid-configuration`. **Nextcloud needs it explicitly** (see below). |
| `client_id` / `client_secret` | From the IdP. The secret comes via `${OIDC_CLIENT_SECRET}` from `.env`. |
| `scopes` | Request `openid profile email`; add `groups` if you use `admin_groups`. |
| `username_claim` | Which claim becomes the username (usually `preferred_username`). |
| `groups_claim` | Which claim carries group membership. |
| `admin_groups` | Users in any of these groups get the **admin** role; everyone else is a normal user. |
| `button_label` | Text on the login button. |

The **email** from the token links an OIDC user to a local user with the same
email (same identity, same saved preferences).

## Discovery URL (`server_metadata_url`)

- **Authentik / Keycloak:** leave `server_metadata_url` empty. AstCDR appends
  `/.well-known/openid-configuration` to the `issuer` automatically.
- **Nextcloud** ("OIDC Identity Provider" app) deviates from the standard path and
  needs the discovery URL **explicitly**, e.g.:
  ```yaml
  server_metadata_url: "https://cloud.example.com/index.php/apps/oidc/openid-configuration"
  ```
  The exact URL is shown in your Nextcloud OIDC settings. Open it in a browser — it
  must return JSON containing `authorization_endpoint` and `token_endpoint`.

---

## Provider quick notes

### Nextcloud
1. Install/enable the **OIDC Identity Provider** app.
2. Add a client: redirect URI `{base_url}/auth/callback`. Note the client ID/secret.
3. Make sure a **groups** claim is emitted if you want `admin_groups` to work.
4. Set `server_metadata_url` explicitly (see above).

### Authentik
1. Create an **OAuth2/OpenID Provider**, then an **Application** bound to it.
2. Redirect URI `{base_url}/auth/callback`.
3. `issuer` is the provider's issuer URL (e.g.
   `https://auth.example.com/application/o/<slug>/`). Leave `server_metadata_url`
   empty.
4. Add a **groups** scope/mapping if you use `admin_groups`.

### Keycloak
1. Create a **client** (type: OpenID Connect, confidential/standard flow).
2. Valid redirect URI `{base_url}/auth/callback`.
3. `issuer` is `https://<host>/realms/<realm>`. Leave `server_metadata_url` empty.
4. Add a **groups** mapper to the token if you use `admin_groups`.

---

## Checklist / troubleshooting

- **Redirect/callback mismatch:** the IdP's allowed redirect URI must be exactly
  `{base_url}/auth/callback`, and `base_url` must match what the reverse proxy
  serves (scheme + host).
- **No admin rights:** check that `groups` is in `scopes`, the `groups_claim`
  matches your IdP's claim name, and the user is in one of `admin_groups`.
- **"discovery failed" / cannot reach metadata:** verify the discovery URL returns
  JSON in a browser; for Nextcloud set `server_metadata_url` explicitly.
- **Login works but session drops:** ensure `base_url` is `https` in production so
  secure cookies are set correctly.

More general issues: [TROUBLESHOOTING.md](TROUBLESHOOTING.md).
