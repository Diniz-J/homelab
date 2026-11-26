# Alerting via Telegram

Alertmanager routes all alerts to a Telegram chat. The receiver uses a
bot you create once; the bot token and chat id never live in plaintext
git.

## Create the bot

1. On Telegram, open [@BotFather](https://t.me/BotFather).
2. `/newbot`, pick a name, pick a username ending in `bot` (e.g.
   `homelab_alerts_bot`).
3. BotFather returns a **bot token** — long string like
   `123456:ABC-DEF...`. Keep it around; you'll paste it into SOPS in a
   minute.

## Create the chat and get its id

1. Create a Telegram group (or use a private DM with the bot).
2. Add the bot to the group as a member.
3. Send any message in the chat.
4. Fetch the chat id:

   ```
   curl -s "https://api.telegram.org/bot<TOKEN>/getUpdates" | jq '.result[].message.chat'
   ```

   Group ids are negative integers; private-chat ids are positive.

## Build the Alertmanager config

This is the whole Alertmanager configuration — Prometheus Operator
mounts it from a `Secret` named `alertmanager-telegram` in the
`monitoring` namespace. The kube-prometheus-stack Application is
already wired to that `configSecret`.

Create `secrets/alertmanager-telegram.enc.yaml` with SOPS:

```
sops secrets/alertmanager-telegram.enc.yaml
```

Paste this, replacing `<BOT_TOKEN>` and `<CHAT_ID>`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: alertmanager-telegram
  namespace: monitoring
type: Opaque
stringData:
  alertmanager.yaml: |
    global:
      resolve_timeout: 5m
    route:
      receiver: telegram
      group_by: [alertname, severity]
      group_wait: 30s
      group_interval: 5m
      repeat_interval: 4h
      routes:
        - matchers:
            - severity = "info"
          receiver: telegram
          group_wait: 1m
          repeat_interval: 24h
    receivers:
      - name: telegram
        telegram_configs:
          - send_resolved: true
            bot_token: "<BOT_TOKEN>"
            chat_id: <CHAT_ID>
            parse_mode: HTML
            message: |
              <b>[{{ .Status | toUpper }}]</b> {{ .CommonLabels.alertname }}
              {{ range .Alerts }}
              • <i>{{ .Annotations.summary }}</i>
              {{ .Annotations.description }}
              {{ end }}
    inhibit_rules:
      - source_matchers: [severity = "critical"]
        target_matchers: [severity = "warning"]
        equal: [alertname, namespace]
```

Save, exit. The file on disk is now encrypted.

## Apply

The ArgoCD + SOPS wiring exists (see
[`docs/secrets.md`](secrets.md) and
[ADR 0005](adr/0005-argocd-sops-integration.md)) but
`k8s/apps/_root/kube-prometheus-stack.yaml` doesn't reference the
KSOPS generator yet. Until that follow-up PR lands, apply the
encrypted Secret manually:

```
sops --decrypt secrets/alertmanager-telegram.enc.yaml \
  | kubectl --context k3d-homelab apply -f -

kubectl --context k3d-homelab -n monitoring rollout restart \
  statefulset/alertmanager-kps-alertmanager
```

ArgoCD then takes over keeping the Alertmanager pod itself in sync; the
`Secret` stays out-of-band.

## Verify

Hit `/boom` on the demo workload and wait a couple of minutes:

```
curl -k https://go-sample.homelab.localhost:8443/boom
```

The `GoSampleBoomed` alert fires, and a Telegram message lands.

## Rotate

Rotate the bot token via BotFather (`/revoke`), re-edit the SOPS file
with the new token, re-apply.
