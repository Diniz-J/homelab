# Backup and restore drill

A `CronJob` snapshots the cluster's declarative state daily at 03:00 UTC
and pushes a tarball to MinIO. Restore is a `kubectl apply` on the
decrypted archive. This doc is the runbook; the drill is part of the
check we run after every major change.

## What's in a backup

- Every namespaced resource of the kinds the dump script lists
  (`deployment`, `statefulset`, `configmap`, `secret`, `ingress`,
  `pvc`, `serviceaccount`, `role`/`rolebinding`, `application`,
  `servicemonitor`, `prometheusrule`, `certificate`, `clusterissuer`,
  …).
- Every object is exported with its `metadata.namespace`, so a restore
  is reproducible without renaming things.

What's **not** in a backup:

- The k3s datastore itself (SQLite/etcd). The cluster is rebuilt from
  `terraform apply`; the backup restores the state **on top of** a
  fresh cluster.
- Data in PVCs (MinIO's own objects, Loki chunks, Prometheus TSDB).
  These are regenerated or accepted as lost in a lab.

## Where it goes

- `s3://homelab-backup/homelab-<timestamp>.tgz` inside the in-cluster
  MinIO. 30-day lifecycle rule applied on first run.
- A cold copy on your laptop via `rclone`, pulled on demand:

      rclone sync minio:homelab-backup ./homelab-backups

  The `minio` remote is a standard rclone S3 target pointing at the
  console URL with the root credentials.

## Run it ad-hoc

```
kubectl --context k3d-homelab -n minio create job backup-adhoc \
  --from=cronjob/homelab-backup
kubectl --context k3d-homelab -n minio logs -f job/backup-adhoc
```

## Restore drill

Every major infra change should end with one of these. Aim for a
**measured** run — write the elapsed time in the PR description.

### 1. Pick an archive

```
kubectl --context k3d-homelab -n minio run mc --rm -it --restart=Never \
  --image=minio/mc:RELEASE.2024-10-29T15-34-59Z -- sh
mc alias set minio http://minio:9000 minioadmin minioadmin123
mc ls minio/homelab-backup
```

### 2. Download and extract

```
mc cp minio/homelab-backup/homelab-<timestamp>.tgz /tmp/
tar -xzf /tmp/homelab-<timestamp>.tgz -C /tmp/
ls /tmp/backup-<timestamp>/
```

### 3. Apply order matters

1. `namespace.yaml`
2. `serviceaccount.yaml`, `role.yaml`, `rolebinding.yaml`,
   `clusterrole.yaml`, `clusterrolebinding.yaml`
3. `secret.yaml`, `configmap.yaml`
4. `persistentvolumeclaim.yaml`
5. `clusterissuer.yaml`, `certificate.yaml`
6. `service.yaml`, `ingress.yaml`
7. `deployment.yaml`, `statefulset.yaml`, `daemonset.yaml`
8. `cronjob.yaml`
9. `servicemonitor.yaml`, `podmonitor.yaml`, `prometheusrule.yaml`
10. `application.yaml`, `applicationset.yaml` (ArgoCD takes over from
    here)

Apply each with:

```
kubectl --context k3d-homelab apply -f /tmp/backup-<timestamp>/<kind>.yaml
```

Expect warnings about `ownerReferences` pointing at objects not yet
present — those resolve as later files land.

### 4. Verify

```
kubectl --context k3d-homelab -n argocd get applications
# All should be Synced + Healthy within a couple of minutes.

kubectl --context k3d-homelab get nodes
curl -k https://go-sample.homelab.localhost:8443/healthz
```

## Measured runs

| Date | Archive | Duration | Notes |
|---|---|---|---|
| _TBD_ | first drill | | |
