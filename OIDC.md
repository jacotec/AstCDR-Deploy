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
| `link_by_unverified_email` | Link to an existing account by email even without an `email_verified` claim. Off by default — see [Account linking](#account-linking). |

## Account linking

An OIDC login is matched to an existing account in this order:

1. by the IdP's **`sub`** (stable per user *and* per IdP),
2. by **email** — but only if the IdP asserts `email_verified`,
3. otherwise a **new account** is created. If the username is already taken, it gets a
   short suffix (`marco#5dd4c35a`) so the two accounts stay apart.

That's why step 2 matters: `sub` is *not* stable across IdPs. If you **switch provider**
(or move from local logins to OIDC), every user arrives with a brand-new `sub`, and
without the email match they land in a fresh account — the suffixed one — leaving their
saved filters, columns and email preferences behind on the old account.

> **authentik does not send `email_verified`** — deliberately, because it hasn't
> verified the address. Keycloak has a per-user switch for it. So on authentik, step 2
> never fires and a provider switch produces duplicates.

Set **`link_by_unverified_email: true`** to allow step 2 without the claim. It is off by
default for a reason: if your IdP lets people **self-register**, someone could sign up
with a colleague's address and take over that account on first login. Only enable it
when addresses are assigned administratively.

**Recommended for a migration:** switch it on, let everyone log in once (they keep their
accounts and settings), then switch it off again. New users are unaffected either way —
they have no existing account to link to.

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
   Note: Nextcloud typically returns groups from the **`userinfo` endpoint**
   (not inside the id_token) — enable the group sharing / `groups` scope on the
   client. AstCDR reads them from userinfo automatically.
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
  matches your IdP's claim name, and the user is in one of `admin_groups`. The
  role is applied on **(re-)login** — sign out and back in after group changes.
- **See what the IdP actually sent:** `docker compose logs cdrj-web | grep OIDC-Login`
  prints the received claim keys, the group value and the resulting role — the
  fastest way to see why a mapping didn't take.
- **"discovery failed" / cannot reach metadata:** verify the discovery URL returns
  JSON in a browser; for Nextcloud set `server_metadata_url` explicitly.
- **Login works but session drops:** ensure `base_url` is `https` in production so
  secure cookies are set correctly.

More general issues: [TROUBLESHOOTING.md](TROUBLESHOOTING.md).
