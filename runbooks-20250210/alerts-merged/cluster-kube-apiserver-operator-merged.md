Original Filename:  AuditLogError.md

# AuditLogError

## Meaning

This alert is triggered when an API Server instance in the cluster is unable
to write audit logs. It fires when there's any errors, which is calculated
by checking the error rate with `apiserver_audit_error_total` and `apiserver_audit_event_total`.

There might be many causes to this:

* This might have been caused by the node that host's that API Server instance
  running out of disk space.

* A malicious actor could be tampering with the audit log files or directory
  permissions

* The API server might be encountering an unexpected error.

## Impact

When there are errors writing audit logs, security events will not be logged
by that specific API Server instance. Security Incident Response teams use
these audit logs, amongst other artifacts, to determine the impact of
security breaches or events. Without these logs, it becomes very difficult
to assess a situation and do appropriate root cause analysis in such incidents.

However, this is not detrimental to the cluster's availability.

## Diagnosis

Verify if there are other alerts being triggered, e.g. the
`NodeFilesystemFillingUp` alert. This might indicate what's causing this error.

The metric `apiserver_audit_error_total` will only show up on instances
that are experiencing errors. There will be appropriate labels that indicate
the API Server type and the specific instance that's affected.

With this information, gather the runtime logs from that specific api server
pod, and verify if the logs indicate an unexpected error.

From the `instance` label, it's possible to determine what node is hosting
the aforementioned affected API Server.

Log into the appropriate node and Verify that the relevant audit log file
permissions are what's expected:
Owned by the `root` user and with a mode of `0600`. Make sure as well that
there aren't unexpected attributes for the files, such as immutability or append-only.

While logged into the appropriate node, also verify that the relevant audit
log directory permissions are what's expected:
Owned by the `root` user and with a mode of `0700`.

If you suspect tampering is happening, contact your incident response team.

## Mitigation

The appropriate mitigation will be very different depending on the organization
and the compliance requirements. A FedRAMP moderate deployment might need to
isolate the node and investigate, while deployment with more strict compliance
requirements would need to snapshot and shut down the system immediately.
A more usual deployment might just need to investigate, and since the causes
could be many. Regardless, investigate the deployment as described in the
diagnosis, and contact the incident response team in your organization if
necessary.



------------------------------


Original Filename:  ExtremelyHighIndividualControlPlaneCPU.md

# ExtremelyHighIndividualControlPlaneCPU

## Meaning

[This alert][ExtremelyHighIndividualControlPlaneCPU] is triggered when there
is a sustained high CPU utilization on a single control plane node.

The urgency of this alert is determined by how long the node is
sustaining high CPU usage:

* Critical
  * when CPU usage on an individual control plane node is greater than
    `90%` for more than `1h`.

* Warning
  * when CPU usage on an individual control plane node is greater than
    `90%` for more than `5m`.


[This alert][HighOverallControlPlaneCPU] is triggered when CPU utilization
across all three control plane nodes is higher than two control plane nodes
can sustain; a single control plane node outage may cause
a cascading failure; increase available CPU.

The urgency of this alert is determined by how long CPU utilization across all
three control plane nodes is higher than two control plane nodes can sustain.

* Warning
  * when CPU utilization across all three control plane nodes is higher than
    two control plane nodes can sustain for more than `10m`.
  

## Impact

Extreme CPU pressure can cause slow serialization and poor performance from
the `kube-apiserver` and `etcd`. When this happens, there is a risk of
clients seeing non-responsive API requests which are issued again
causing even more CPU pressure.

It can also cause failing liveness probes due to slow etcd responsiveness on
the backend. If one kube-apiserver fails under this condition, chances are
you will experience a cascade as the remaining kube-apiservers
are also under-provisioned.

To fix this, increase the CPU and memory on your control plane nodes.

## Diagnosis

The following prometheus queries can be used to diagnose:
```sh
// Top 5 of containers with the most CPU utilization on a particular node
topk(5,
  sum by (namespace, pod, container) (
    irate (container_cpu_usage_seconds_total{node="NODE_NAME",container!="",pod!=""}[4m])
  )
)

// CPU utilization of containers on master nodes
sum by (node) (
  irate (container_cpu_usage_seconds_total{container!="",pod!=""}[4m])
    and on (node) cluster:master_nodes
)

// CPU utilization of the master nodes from the cgroups
sum by (node) (
  1 - irate(
    node_cpu_seconds_total{mode="idle"}[4m]
  )
  * on(namespace, pod) group_left(node) (
    node_namespace_pod:kube_pod_info:
  )
  and on (node) (
    cluster:master_nodes
  )
)

// for Windows
sum by (node) (
  1 - irate(
    windows_cpu_time_total{mode="idle", job="windows-exporter"}[4m]
  )
  and on (node) (
    cluster:master_nodes
  )
)
```

These are the conditions that could trigger the alert:

- there is a new workload that is generating more calls to the apiserver
  and causing high CPU usage. In this case, increase the CPU and
  memory on your control plane nodes.
- the alert is triggered based on the node metrics, so it could be that a
  component on the node is causing the high CPU usage.
- apiserver/etcd is processing more requests due to client retries that is
  being caused by an underlying condition.
- uneven distribution of requests to the apiserver instance(s) due to http2
  (it multiplexes requests over a single TCP connection). The load balancers
  are not at application layer, and so does not understand http2.


## Mitigation

- if a workload is generating load to the apiserver that is causing high CPU
  usage, then increase the CPU and memory on your control plane nodes.
- If the sustained high CPU usage is due to a cluster degradation:

  - find out the root cause of the degradation, and then
    determine the next steps accordingly.

If this needs to be reported, then capture the following dataset, and file
a new issue in BugZilla with links to the captured dataset:

- must-gather
- audit logs
- dump of prometheus data


How to gather the audit logs of the cluster:
```sh
oc adm must-gather -- /usr/bin/gather_audit_logs
```

How to take a dump of the cluster prometheus data:
```sh

#!/usr/bin/env bash

function queue() {
  local TARGET="${1}"
  shift
  local LIVE
  LIVE="$(jobs | wc -l)"
  while [[ "${LIVE}" -ge 45 ]]; do
    sleep 1
    LIVE="$(jobs | wc -l)"
  done
  echo "${@}"
  if [[ -n "${FILTER:-}" ]]; then
    "${@}" | "${FILTER}" >"${TARGET}" &
  else
    "${@}" >"${TARGET}" &
  fi
}

ARTIFACT_DIR=$PWD
mkdir -p $ARTIFACT_DIR/metrics
echo "Snapshotting prometheus (may take 15s) ..."
queue ${ARTIFACT_DIR}/metrics/prometheus.tar.gz oc --insecure-skip-tls-verify exec -n openshift-monitoring prometheus-k8s-0 -- tar cvzf - -C /prometheus .
FILTER=gzip queue ${ARTIFACT_DIR}/metrics/prometheus-target-metadata.json.gz oc --insecure-skip-tls-verify exec -n openshift-monitoring prometheus-k8s-0 -- /bin/bash -c "curl -G http://localhost:9090/api/v1/targets/metadata --data-urlencode 'match_target={instance!=\"\"}'"
```


[ExtremelyHighIndividualControlPlaneCPU]: https://github.com/openshift/cluster-kube-apiserver-operator/blob/master/bindata/assets/alerts/cpu-utilization.yaml
[HighOverallControlPlaneCPU]: https://github.com/openshift/cluster-kube-apiserver-operator/blob/master/bindata/assets/alerts/cpu-utilization.yaml



------------------------------


Original Filename:  KubeAPIErrorBudgetBurn.md

# KubeAPIErrorBudgetBurn

## Meaning

[These alerts][KubeAPIErrorBudgetBurn] are triggered when the Kubernetes API
server is encountering:

* Many 5xx failed requests and/or
* Many slow requests

The urgency of these alerts is determined by the values of their `long` and
`short` labels:

* Critical
  * `long`: 1h and `short`: 5m: less than ~2 days -- You should fix the problem
as soon as possible!
  * `long`: 6h and `short`: 30m: less than ~5 days -- Track this down now but no
immediate fix required.
* Warning
  * `long`: 1d and `short`: 2h: less than ~10 days -- This is problematic in the
long run. You should take a look in the next 24-48 hours.
  * `long`: 3d and `short`: 6h: less than ~30 days -- (the entire window of the
error budget) at this rate. This means that at the end of the next 30 days there
won't be any error budget left at this rate. It's fine to leave this over the
weekend and have someone take a look in the coming days at working hours.

Information in this runbook is derived from the
[upstream runbook][upstream runbook].

Note that in OCP 4.8, these alerts have been [rewritten][alert PR], so they are
no longer the same as the upstream ones.

## Impact

The overall availability of the cluster isn't guaranteed anymore. The API
server is returning too many errors and/or responses are taking too long for
guarantee reconciliation.

## Diagnosis

The following [recording rules][recording rules] can be used to determine the
main contributors of the alerts, after adjusting their range to match the `long`
and `short` labels of the active alerts:

```sh
# error
label_replace(
  sum(rate(apiserver_request_total{job="apiserver",verb=~"LIST|GET",code=~"5.."}[1d]))
/ scalar(sum(rate(apiserver_request_total{job="apiserver",verb=~"LIST|GET"}[1d])))
, "type", "error", "_none_", "")
or
# resource-scoped latency
label_replace(
  (
    sum(rate(apiserver_request_duration_seconds_count{job="apiserver",verb=~"LIST|GET",subresource!~"proxy|log|exec",scope="resource"}[1d]))
  -
    (sum(rate(apiserver_request_duration_seconds_bucket{job="apiserver",verb=~"LIST|GET",subresource!~"proxy|log|exec",scope="resource",le="0.1"}[1d])) or vector(0))
  ) / scalar(sum(rate(apiserver_request_total{job="apiserver",verb=~"LIST|GET",subresource!~"proxy|log|exec"}[1d])))
, "type", "slow-resource", "_none_", "")
or
# namespace-scoped latency
label_replace(
  (
    sum(rate(apiserver_request_duration_seconds_count{job="apiserver",verb=~"LIST|GET",subresource!~"proxy|log|exec",scope="namespace"}[1d]))
  - sum(rate(apiserver_request_duration_seconds_bucket{job="apiserver",verb=~"LIST|GET",subresource!~"proxy|log|exec",scope="namespace",le="0.5"}[1d]))
  ) / scalar(sum(rate(apiserver_request_total{job="apiserver",verb=~"LIST|GET",subresource!~"proxy|log|exec"}[1d])))
, "type", "slow-namespace", "_none_", "")
or
# cluster-scoped latency
label_replace(
  (
    sum(rate(apiserver_request_duration_seconds_count{job="apiserver",verb=~"LIST|GET",scope="cluster"}[1d]))
    - sum(rate(apiserver_request_duration_seconds_bucket{job="apiserver",verb=~"LIST|GET",scope="cluster",le="5"}[1d]))
  ) / scalar(sum(rate(apiserver_request_total{job="apiserver",verb=~"LIST|GET"}[1d])))
, "type", "slow-cluster", "_none_", "")
```

In this example, the `slow-resource` error type appears to be the main
contributor to the alerts:

![KubeAPIErrorBudgetBurn alert error types](img/kubeapierrorbudgetburn-error-types.png)

Use the `slow-resource` query from the above recording rules to identify the
resource kinds that contribute to the SLO violation:

```sh
sum by(resource) (rate(apiserver_request_duration_seconds_count{job="apiserver",verb=~"LIST|GET",subresource!~"proxy|log|exec",scope="resource"}[1d]))
-
(sum by(resource) (rate(apiserver_request_duration_seconds_bucket{job="apiserver",verb=~"LIST|GET",subresource!~"proxy|log|exec",scope="resource",le="0.1"}[1d])) or vector(0))
/ scalar(sum(rate(apiserver_request_total{job="apiserver",verb=~"LIST|GET",subresource!~"proxy|log|exec"}[1d])))
```

In this example, requests to the `apirequestcounts` resource kind appear to be
the ones experiencing high latency:

![KubeAPIErrorBudgetBurn slow resource](img/kubeapierrorbudgetburn-slow-resource.png)

If accessible, the following Grafana dashboards will can also provide further
insights into request duration and API server and etcd performance:

* API Request Duration by Verb
* etcd Request Duration - 99th Percentile
* etcd Object Count
* Request Duration by Read vs Write - 99th Percentile
* Long Running Requests by Resource

The following queries can be used individually to determine the resource kinds
that contribute to the SLO violation once the main contributor has been
identified.

`error`:
```sh
sum by(resource) (rate(apiserver_request_total{job="apiserver",verb=~"LIST|GET",code=~"5.."}[1d]))
/ scalar(sum(rate(apiserver_request_total{job="apiserver",verb=~"LIST|GET"}[1d])) or vector(0))
```

`slow-resource`:
```sh
sum by(resource) (rate(apiserver_request_duration_seconds_count{job="apiserver",verb=~"LIST|GET",subresource!~"proxy|log|exec",scope="resource"}[1d]))
-
(sum by(resource) (rate(apiserver_request_duration_seconds_bucket{job="apiserver",verb=~"LIST|GET",subresource!~"proxy|log|exec",scope="resource",le="0.1"}[1d])) or vector(0))
/ scalar(sum(rate(apiserver_request_total{job="apiserver",verb=~"LIST|GET",subresource!~"proxy|log|exec"}[1d])))
```

`slow-namespace`:
```sh
sum by(resource) (rate(apiserver_request_duration_seconds_count{job="apiserver",verb=~"LIST|GET",subresource!~"proxy|log|exec",scope="namespace"}[1d]))
-
(sum by(resource) (rate(apiserver_request_duration_seconds_bucket{job="apiserver",verb=~"LIST|GET",subresource!~"proxy|log|exec",scope="namespace",le="0.5"}[1d])) or vector(0))
/ scalar(sum(rate(apiserver_request_total{job="apiserver",verb=~"LIST|GET",subresource!~"proxy|log|exec"}[1d])))
```

`slow-cluster`:
```sh
sum by(resource) (rate(apiserver_request_duration_seconds_count{job="apiserver",verb=~"LIST|GET",scope="cluster"}[1d]))
-
(sum by(resource) (rate(apiserver_request_duration_seconds_bucket{job="apiserver",verb=~"LIST|GET",scope="cluster",le="5"}[1d])) or vector(0))
/ scalar(sum(rate(apiserver_request_total{job="apiserver",verb=~"LIST|GET"}[1d])))
```

## Mitigation

### Restart the kubelet (after upgrade)

If these alerts are triggered following a cluster upgrade, try restarting the
kubelets per description [here][5420801].

### Determine the source of the error or slow requests

There isn't a straightforward way to identify the root causes, but in the past
we were able to narrow down bugs by examining the failed resource counts in the
audit logs.

Gather the audit logs of the cluster:

```sh
oc adm must-gather -- /usr/bin/gather_audit_logs
```

Install the [cluster-debug-tools][cluster-debug-tools] as a kubectl/oc plugin.

Use the `audit` subcommands to gather information on users that sends the
requests, the resource kinds, the request verbs etc.

E.g. to determine who generate the `apirequestcount` resource slow requests and
what these requests are doing:

```sh
oc dev_tool audit -f ${kube_apiserver_audit_log_dir} -otop --by=user resource="apirequestcounts"

oc dev_tool audit -f ${kube_apiserver_audit_log_dir} -otop --by=verb resource="apirequestcounts" --user=${top-user-from-last-command}
```

The `audit` subcommand also supports the `--failed-only` option which can be
used to return failed requests only:

```sh
# find the top-10 users with the highest failed requests count
oc dev_tool audit -f ${kube_apiserver_audit_log_dir} --by user --failed-only -otop

# find the top-10 failed API resource calls of a specific user
oc dev_tool audit -f ${kube_apiserver_audit_log_dir} --by resource --user=${service_account} --failed-only -otop

# find the top-10 failed API verbs of a specific user on a specific resource
oc dev_tool audit -f ${kube_apiserver_audit_log_dir} --by verb --user=${service_account} --resource=${resources} --failed-only -otop
```

When filing a new Bugzilla issue, be sure to attach this information and the
audit logs to it.

[alert PR]: https://github.com/openshift/cluster-kube-apiserver-operator/pull/1126
[cluster-debug-tools]: https://github.com/openshift/cluster-debug-tools
[KubeAPIErrorBudgetBurn]: https://github.com/openshift/cluster-kube-apiserver-operator/blob/622c08f101555be4584cb897f68f772777b32ada/bindata/v4.1.0/alerts/kube-apiserver-slos.yaml
[recording rules]: https://github.com/openshift/cluster-kube-apiserver-operator/blob/c1c38912859e8b023a1da9168960e2c712068d5b/bindata/v4.1.0/alerts/kube-apiserver-slos.yaml#L234-L267
[upstream runbook]: https://github.com/prometheus-operator/kube-prometheus/wiki/KubeAPIErrorBudgetBurn
[5420801]: https://access.redhat.com/solutions/5420801



------------------------------


