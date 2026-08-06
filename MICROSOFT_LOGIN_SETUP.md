# Microsoft / organization sign-in — setup

The app already has the **Continue with Microsoft** button and all the code
behind it. It stays a demo login until you connect it to Microsoft, which takes
two console visits: register the app in Azure, then paste two values into
Firebase.

Nothing here can be done for you — both consoles are tied to your identity.

---

## Step 1 — Register the app in Azure (Microsoft Entra ID)

1. Go to <https://portal.azure.com> and sign in with the Microsoft account that
   owns your organization (for SPTECH USA, your work account).
2. Search for **Microsoft Entra ID** → open it.
3. Left menu → **App registrations** → **+ New registration**.
4. Fill in:
   - **Name:** `Anthropic Arena`
   - **Supported account types:** pick one —
     - *Accounts in any organizational directory and personal Microsoft accounts*
       → anyone from any company (recommended, matches the app default)
     - *Accounts in this organizational directory only* → SPTECH USA staff only
   - **Redirect URI:** platform **Web**, value:
     ```
     https://anthropic-arena.firebaseapp.com/__/auth/handler
     ```
5. Click **Register**.
6. On the overview page, copy the **Application (client) ID** — you need it in
   step 2. (Also copy the **Directory (tenant) ID** if you want to lock sign-in
   to your company only — see step 4.)
7. Left menu → **Certificates & secrets** → **+ New client secret** →
   description `Firebase`, expiry 24 months → **Add**.
   **Copy the secret Value immediately** (not the "Secret ID") — Azure hides it
   once you leave the page.

---

## Step 2 — Turn Microsoft on in Firebase

1. Open <https://console.firebase.google.com/project/anthropic-arena/authentication/providers>
2. **Add new provider** → **Microsoft**.
3. Toggle **Enable**, then paste:
   - **Application ID** → the *Application (client) ID* from step 1.6
   - **Application Secret** → the secret *Value* from step 1.7
4. **Save**.

That's it — the button becomes a real Microsoft login immediately, no app
rebuild needed. Test it at <https://anthropic-arena.web.app>.

---

## Step 3 — Check the authorised domains

Still in Firebase Authentication → **Settings** → **Authorised domains**.
`anthropic-arena.web.app` and `anthropic-arena.firebaseapp.com` should already
be listed. Add any custom domain you later point at the app, or sign-in will
fail with *"This site isn't on the Firebase authorised-domains list yet."*

---

## Step 4 — (Optional) Restrict who can sign in

Open [lib/core/auth_config.dart](lib/core/auth_config.dart) and set
`microsoftTenant`:

| Value | Who can sign in |
| --- | --- |
| `'common'` *(default)* | Any organization's work/school account **and** personal Microsoft accounts |
| `'organizations'` | Any organization's work/school account; personal accounts blocked |
| `'consumers'` | Personal Microsoft accounts only |
| `'<your tenant id>'` | **One** company only — paste the *Directory (tenant) ID* from step 1.6 |

Then rebuild and redeploy:

```powershell
flutter build web --release
firebase deploy --only hosting
```

This is a convenience filter on the sign-in screen. For a hard guarantee, also
set *Supported account types* correctly in step 1.4 — Azure enforces that one.

---

## Notes

- **Web works today.** Android/iOS fall back to a local demo account for
  Microsoft (same as Google) until those platforms get native OAuth wiring —
  ask and it can be added.
- **Microsoft accounts are real accounts**: they appear on the global
  leaderboard and unlock the Certifications tab, unlike guest sessions.
- **Same person, two providers:** if someone signs up with Google using
  `name@company.com` and later clicks Microsoft with the same address, Firebase
  reports *account-exists-with-different-credential* and the app tells them to
  sign in the way they did the first time. To merge them instead, enable
  "Link accounts that use the same email" in Firebase Authentication settings.
