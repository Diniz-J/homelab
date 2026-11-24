# Importing the `homelab-ca` into your trust store

The lab issues every local certificate from the `homelab-ca`
`ClusterIssuer` (see [ADR 0004](adr/0004-local-first-homelab.md) and the
[`cluster-issuers`](../k8s/apps/cluster-issuers/) manifests). Browsers
and most CLI tools don't trust it until you add the CA certificate to
your OS trust store.

## 1. Export the CA certificate

Pull the CA bundle out of the `homelab-ca-key-pair` `Secret` that
cert-manager keeps in the `cert-manager` namespace:

```
kubectl --context k3d-homelab -n cert-manager \
  get secret homelab-ca-key-pair \
  -o jsonpath='{.data.ca\.crt}' \
  | base64 --decode > homelab-ca.crt
```

On Windows PowerShell:

```powershell
$crt = kubectl --context k3d-homelab -n cert-manager `
  get secret homelab-ca-key-pair `
  -o jsonpath='{.data.ca\.crt}'
[System.Text.Encoding]::ASCII.GetString(
  [System.Convert]::FromBase64String($crt)
) | Set-Content -Encoding Ascii homelab-ca.crt
```

Inspect it:

```
openssl x509 -in homelab-ca.crt -noout -subject -issuer -dates
```

Subject and issuer should both read `CN = homelab-ca`, and the `notAfter`
should be roughly ten years from now.

## 2. Install it

### Windows

Right-click the `.crt` file → **Install Certificate**, pick
**Local Machine** (needs admin) or **Current User**, pick
**Place all certificates in the following store** → **Trusted Root
Certification Authorities**, finish.

Or scripted:

```powershell
Import-Certificate -FilePath .\homelab-ca.crt `
  -CertStoreLocation Cert:\CurrentUser\Root
```

### macOS

```
sudo security add-trusted-cert -d -r trustRoot \
  -k /Library/Keychains/System.keychain homelab-ca.crt
```

### Linux (Debian/Ubuntu)

```
sudo cp homelab-ca.crt /usr/local/share/ca-certificates/homelab-ca.crt
sudo update-ca-certificates
```

### Linux (Fedora/RHEL)

```
sudo cp homelab-ca.crt /etc/pki/ca-trust/source/anchors/homelab-ca.crt
sudo update-ca-trust
```

### Firefox (any OS)

Firefox ships its own trust store and ignores the OS one by default.
Fix it per-profile (**Settings → Privacy & Security → Certificates →
View Certificates → Authorities → Import**) or set
`security.enterprise_roots.enabled = true` in `about:config` so
Firefox picks the OS trust store up.

## 3. Verify

```
curl https://go-sample.homelab.localhost:8443/healthz
```

No `-k` needed. The response is `ok`; the connection shows
`SSL certificate verify ok` under `-v`.

## Rotating

The CA is a 10-year ECDSA key. Rotate by deleting the `homelab-ca`
`Certificate` and re-creating it; cert-manager mints a new CA, every
downstream certificate gets re-issued, and you re-run step 1 on every
machine that had the old CA installed.

For a lab, you'll run this once and forget it.
