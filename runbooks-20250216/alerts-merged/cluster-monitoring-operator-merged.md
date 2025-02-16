Original Filename:  AlertmanagerClusterFailedToSendAlerts.md

# AlertmanagerClusterFailedToSendAlerts

## Meaning

The alert `AlertmanagerClusterFailedToSendAlerts` is triggered when all
Alertmanager instances in a cluster have consistently failed to send
notifications to an integration.

## Impact

Some notifications are not delivered to the integration.

## Diagnosis

Review the logs of the `alertmanager-main` pods in the `openshift-monitoring`
namespace by running:

```console
$ oc -n openshift-monitoring logs -l 'alertmanager=main'
```

The following reasons might cause this alert to fire:

- The endpoint is not reachable.
- The endpoint's URL or credentials are misconfigured.

## Mitigation

How you resolve the problem causing the alert to fire depends on the particular
issue reported in the logs.



------------------------------


Original Filename:  AlertmanagerFailedReload.md

# AlertmanagerFailedReload

## Meaning

The alert `AlertmanagerFailedReload` is triggered when the Alertmanager instance
for the cluster monitoring stack has consistently failed to reload its
configuration for a certain period of time.

## Impact

Alerts for cluster components may not be delivered as expected.

## Diagnosis

Check the logs for the `alertmanager-main` pods in the `openshift-monitoring`
namespace:

```console
$ oc -n openshift-monitoring logs -l 'alertmanager=main'
```

## Mitigation

The resolution depends on the particular issue reported in the logs.



------------------------------


Original Filename:  AlertmanagerFailedToSendAlerts.md

# AlertmanagerFailedToSendAlerts

## Meaning

The alert `AlertmanagerFailedToSendAlerts` is triggered when any of the
Alertmanager instances in the cluster monitoring stack has repeatedly
failed to send notifications to an integration.

## Impact

Some alert notifications are not delivered.

## Diagnosis

Review the logs for the pod in the namespace indicated in the alert message.

For example, the following sample alert message refers to the
`alertmanager-main-1` pod in the `openshift-monitoring` namespace:

> Alertmanager openshift-monitoring/alertmanager-main-1 failed to send 75%
> of notifications to webhook.

You can review the logs for the `alertmanager-main-1` pod in the
`openshift-monitoring` namespace by running the following command:

```console
$ oc -n openshift-monitoring logs alertmanager-main-1
```

## Mitigation

The resolution depends on the particular issue reported in the logs.



------------------------------


Original Filename:  ClusterMonitoringOperatorDeprecatedConfig.md

# ClusterMonitoringOperatorDeprecatedConfig

## Meaning

This alert fires when a deprecated config is used in the
`openshift-monitoring/cluster-monitoring-config` config map.

## Impact

Avoid using a deprecated config because the config has no effect, and doing so
might cause the `Upgradeable` condition for the Cluster Monitoring Operator
to become `False` in a future OpenShift Container Platform release.

## Diagnosis

- Check the __Description__ and __Summary__ annotations of the alert to identify
the deprecated config as shown in the following example:

  __Description__

  `The configuration field k8sPrometheusAdapter in
  openshift-monitoring/cluster-monitoring-config was deprecated in version 4.16
  and has no effect`.

  __Summary__

  `Cluster Monitoring Operator is being used with a deprecated configuration.`

## Mitigation

* For the `k8sPrometheusAdapter.dedicatedServiceMonitors`
field, you can remove the block. For more information, see
`Monitoring deprecated and removed features` under
[Deprecated and removed features](https://docs.openshift.com/container-platform/4.16/release_notes/ocp-4-16-release-notes.html#ocp-4-16-deprecated-removed-features_release-notes).

* For the other `k8sPrometheusAdapter` fields, see `Monitoring deprecated and
removed features` under [Deprecated and removed features](https://docs.openshift.com/container-platform/4.16/release_notes/ocp-4-16-release-notes.html#ocp-4-16-deprecated-removed-features_release-notes).
You might need to migrate some of the fields under [metricsServer](https://docs.openshift.com/container-platform/latest/observability/monitoring/config-map-reference-for-the-cluster-monitoring-operator.html#metricsserverconfig).

The alert resolves itself when the deprecated config is not used.



------------------------------


Original Filename:  ClusterOperatorDegraded.md

# ClusterOperatorDegraded

## Meaning

The alert `ClusterOperatorDegraded` is triggered by the
[cluster-version-operator](https://github.com/openshift/cluster-version-operator)
(CVO) when a `ClusterOperator` is in the `degraded` state for a certain period.

An Operator reports a `Degraded` state when its current state does not
match the requested state over a period of time, which results in a lower
quality of service. The period of time varies by component, but a `Degraded`
state represents the persistent observation of a condition. A service state
might also be in an `Available` state even when degraded.

For example, a service might request three running pods, but one pod is in a
crash-loop state. In this case, the service is reported as `Available` but
`Degraded` because it might have a lower quality of service.

A component might also be reported as `Progressing` but not `Degraded` because
the change from one state to another does not persist over a long enough
time period to report a `Degraded` state.

A service does not report a `Degraded` state during a normal upgrade. A service
might report `Degraded` in response to a persistent infrastructure failure that
requires administrator intervention--for example, when a control plane host is
unhealthy and has to be replaced. An Operator reports `Degraded` state
if unexpected errors occur over a period of time.
## Impact

This alert indicates that an Operator has encountered an error preventing it
or its operand from working properly. The operand might still be available,
but its intent might not be fulfilled, and therefore an outage might occur.

## Diagnosis

The alert message indicates the Operator for which the alert triggered. The
Operator name is displayed under the `name` label, as shown in the following
example:

```text
 - alertname = ClusterOperatorDegraded
...
 - name = console
...
```

To troubleshoot the issue causing the alert to trigger, use any or all of
the following methods after logging into the cluster:

* Review the status of all Operators to discover if multiple Operators are
in a `Degraded` state:

    ```console
    $ oc get clusteroperator
    ```

* Review information about the current status of the Operator:

    ```console
    $ oc get clusteroperator $CLUSTEROPERATOR -ojson | jq .status.conditions
    ```

* Review the associated resources for the Operator:

    ```console
    $ oc get clusteroperator $CLUSTEROPERATOR -ojson | jq .status.relatedObjects
    ```

* Review the logs and other artifacts for the Operator. For example, you can
collect the logs of a specific Operator and store them in a local directory
named `out`:

    ```console
    $ oc adm inspect clusteroperator/$CLUSTEROPERATOR --dest-dir=out
    ```

## Mitigation

How you resolve the issue causing the `Degraded` state of the Operator varies
depending on the Operator. If the alert is triggered during an upgrade, the
`Degraded` state might recover after some time has passed. If an Operator is
misconfigured, troubleshoot the error by reviewing information about
the Operator in the logs and fix the configuration based on your findings.



------------------------------


Original Filename:  ClusterOperatorDown.md

# ClusterOperatorDown

## Meaning

The alert `ClusterOperatorDown` is triggered by
[cluster-version-operator](https://github.com/openshift/cluster-version-operator)
(CVO) when a `ClusterOperator` is not in the `Available` state for a certain
period of time. An operand is `Available` when it is functional in the cluster.

## Impact

This alert indicates that an outage has occurred in your cluster. Investigate
the issue as soon as possible.

## Diagnosis

The alert message provides the name of the Operator that triggered the alert,
as shown in the following example:

```text
 - alertname = ClusterOperatorDown
...
 - name = console
...
```

To troubleshoot the issue causing the alert to trigger, use any or all of
the following methods after logging into the cluster:

* Review the status of all Operators to discover if multiple Operators are
down:

    ```console
    $ oc get clusteroperator
    ```

* Review information about the current status of the Operator:

    ```console
    $ oc get clusteroperator $CLUSTEROPERATOR -ojson | jq .status.conditions
    ```

* Review the associated resources for the Operator:

    ```console
    $ oc get clusteroperator $CLUSTEROPERATOR -ojson | jq .status.relatedObjects
    ```

* Review the logs and other artifacts for the Operator. For example, you can
collect the logs of a specific Operator and store them in a local directory
named `out`:

    ```console
    $ oc adm inspect clusteroperator/$CLUSTEROPERATOR --dest-dir=out
    ```

## Mitigation

How you resolve the issue causing the issue varies depending on the Operator.
If the alert is triggered during an upgrade, the issue might resolve after some
time has passed. Otherwise, troubleshoot the error by reviewing information
about the Operator in the logs and fix the configuration based on your findings.



------------------------------


Original Filename:  KubeAPIDown.md

# KubeAPIDown

## Meaning

The `KubeAPIDown` alert is triggered when all Kubernetes API servers have not
been reachable by the monitoring system for more than 15 minutes.

## Impact

This is a critical alert. It indicates that the Kubernetes API is not
responding, and the cluster might be partially or fully non-functional.

## Diagnosis

1. Verify the status of the API server targets in Prometheus in the OpenShift
web console.

1. Confirm whether the API is also unresponsive:

    ```console
    $ oc cluster-info
    ```

1. If you can still reach the API server, a network issue might exist between
the Prometheus instances and the API server pods. Review the status of the API
server pods:

    ```console
    $ oc -n openshift-kube-apiserver get pods
    $ oc -n openshift-kube-apiserver logs -l 'app=openshift-kube-apiserver'
    ```
## Mitigation

If you can still reach the API server intermittently, you might be able to
troubleshoot this issue as you would for any other failing deployment.

If the API server is not reachable at all, refer to the disaster recovery
documentation for your version of OpenShift.



------------------------------


Original Filename:  KubeAggregatedAPIErrors.md

# KubeAggregatedAPIErrors

## Meaning

The `KubeAggregatedAPIErrors` alert is triggered when multiple calls to the
aggregated OpenShift API fail over a certain period of time.

## Impact

Aggregated API errors can result in the unavailability of some OpenShift
services.

## Diagnosis

The alert message contains information about the affected API and the scope of
the impact, as shown in the following sample:

```text
 - alertname = KubeAggregatedAPIErrors
 - name = v1.packages.operators.coreos.com
 - namespace = default
...
 - message = Kubernetes aggregated API v1.packages.operators.coreos.com/default has reported errors. It has appeared unavailable 5 times averaged over the past 10m.
```

## Mitigation

Troubleshoot and fix the issue or issues causing the aggregated API errors by
checking the availability status for each API and by verifying the
authentication certificates for the aggregated API.

### Check the availability status for each API

At least four aggregated APIs exist in an OpenShift cluster:

* the API for the `openshift-apiserver` namespace
* the API for the `prometheus-adapter` in the namespace `openshift-monitoring`
* the API for the the `package-server` service in the
`openshift-operator-lifecycle-manager` namespace
* the API for the `openshift-oauth-apiserver` namespace

1. Check the availability of all APIs. To get a list of `APIServices` and their
backing aggregated APIs, use the following command:

    ```console
    $ oc get apiservice
    ```

    The `SERVICE` column in the returned data shows the aggregated API name.
    Normally, the availability status for every listed API will be shown as
    `True`. If the status is `False`, it means that requests for that API
    service, API server pods, or resources belonging to that `apiGroup` have
    failed many times in the past few minutes.

2. Fetch the pods that serve the unavailable API. For example, for
`openshift-apiserver/api` use the following command:

    ```console
    $ oc get pods -n openshift-apiserver
    ```

    If the status is not shown as `Running`, review the logs for more details.
    Because these pods are controlled by a deployment, they can be restarted
    when they do not respond to requests.

### Verify the authentication certificates for the aggregated API

1. Verify that the certificates have not expired and are still valid:

    ```console
    $ oc get configmaps -n kube-system extension-apiserver-authentication
    ```

    If required, you can save these certificates to a file and use the following
    command to check the expiration dates for each certificate file:

    ```console
    $ openssl x509 -noout -enddate -in {myfile_with_certs.crt}
    ```

    The aggregated APIs use these certificates to validate requests. If
    they are expired, see [the OpenShift documentation][cert] for information
    about how to add a new certificate.

[cert]: https://docs.openshift.com/container-platform/latest/security/certificates/api-server.html



------------------------------


Original Filename:  KubeDeploymentReplicasMismatch.md

# KubeDeploymentReplicasMismatch

## Meaning

Th `KubeDeploymentReplicasMismatch` alert triggers when, over a certain time
period, a discrepancy occurs between the desired number of pod replicas for
deployment and the actual number of running instances.

## Impact

The impact differs depending on the size of the discrepancy.

## Diagnosis

The alert message under the `deployment` label describes where the discrepancy
occurred:

```console
 - alertname = KubeDeploymentReplicasMismatch
...
 - deployment = elasticsearch-cdm-u1gqqbu6-2
...
 - namespace = openshift-logging
...
```

Review the current deployment details by examining the items available in
the alert.

* Start by reviewing the status of the deployment:

    ```console
    $ oc get deploy -n $NAMESPACE $DEPLOYMENT
    ```

* Run the following command in the target namespace to review the
events:

    ```console
    $ oc get events -n $NAMESPACE
    ```

* Review the status of the pods that the deployment manages:

    ```console
    $ oc get pods -n $NAMESPACE --selector=app=$DEPLOYMENT
    ```

    Possible problems include a pod stuck in a `ContainerCreating` or
    `CrashLoopBackoff` state.

* The events might also list information about possible failed actions of a
pod. You can view application and start-up failures by running:

    ```console
    $ oc describe pod $POD
    ```

* For pods stuck in a `Pending` state, insufficient resources are
preventing the pod from being scheduled. Check the health of the nodes:

    ```console
    $ oc get nodes
    ```

* Verify whether or not the host has sufficient CPU and memory resources:

    ```console
    $ oc adm top nodes
    ```

## Mitigation

After you diagnose the issue, refer to the OpenShift documentation to learn how
to resolve the problems. You can safely delete the pods because they are
managed by the deployment. However, you might also need to add more nodes if
your diagnostic steps showed that the host had insufficient resources.



------------------------------


Original Filename:  KubeJobFailed.md

# KubeJobFailed

## Meaning

The `KubeJobFailed` alert triggers when the number of job execution attempts
exceeds the value defined in `backoffLimit`. If this issue occurs, a job can
create one or many pods for its tasks.

## Impact

A task has not finished correctly. Depending on the task, the severity of the
impact differs.

## Diagnosis

The alert message contains the job name and the namespace in which that job
failed. The following message provides an example:

```text
 - alertname = KubeJobFailed
...
 - job_name = elasticsearch-delete-app-1600903800
 - namespace = openshift-logging
... 
 - message = Job openshift-logging/elasticsearch-delete-app-1600855200 failed to complete.
```

This information is required for you to follow the mitigation steps.

## Mitigation

* Find the pods that belong to the failed job shown in the alert message:

    ```console
    $ oc get pod -n $NAMESPACE -l job-name=$JOBNAME
    ```

    If you see an `Error` pod together with a subsequent `Completed` pod of the
    same base name, the error was transient, and you can safely delete the
    `Error` pod.

* Review the status of the jobs:

    ```console
    $ oc get jobs -n $NAMESPACE
    ```

    If a healthy job exists for every failed job, you can safely delete the
    failed jobs, and the alert will resolve itself after a few minutes.



------------------------------


Original Filename:  KubeNodeNotReady.md

# KubeNodeNotReady

## Meaning

The `KubeNodeNotReady` alert triggers when a node is not in a `Ready` state
over a certain period of time. If this alert triggers, the node cannot host any
new pods, as described [here][KubeNode].

## Impact

The issue that triggers this alert degrades the performance of the cluster
deployments. The severity of the degradation depends on the overall workload
and the type of node.

## Diagnosis

The alert notification message includes the affected node, as shown in the
following example:

```txt
 - alertname = KubeNodeNotReady
...
 - node = node1.example.com
...
```

* Log in to the cluster. Review the status of the node indicated in the alert
message:

    ```console
    $ oc get node $NODE -o yaml
    ```

    The output of this command describes why the node is not ready. For example
    network issues could be causing timeouts when trying to reach the API or
    kubelet.

* Check the machine for the node:

    ```console
    $ oc get -n openshift-machine-api machine $NODE -o yaml
    ```

* Check the events for the machine API:

    ```console
    $ oc get -n openshift-machine-api events
    ```

    If the machine API is not able to replace the node, the machine status and
    events list will provide the details.

## Mitigation

After you resolve the problem that prevented the machine API from replacing the
node, the instance is terminated and replaced by the machine API, but only if
`MachineHealthChecks` are enabled for the nodes. Otherwise, a manual restart is
required.

[KubeNode]: https://kubernetes.io/docs/concepts/architecture/nodes/#condition



------------------------------


Original Filename:  KubePersistentVolumeFillingUp.md

# KubePersistentVolumeFillingUp

## Meaning

This alert fires when a persistent volume in one of the system namespaces has
less than 3% of its total space remaining. System namespaces include
`default` and those that have names beginning with `openshift-` or `kube-`.
## Impact

If a persistent volume used by a system component fills up, the component
is unlikely to function normally. A full persistent volume can also lead to a
partial or full cluster outage.

## Diagnosis

The alert labels include the name of the persistent volume claim (PVC)
associated with the volume running low on storage. The labels also include the
namespace in which the PVC is located. Use this information to graph
available storage in the OpenShift web console under Observe -> Metrics.  

The following is an example query for a PVC associated with a Prometheus
instance in the `openshift-monitoring` namespace:

```text
kubelet_volume_stats_available_bytes{
  namespace="openshift-monitoring",
  persistentvolumeclaim="prometheus-k8s-db-prometheus-k8s-0"
}
```

You can also inspect the contents of the volume manually to determine what is
using the storage:

```console
$ PVC_NAME='<persistentvolumeclaim label from alert>'
$ NAMESPACE='<namespace label from alert>'

$ oc -n $NAMESPACE describe pvc $PVC_NAME
$ POD_NAME='<"Used By:" field from the above output>'

$ oc -n $NAMESPACE rsh $POD_NAME
$ df -h
```

## Mitigation

Mitigation for this issue depends on what is filling up the storage.  

You can try allocating more storage space to the affected volume to solve the
issue.

You can also try adjusting the configuration for the component that is the
volume so that the component requires less storage space. For example, if logs
for a component are filling up the persistent volume, you can change the log
level so that less information is logged and therefore less space is required
for logs.



------------------------------


Original Filename:  KubePersistentVolumeInodesFillingUp.md

# KubePersistentVolumeInodesFillingUp

## Meaning

The `KubePersistentVolumeInodesFillingUp` alert triggers when a persistent
volume in one of the system namespaces has less than 3% of its allocated inodes
left. System namespaces include `default` and those that have names beginning
with `openshift-` or `kube-`.

## Impact

Significant inode usage by a system component is likely to prevent the
component from functioning normally. Signficant inode usage can also lead to a
partial or full cluster outage.

## Diagnosis

The alert labels include the name of the persistent volume claim (PVC)
associated with the volume running low on storage. The labels also include the
namespace in which the PVC is located. Use this information to graph
available storage in the OpenShift web console under Observe -> Metrics.  

The following is an example query for a PVC associated with a Prometheus
instance in the `openshift-monitoring` namespace:

```text
kubelet_volume_stats_inodes_used{
  namespace="openshift-monitoring",
  persistentvolumeclaim="prometheus-k8s-db-prometheus-k8s-0"
}
```

You can inspect the status of the volume manually to determine which directory
is consuming a large number of inodes:

```console
$ PVC_NAME='<persistentvolumeclaim label from alert>'
$ NAMESPACE='<namespace label from alert>'

$ oc -n $NAMESPACE describe pvc $PVC_NAME
$ POD_NAME='<"Used By:" field from the above output>'

$ oc -n $NAMESPACE rsh $POD_NAME
$ cd /path/to/pvc-mount
$ ls -li .
$ stat
```

## Mitigation

Mitigating this issue depends on the total count of files, directories, and
symbolic links. You cannot expand the number of inodes on a file system after
the file system has been created. However, you can adjust the configuration for
the component using the volume so that it creates fewer files, directories, and
symbolic links.


------------------------------


Original Filename:  KubePodNotReady.md

# KubePodNotReady

## Meaning

The `KubePodNotReady` alert triggers when a pod has not been in a
`Ready` state for a certain time period. This issue can occur for different
reasons, as described [in the Kubernetes documentation][PodLifecycle]. When a
pod has a status of `Running` but is not in a `Ready` state, the `Readiness`
probe is failing. For example, an application-specific error might be
preventing the pod from being attached to a service. When a pod remains in
`Pending` state, it cannot be deployed to particular namespaces and nodes.

## Impact

The affected pod is not functional and does not receive any traffic. Depending
on how many functional replicas are still available, the severity of the impact
differs.

## Diagnosis

The alert notification message lists the pod that is not ready and the
namespace in which the pod is located, as shown in the following example alert
message:

```text
 - alertname = KubePodNotReady
...
 - namespace = openshift-logging
 - pod = elasticsearch-cdm-u1gqqbu6-2-868ddd4b45-w224d
...
```

To diagnose the cause of the issue, start by reviewing the status of the
affected pod:

```console
$ oc get pod -n $NAMESPACE $POD
```

If the pod is in a `Running` state, review the logs for the pod:

```console
$ oc logs -n $NAMESPACE $POD
```

Be aware that there might be multiple containers in the pod. If so, review the
logs for all of these containers. If the pod is not in a `Running` state--for
instance, if it is stuck in a `ContainerCreating` state--try to find out why.

## Mitigation

The steps you take to fix the issue will depend on the cause that you found when
you examined the logs.

[PodLifecycle]: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/


------------------------------


Original Filename:  KubeletDown.md

# KubeletDown

## Meaning

The `KubeletDown` alert is triggered when the monitoring system has not been
able to reach any of the Kubelets in a cluster for more than 15 minutes.

## Impact

This alert represents a critical threat to the cluster's stability. Excluding
the possibility of a network issue preventing the monitoring system from
scraping Kubelet metrics, multiple nodes in the cluster are likely unable to
respond to configuration changes for pods and other resources, and some
debugging tools are likely not to be functional, such as `oc exec` and
`oc logs`.

## Diagnosis

Review the status of the nodes and check for recent events on `Node` or other
resources:

```console
$ oc get nodes
$ oc describe node $NODE_NAME
$ oc get events --field-selector 'involvedObject.kind=Node'
$ oc get events
```

You can [access cluster node journal logs][cluster-node-journal-logs] to review
the logs for the Kubelet.  If the Kubelet is functional, you can use:

```console
$ oc adm node-logs --role=master -u kubelet
```

See `oc adm node-logs --help` for alternative ways to select nodes and filter results.

If the kubelet is not functional and you have SSH access to the nodes,
use this access to review the logs for the Kubelet:

```console
$ journalctl -b -f -u kubelet.service
```

## Mitigation

The mitigation for this alert depends on the issue causing the Kubelets to
become unresponsive. You can begin by checking for general networking issues or
for node-level configuration issues.

[cluster-node-journal-logs]: https://docs.openshift.com/container-platform/latest/support/gathering-cluster-data.html#querying-cluster-node-journal-logs_gathering-cluster-data



------------------------------


Original Filename:  NodeClockNotSynchronising.md

# NodeClockNotSynchronising

## Meaning

The `NodeClockNotSynchronising` alert triggers when a node is affected by
issues with the NTP server for that node. For example, this alert might trigger
when certificates are rotated for the API Server on a node, and the
certificates fail validation because of an invalid time.


## Impact
This alert is critical. It indicates an issue that can lead to the API Server
Operator becoming degraded or unavailable. If the API Server Operator becomes
degraded or unavailable, this issue can negatively affect other Operators, such
as the Cluster Monitoring Operator.

## Diagnosis

To diagnose the underlying issue, start a debug pod on the affected node and
check the `chronyd` service:

```shell
oc -n default debug node/<affected_node_name>
chroot /host
systemctl status chronyd
```

## Mitigation

1. If the `chronyd` service is failing or stopped, start it:

    ```shell
    systemctl start chronyd
    ```
    If the chronyd service is ready, restart it

    ```shell
    systemctl restart chronyd
    ```

    If `chronyd` starts or restarts successfuly, the service adjusts the clock
    and displays something similar to the following example output:

    ```shell
    Oct 18 19:39:36 ip-100-67-47-86 chronyd[2055318]: System clock wrong by 16422.107473 seconds, adjustment started
    Oct 19 00:13:18 ip-100-67-47-86 chronyd[2055318]: System clock was stepped by 16422.107473 seconds
    ```

2. Verify that the `chronyd` service is running:

    ```shell
    systemctl status chronyd
    ```

3. Verify using PromQL:

    ```console
    min_over_time(node_timex_sync_status[5m])
    node_timex_maxerror_seconds
    ```
    `node_timex_sync_status` returns `1` if NTP is working properly,or `0` if
    NTP is not working properly. `node_timex_maxerror_seconds` indicates how
    many seconds NTP is falling behind.

    The alert triggers when the value for
    `min_over_time(node_timex_sync_status[5m])` equals `0` and the value for
    `node_timex_maxerror_seconds` is greater than or equal to `16`.



------------------------------


Original Filename:  NodeFileDescriptorLimit.md

# NodeFileDescriptorLimit

## Meaning

The `NodeFileDescriptorLimit` alert is triggered when a node's kernel is
running out of available file descriptors. A `warning` level alert triggers at
greater than 70% usage, and a `critical` level alert triggers at greater than
90% usage.

## Impact

Applications on the node might no longer be able to open and operate on
files, which is likely to have severe negative consequences for anything
scheduled on this node.

## Diagnosis

Open a shell on the node and use standard Linux utilities to diagnose the issue:

```console
$ NODE_NAME='<value of instance label from alert>'

$ oc debug "node/$NODE_NAME"
# sysctl -a | grep 'fs.file-'
fs.file-max = 1597016
fs.file-nr = 7104       0       1597016
# lsof -n
```

## Mitigation

Reduce the number of files opened simultaneously either by adjusting application
configuration or by moving some applications to other nodes.



------------------------------


Original Filename:  NodeFilesystemAlmostOutOfFiles.md

# NodeFilesystemAlmostOutOfFiles

## Meaning

The `NodeFilesystemAlmostOutOfFiles` alert is similar to the
[NodeFilesystemSpaceFillingUp][1] alert, but rather
than being based on a prediction that a filesystem will run out of inodes in a
certain amount of time, it uses simple static thresholds. The alert triggers
at a `warning` level when 5% of available inodes remain, and triggers at a
`critical` level when 3% of available inodes remain.

## Impact

When a node's filesystem becomes full, it has a widespread impact. This issue
can cause any or all of the applications scheduled to that node to experience
anything from degraded performance to becoming fully inoperable. Depending on
the node and filesystem involved, this issue could pose a critical threat to
the stability of the cluster.

## Diagnosis

Refer to the [NodeFilesystemFilesFillingUp][1] runbook.

## Mitigation

Refer to the [NodeFilesystemFilesFillingUp][1] runbook.

[1]: https://github.com/openshift/runbooks/blob/master/alerts/cluster-monitoring-operator/NodeFilesystemFilesFillingUp.md



------------------------------


Original Filename:  NodeFilesystemAlmostOutOfSpace.md

# NodeFilesystemAlmostOutOfSpace

## Meaning

The `NodeFilesystemAlmostOutOfSpace` alert is similar to the
[NodeFilesystemSpaceFillingUp][1] alert, but rather
than being based on a prediction that a file system will become full in a
certain amount of time, it uses simple static thresholds. This alert triggers
at a `warning` level when 5% of space remains in the file system, and at a
`critical` level when 3% of space remains.

## Impact

A node's file system becoming full can have a widespread negative impact. This
issue can cause any or all of the applications scheduled to that node to
experience anything from degraded performance to becoming fully inoperable.
Depending on the node and file system involved, this issue can pose a critical
threat to the stability of the cluster.

## Diagnosis

Refer to the [NodeFilesystemSpaceFillingUp][1] runbook.

## Mitigation

Refer to the [NodeFilesystemSpaceFillingUp][1] runbook.

[1]: https://github.com/openshift/runbooks/blob/master/alerts/cluster-monitoring-operator/NodeFilesystemSpaceFillingUp.md



------------------------------


Original Filename:  NodeFilesystemFilesFillingUp.md

# NodeFilesystemFilesFillingUp

## Meaning

The `NodeFilesystemFilesFillingUp` alert is similar to the
[NodeFilesystemSpaceFillingUp][1] alert, but predicts that the file system will
run out of inodes rather than bytes of storage space. The alert triggers at a
`critical` level when the file system is predicted to run out of available
inodes within four hours.

## Impact

A node's file system becoming full can have a widespread negative impact. The
issue might cause any or all of the applications scheduled to that node to
experience anything from degraded performance to becoming fully inoperable,
Depending on the node and file system involved, this issue can pose a critical
threat to the stability of a cluster.

## Diagnosis

Note the `instance` and `mountpoint` labels from the alert. You can graph the
usage history of this file system by using the following query in the OpenShift
web console:

```text
node_filesystem_files_free{
  instance="<value of instance label from alert>",
  mountpoint="<value of mountpoint label from alert>"
}
```

You can also open a debug session on the node and use standard Linux utilities
to locate the source of the usage:

```console
$ MOUNT_POINT='<value of mountpoint label from alert>'
$ NODE_NAME='<value of instance label from alert>'

$ oc debug "node/$NODE_NAME"
$ df -hi "/host/$MOUNT_POINT"
```

Note that in many cases a file system that is running out of inodes will still
have available storage. Running out of inodes is often caused when an
application creates many small files.

## Mitigation

The number of inodes allocated to a file system is usually based on the storage
size. You might be able to solve the problem, or at least delay the negative
impact of the problem, by increasing the size of the storage volume. Otherwise,
determine the application that is creating large numbers of small files and
then either adjust its configuration or provide it with dedicated storage.

[1]: https://github.com/openshift/runbooks/blob/master/alerts/cluster-monitoring-operator/NodeFilesystemSpaceFillingUp.md



------------------------------


Original Filename:  NodeFilesystemSpaceFillingUp.md

# NodeFilesystemSpaceFillingUp

## Meaning

The `NodeFilesystemSpaceFillingUp` alert triggers when two conditions are met:  

* The current file system usage exceeds a certain threshold.
* An extrapolation algorithm predicts that the file system will run out of
  space within a certain amount of time. If the time period is less than 24
  hours, this is a `Warning` alert. If the time is less than 4
  hours, this is a `Critical` alert.

## Impact

As a file system starts to get low on space, system performance usually
degrades gradually.

If a file system fills up and runs out of space, processes that need to write
to the file system can no longer do so, which can result in lost data and
system instability.

## Diagnosis

* Study recent trends of file system usage on a dashboard. Sometimes, a periodic
pattern of writing and cleaning up in the file system can cause the linear
prediction algorithm to trigger a false alert.

* Use the Linux operating system tools and utilities to investigate what
directories are using the most space in the file system. Is the issue an
irregular condition, such as a process failing to clean up behind itself and
using a large amount of space? Or does the issue seem to be related to
organic growth?

To assist in your diagnosis, watch the following metric in PromQL:

```console
node_filesystem_free_bytes
```

Then, check the `mountpoint` label for the alert.

## Mitigation

If the `mountpoint` label is `/`, `/sysroot` or `/var`, remove unused images to
resolve the issue:

1. Debug the node by accessing the node file system:

    ```console
    $ NODE_NAME=<instance label from alert>
    $ oc -n default debug node/$NODE_NAME
    $ chroot /host
    ```

1. Remove dangling images:

    ```console
    $ podman images -q -f dangling=true | xargs --no-run-if-empty podman rmi
    ```

1. Remove unused images:

    ```console
    $ podman images | grep -v -e registry.redhat.io -e "quay.io/openshift" -e registry.access.redhat.com -e docker-registry.usersys.redhat.com -e docker-registry.ops.rhcloud.com -e rhmap | xargs --no-run-if-empty podman rmi 2>/dev/null
    ```

1. Exit debug:

    ```console
    $ exit
    $ exit
    ```



------------------------------


Original Filename:  NodeRAIDDegraded.md

# NodeRAIDDegraded

## Meaning

The `NodeRAIDDegraded` alert triggers when a node has a storage configuration
with a RAID array and that array is reporting a degraded state because of one or
more disk failures.

## Impact

The affected node might go offline at any moment if the RAID array fully fails
because of issues with disks.

## Diagnosis

Open a shell on the node and use standard Linux utilities to diagnose the
issue. Note that you might also need to install additional software in the
debug container:

```console
$ NODE_NAME='<value of instance label from alert>'

$ oc debug "node/$NODE_NAME"
$ cat /proc/mdstat
```

## Mitigation

See the Red Hat Enterprise Linux [documentation][1] to see mitigation steps for
failing RAID arrays.

[1]: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/managing_storage_devices/managing-raid_managing-storage-devices



------------------------------


Original Filename:  PrometheusDuplicateTimestamps.md

# PrometheusDuplicateTimestamps

## Meaning

The `PrometheusDuplicateTimestamps` alert is triggered when there is a constant
increase in dropped samples due to them having identical timestamps.

## Impact

Unwanted samples might be scraped, and desired samples might be dropped.
Consequently, queries may yield incorrect and unexpected results.

## Diagnosis

1. Determine whether the alert has triggered for the instance of Prometheus used
   for default cluster monitoring or for the instance that monitors user-defined
   projects by viewing the alert message's `namespace` label: the namespace for
   default cluster monitoring is `openshift-monitoring` and the namespace for
   user workload monitoring is `openshift-user-workload-monitoring`.

2. Review the logs for the affected Prometheus instance:

   ```shell
   $ NAMESPACE='<value of namespace label from alert>'

   $ oc -n $NAMESPACE logs -l 'app.kubernetes.io/name=prometheus' | \
   grep 'Error on ingesting samples with different value but same timestamp.*' \
   | sort | uniq -c | sort -n
   level=warn ... scrape_pool="the-scrape-pool" target="an-involved-target" \
   msg="Error on ingesting samples with different value but same timestamp"
   ```

   Warning logs similar to the one above should be present.

   In the case where targets are defined via a `ServiceMonitor` or `PodMonitor`,
   the `scrape_pool` label will be in the format
   `serviceMonitor/<namespace>/<service-monitor-name>/<endpoint-id>` or
   `podMonitor/<namespace>/<pod-monitor-name>/<endpoint-id>`.

## Mitigation

If the alert originates from the `openshift-monitoring` namespace, please open a
support case. If not, this might be due to one or both of the following issues:

### Target duplication

The logs might help determine the following information:

- The same target is defined in different scrape pools.
- Distinct targets across different scrape pools are producing the same samples.

This happens when the target is duplicated, that is, defined multiple times with
identical target labels.

Proceed with the following steps to fix the issue:

1. Use the logs to guide you to the place where the conflicting targets are defined.
2. Remove the duplicated targets or ensure that distinct targets are labeled uniquely.

### Target is exposing duplicated samples for the same timestamp

In this scenario, even if the samples have the same value for the same
timestamp, they are considered duplicates.

#### NOTE

A regression introduced in OpenShift Container Platform 4.16.0 might cause the alert
to fire when a target is exposing samples of the same series with different explicit
timestamps (see [OCPBUGS-39179] to track the resolution).

Proceed with the following steps to fix the issue:

1. Enable the `debug` log level on the Prometheus instance. See
[a guide to change log level] for monitoring components in OpenShift.
2. Review the new debug logs. The logs should reveal the problematic metrics:

   ```shell
   $ NAMESPACE='<value of namespace label from alert>'

   $ oc -n $NAMESPACE logs -l 'app.kubernetes.io/name=prometheus' | \
   grep 'Duplicate sample for timestamp.*' | sort | uniq -c | sort -n
   level=debug ... msg="Duplicate sample for timestamp" \
   series="a-concerned-series"
   ```

   In this case, you have to fix the metrics exposition in the broken targets to
   resolve the problem. Ensure they do not expose duplicated samples.
3. After resolving the issue, disable the `debug` log level.

[a guide to change log level]: https://docs.openshift.com/container-platform/latest/observability/monitoring/config-map-reference-for-the-cluster-monitoring-operator.html

[OCPBUGS-39179]: https://issues.redhat.com/browse/OCPBUGS-39179



------------------------------


Original Filename:  PrometheusOperatorRejectedResources.md

# PrometheusOperatorRejectedResources

## Meaning

The `PrometheusOperatorRejectedResources` alert triggers when the Prometheus
Operator detects and rejects invalid `AlertmanagerConfig`, `PodMonitor`,
`ServiceMonitor`, or `PrometheusRule` objects.

## Impact

The custom resources that trigger the alert are ignored by Prometheus Operator.
As a consequence, they will not be part of the final configuration of the
Prometheus, Alertmanager, or Thanos Ruler components managed by the Prometheus
Operator.

## Diagnosis

### Identify the custom resource type

The first step is to identify the custom resource type and the namespace from
the `resource` and `namespace` labels of the
`PrometheusOperatorRejectedResources` alert. You can find this information by
using the OpenShift web console or the command line interface (CLI).

#### Using the Openshift web console

1. Browse to **Observe** -> **Alerting**.
2. Search for the `PrometheusOperatorRejectedResources` alert.
3. Click the alert to view its details.
4. Scroll down and view the **Labels** field. The resource type is indicated by
the `resource` label.

#### Using the CLI

Get the Alertmanager URL and view a list of alerts that have fired:

```bash
### Retrieve the Alertmanager URL
$ ALERTMANAGER=$(oc get route alertmanager-main -n openshift-monitoring -o jsonpath='{@.spec.host}')

### Get active alerts
$ curl -sk -H "Authorization: Bearer $(oc create token prometheus-k8s -n openshift-monitoring)" \
    https://$ALERTMANAGER/api/v2/alerts?filter=alertname=PrometheusOperatorRejectedResources
```

The `namespace` label can be either `openshift-monitoring` or `openshift-user-workload-monitoring`,
which dictates your course of action:
* When the value is `openshift-monitoring`, this is an issue with the platform
monitoring stack. Please submit a request to the Customer Support.
* When the value is `openshift-user-workload-monitoring`, this is an issue with
a user-defined monitoring resource.


### Identify the resource(s) and reason

To identity which monitoring objects have been rejected and why, use one of the
2 following methods depending on the OCP version.

#### OCP 4.16 and later

The Prometheus operator emits events about invalid resources.

##### Using the Openshift web console

1. Browse to **Home** -> **Events**.
2. Select "All projects" in the Project drop-down list.
3. Select the `resource` label in the Resources drop-down list (for instance,
`ServiceMonitor`).

##### Using the CLI

Check the Kubernetes events related to the `resource` label using the following
command (example for `ServiceMonitor` resources):

```bash
oc get events --field-selector involvedObject.kind=ServiceMonitor --all-namespaces
```

The following is a sample event about a rejected custom resource:

```log
NAMESPACE   LAST SEEN   TYPE      REASON                 OBJECT                       MESSAGE
default     106s        Warning   InvalidConfiguration   servicemonitor/example-app   ServiceMonitor example-app was rejected due to invalid configuration: it accesses file system via bearer token file which Prometheus specification prohibits
```


#### Before OCP 4.16

Check the logs of the Prometheus Operator deployment in the
`openshift-user-workload-monitoring` namespace. The namespace and the name of
the rejected resource will appear in the log entry after the error message.

```bash
oc logs deployment/prometheus-operator -c prometheus-operator -n openshift-user-workload-monitoring
```

The following is a sample error message about a rejected custom resource:

```log
level=warn ts=2023-07-03T20:37:20.740723141Z caller=operator.go:1917 component=prometheusoperator msg="skipping servicemonitor" error="it accesses file system via bearer token file which Prometheus specification prohibits" servicemonitor=quarkus-demo/otel-collector namespace=openshift-user-workload-monitoring prometheus=user-workload
```

## Mitigation

The mitigation depends on which resources are being rejected and why.

### ServiceMonitor and PodMonitor

- Invalid relabeling configuration (for example, a malformed regular expression).
  - Fix the relabeling configuration syntax.
- Invalid TLS configuration.
  - Fix the TLS configuration.
- A scrape interval less than the scrape timeout.
  - Change the scrape timeout or the scrape interval value.
- Invalid secret or configmap key reference.
  - Verify that the secret/configmap object exists and that they key is present
    in the secret/configmap.
- Violation of file system access rules, which can occur when a `ServiceMonitor`
  or `PodMonitor` object references a file to use as a bearer token or references
  a TLS file. These configurations are not allowed in user-defined monitoring.
  - you must create a secret that contains the credential data in the
    same namespace as the `ServiceMonitor` or `PodMonitor` object and use a
    secret key reference in the `ServiceMonitor` or `PodMonitor`
    configuration.

When the alert is triggered by an resource managed by a 3rd-party operator, it
might not be possible to fix the root cause. The resolution will depend on the
status of the operator:

- The operator is a certified Red Hat operator.
  - If the operator is installed in the `openshift-operators` namespace, it
    should be removed and installed in a different namespace because
    `openshift-operators` might contain community operators which don't have
    the same level of support.
  - If the operator is deployed in another namespace than `openshift-operators`
    and its documentation requires adding the
    `openshift.io/cluster-monitoring: "true"` label to this namespace during
    the installation, ensure that the label exists.
  - Otherwise you can exclude the resource from user-defined monitoring by adding
    the `openshift.io/user-monitoring:"false"` label to the resource's namespace
    or the resource itself (the latter requires at least OCP 4.16).
- The operator is a community operator.
  - You can exclude the resource from user-defined monitoring by adding the
    `openshift.io/user-monitoring:"false"` label to the resource's namespace or
    the resource itself (the latter requires at least OCP 4.16).


### AlertmanagerConfig

- Invalid secret or configmap key reference.
  - Verify that the secret/configmap object exists and that they key is present
    in the secret/configmap.
- Invalid receiver or route settings (for example, a missing URL in a Slack action).
  - Fix the improper syntax.
- Configuration option which is not yet available in the Alertmanager version.
  - Update the resource to not use this option.
- Unsupported match rules in inhibition rules.
  - Fix the match rule syntax.

The admission webhook should be able to catch most of these errors. In this
case, the admission webhook might be offline. Please check the
`prometheus-operator-admission-webhook` deployment in the
`openshift-monitoring` namespace.


### PrometheusRule

The resource can be invalid because it contains an invalid expression which
needs to be fixed. The admission webhook should be able to catch the error of
an invalid expression in a `PrometheusRule` object. In this case, the admission
webhook might be offline. Please check the
`prometheus-operator-admission-webhook` deployment in the
`openshift-monitoring` namespace.


## Additional resources

- ["PrometheusOperatorRejectedResources" alert firing continuously in a Red Hat OpenShift Service in RHOCP 4](https://access.redhat.com/solutions/6992399)



------------------------------


Original Filename:  PrometheusRemoteStorageFailures.md

# PrometheusRemoteStorageFailures

## Meaning

The `PrometheusRemoteStorageFailures` alert triggers when failures to send
samples to remote storage ave been constantly increasing for more than 15
minutes for either platform Prometheus pods or user-defined monitoring
Prometheus pods.

## Impact

Prometheus samples in remote storage might be missing. Depending on the
`remote_write` pipeline configuration, Prometheus memory usage might increase
while pending samples are queued.

## Diagnosis

* Check the `namespace` label in the alert message to determine if the alert was
  triggered for the instance of Prometheus used for default cluster monitoring
  or for the instance that monitors user-defined projects. The `namespace` value
  indicates the Prometheus instance: `openshift-monitoring`for default
  monitoring and `openshift-user-workload-monitoring` for user-defined
  monitoring.

* Review the logs for the affected Prometheus instance:

  ```console
  $ NAMESPACE='<value of namespace label from alert>'

  $ oc -n $NAMESPACE logs -l 'app.kubernetes.io/component=prometheus'
  level=error ... msg="Failed to send batch, retrying" ...
  ```

* Review the Prometheus logs and the remote storage logs.

## Mitigation

This alert fires when Prometheus has an issue communicating with the remote
system. The cause can be on either the Prometheus side or the remote side.

Common issues that can cause the alert to fire include the following:

* **Cause**: Failure to authenticate to the remote storage system
  * **Mitigation**: Verify that the authentication parameters in the Cluster
    Monitoring (CMO) or in the user workload are correct.

* **Cause**: Requests hitting rate-limits
  * **Mitigation**: Tweak the queue configuration in the CMO and user-workload
    config maps and/or limit the number of samples being sent.

* **Cause**: 5xx HTTP errors
  * **Mitigation**: Review the logs on for the remote storage system.

If the logs indicate a configuration error, troubleshoot the issue. Note
that the issue might be related to general networking issues or a bad configuration.

The cause might also be that the amount of data snet to the remote system is too
high for a given network speed. If so, minimize transfers by limiting which
metrics are sent to remote storage.

Additionally, you can check the `cluster-network-operator` configuration to help
debug possible networking issues.



------------------------------


Original Filename:  PrometheusRuleFailures.md

# PrometheusRuleFailures

## Meaning

The `PrometheusRuleFailures` alert triggers when there has been
a constant increase in failed evaluations of Prometheus rules for more
than 15 minutes.

## Impact

Recorded metrics and alerts might be missing or inaccurate.

## Diagnosis

1. Determine whether the alert has triggered for the instance of Prometheus used
for default cluster monitoring or for the instance that monitors user-defined
projects by viewing the alert message's `namespace` label: the namespace for
default cluster monitoring is `openshift-monitoring`; the namespace for user
workload monitoring is `openshift-user-workload-monitoring`.

1. Review the logs for the affected Prometheus instance:

    ```console
    $ NAMESPACE='<value of namespace label from alert>'

    $ oc -n $NAMESPACE logs -l 'app.kubernetes.io/name=prometheus' | \
    grep -o 'Evaluating rule failed.*' | sort | uniq -c | sort -n
    level=error ... msg="Evaluating rule failed." ...
    ```

Note that you can also evaluate the rule expression in the OpenShift web
console.

## Mitigation

If the logs indicate a syntax or other configuration error, troubleshoot the
issue:

- If a `PrometheusRule` is included with OpenShift, open a support case so that
a bug can be logged and the expression fixed.
- If a `PrometheusRule` is not included with OpenShift, then correct the
corresponding resource.



------------------------------


Original Filename:  PrometheusScrapeBodySizeLimitHit.md

# PrometheusScrapeBodySizeLimitHit

## Meaning

The `PrometheusScrapeBodySizeLimitHit` alert triggers when at least one
Prometheus scrape target replies with a response body larger than the
value configured in the `enforcedBodySizeLimit` field in the
`cluster-monitoring-config` config map in the `openshift-monitoring` namespace.

By default, no limit exists on the body size of scraped targets. When a value
is defined for `enforcedBodySizeLimit`, this limit prevents Prometheus from
consuming large amounts of memory if scraped targets return a response of a
size that exceeds the defined limit.

## Impact

Metrics coming from targets responding with a body size that exceeds the
configured size limit are not ingested by Prometheus. The targets are
considered to be down, and they will have their `up` metric set to `0`, which
might also trigger the `TargetDown` alert.

## Diagnosis

You can view the value set for the body size limit in the
`cluster-monitoring-config` config map in the `openshift-monitoring` namespace.
View this value by entering the following command:

```bash
oc get cm -n openshift-monitoring cluster-monitoring-config -o yaml | grep enforcedBodySizeLimit
```

To discover the targets that are exceeding the configured body size limit, open
the OpenShift web console, go to the **Observe** --> **Targets** page, and check
to see which targets are down.

To get more information than is available in the web console, such as details
about discovered labels and the scrape pool, query the Prometheus API endpoint
`/api/v1/targets`. Querying this endpoint will return useful debugging
information for every target, as shown in the following example:

```json
{
  "status": "success",
  "data": {
    "activeTargets": [
      {
        "discoveredLabels": {
          "__address__": "10.128.0.6:8443",
          "__meta_kubernetes_endpoint_address_target_kind": "Pod",
          "__meta_kubernetes_endpoint_address_target_name": "openshift-apiserver-operator-7475b9d64-mdrlc",
          "__meta_kubernetes_endpoint_node_name": "ci-ln-6tfxd7t-72292-d7lf2-master-2",
          ...
          "job": "serviceMonitor/openshift-apiserver-operator/openshift-apiserver-operator/0"
        },
        "labels": {
          "container": "openshift-apiserver-operator",
          "endpoint": "https",
          "instance": "10.128.0.6:8443",
          "job": "metrics",
          "namespace": "openshift-apiserver-operator",
          "pod": "openshift-apiserver-operator-7475b9d64-mdrlc",
          "service": "metrics"
        },
        "scrapePool": "serviceMonitor/openshift-apiserver-operator/openshift-apiserver-operator/0",
        "scrapeUrl": "https://10.128.0.6:8443/metrics",
        "globalUrl": "https://10.128.0.6:8443/metrics",
        "lastError": "",
        "lastScrape": "2022-07-05T13:59:42.924932804Z",
        "lastScrapeDuration": 0.017444282,
        "health": "up",
        "scrapeInterval": "30s",
        "scrapeTimeout": "10s"
      },
      ...
    ],
    "droppedTargets": [
      ...
    ],
  }
}
```

In the `data.activeTargets` field, search for targets in which the value of the
`health` field is not `up`, and check the `lastError` field for confirmation:

1. Get the name of the secret containing the token of the `prometheus-k8s`
   service account by running the following command to check for the name
   `prometheus-k8s-token-[a-z]+` in the line `Tokens`. The following example
   uses the secret name `prometheus-k8s-token-nwtrf`:

    ```bash
    $ oc describe sa prometheus-k8s -n openshift-monitoring
    Name:                prometheus-k8s
    Namespace:           openshift-monitoring
    Labels:              app.kubernetes.io/component=prometheus
                        app.kubernetes.io/instance=k8s
                        app.kubernetes.io/name=prometheus
                        app.kubernetes.io/part-of=openshift-monitoring
                        app.kubernetes.io/version=2.35.0
    Annotations:         serviceaccounts.openshift.io/oauth-redirectreference.prometheus-k8s:
                          {"kind":"OAuthRedirectReference","apiVersion":"v1","reference":{"kind":"Route","name":"prometheus-k8s"}}
    Image pull secrets:  prometheus-k8s-dockercfg-6wl6b
    Mountable secrets:   prometheus-k8s-dockercfg-6wl6b
    Tokens:              prometheus-k8s-token-nwtrf
    Events:              <none>
    ```
2. If no token exists, create a token by entering the following command and
   skip the next step:

    ```bash
    token=$(oc sa new-token prometheus-k8s -n openshift-monitoring)
    ```

3. If a token exists, decode the token from the secret:

    ```bash
    token=$(oc get secret $secret_name_here -n openshift-monitoring -o jsonpath={.data.token} | base64 -d)
    ```

4. Get the route URL of the Prometheus API endpoint:

    ```bash
    host=$(oc get route -n openshift-monitoring prometheus-k8s -o jsonpath={.spec.host})
    ```

5. List all of the scraped targets with a health status different from `up`:

    ```bash
    curl -H "Authorization: Bearer $token" -k https://${host}/api/v1/targets | jq '.data.activeTargets[]|select(.health!="up")'
    ```

6. Review the response body size of the failing target. Enter the following
   command to simulate a scrape of the target's `scrapeUrl` and view the
   response body size:

    ```bash
    oc exec -it prometheus-k8s-0 -n openshift-monitoring  -- curl -k --key /etc/prometheus/secrets/metrics-client-certs/tls.key --cert /etc/prometheus/secrets/metrics-client-certs/tls.crt --cacert /etc/prometheus/configmaps/serving-certs-ca-bundle/service-ca.crt $scrape_url | wc --bytes
    ```

## Mitigation

Your analysis of the issue might reveal that the alert was triggered by one of
two causes:

* The value set for `enforcedBodySizeLimit` is too small.
* A bug exists in the target causing it to report too many metrics.

### Increasing the Body Size Limit

You can increase the body size limit by editing the `cluster-monitoring-config`
config map in the `openshift-monitoring` namespace.

The `prometheusK8s.enforcedBodySizeLimit` field defines this limit. Values for
this field use the [Prometheus size format](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#size).

The following example sets the body size limit to 20MB:

 ```yaml
apiVersion: v1
data:
  config.yaml: |-
    prometheusK8s:
      enforcedBodySizeLimit: 20MB
kind: ConfigMap
metadata:
  name: cluster-monitoring-config
  namespace: openshift-monitoring
 ```

### Bug in the Scraped Target

If you think that the response of the scraped target is too large, you can
contact Red Hat Customer Experience & Engagement.



------------------------------


Original Filename:  PrometheusTargetSyncFailure.md

# PrometheusTargetSyncFailure

## Meaning

The `PrometheusTargetSyncFailure` alert triggers when at least one
Prometheus instance has consistently failed to sync its configuration.

## Impact

Metrics and alerts might be missing or inaccurate.

## Diagnosis

1. Determine whether the alert has triggered for the instance of Prometheus used
for default cluster monitoring or for the instance that monitors user-defined
projects by viewing the alert message's `namespace` label: the namespace for
default cluster monitoring is `openshift-monitoring`; the namespace for user
workload monitoring is `openshift-user-workload-monitoring`.

1. Review the logs for the affected Prometheus instance:

    ```console
    $ NAMESPACE='<value of namespace label from alert>'

    $ oc -n $NAMESPACE logs -l 'app.kubernetes.io/name=prometheus'
    level=error ... msg="Creating target failed" ...
    ```

## Mitigation

If the logs indicate a syntax or other configuration error, correct the
corresponding `ServiceMonitor`, `PodMonitor`, `Probe`, or other configuration
resource.



------------------------------


Original Filename:  TargetDown.md

# TargetDown

This runbook provides guidance for diagnosing and resolving the `TargetDown`` alert
in OpenShift Container Platform.

## Meaning

The `TargetDown` alert fires when Prometheus has been unable to scrape one
or more targets over a specific period of time. It is triggered when specific
scrape targets within a service remain unreachable (`up` metric = 0) for a
predetermined duration.

## Impact

- **Visibility**: If a target is down, the metrics from the affected targets will
  not be captured by Prometheus. If metrics are not captured, you will have only
  limited insights about the health and performance of the associated application.
- **Alerts**: If a target is down, the accuracy of certain alerts can be compromised.
  For example, critical alerts might not be triggered, potentially cause service
  disruptions to go undetected.
- **Resource Optimization**: Auto-scalers might not function correctly if essential
  metrics are missing, which can result in wasted resources or a degraded user
  experience for your applications.

## Diagnosis and mitigation

### Identifying targets that are down

- Navigate to **Observe** -> **Targets** in the OpenShift web console. Choose **Down**
  in the **Filter** combo button to quickly list down targets. Click on individual
  targets for details and error messages from the last scrape attempt.
- Alternatively, query `up == 0` in **Observe** -> **Metrics** in the OpenShift web
  console. The metric labels will help pinpoint the affected Prometheus instance
  and the down target.

The alert and the metric `up` have labels `namespace`, `service`， `job`, `pod`
and `prometheus`.
With these labels we can identify which Prometheus instance fails to scrape which
target:

- The label `prometheus` should be either `openshift-monitoring/k8s` or `openshift-user-workload-monitoring/user-workload`,
  indicating the Prometheus pods scraping the target are either `prometheus-k8s-0`
  / `prometheus-k8s-1` in the namespace `openshift-monitoring`, or `prometheus-user-workload-0`
  / `prometheus-user-workload-1` in the namespace `openshift-user-workload-monitoring`.
- The label `pod` indicates the pod exposing the metrics endpoint.
- The labels `namespace` and `service` that help us locate the `Service` exposing
  the metric endpoint.
- The label `namespace` and `job` can locate the `ServiceMonitor` or `PodMonitor`
  that configures Prometheus to scrape the target. The `job` label is the name of
  the monitor.

Now we have both end of the metric scraping flow as well as the monitor resources
linking them together.
We are ready to diagnosing the root cause by inspecting each component on the scraping
workflow.

### Potential Issues and Resolutions
#### Network Issues

Check the network connectivity between the Prometheus pod and the target pod.
Ensure that the target pod is reachable from the Prometheus pod and that there are
no firewall rules or network interruptions blocking communication.

There are some useful metrics to help investigating network issues:
- `net_conntrack_dialer_conn_attempted_total`
- `net_conntrack_dialer_conn_closed_total`
- `net_conntrack_dialer_conn_established_total`
- `net_conntrack_dialer_conn_failed_total`

OpenShift guide on [Troubleshooting network issues](https://docs.openshift.com/container-platform/4.13/support/troubleshooting/troubleshooting-network-issues.html)
provides more details.

#### Target Resource Exhaustion

Check if the pod's healthy and ready probes reports good state.
Then check whether the metric endpoint is responsive.
We can either forward the metric port to local and then query it using use `curl`,
 `wget` or similar tools. Or on the container exposing the metric, send
query to the port serving the metric endpoint.

If query returns an error, it is probably an application problem.
If the query takes too long or times out, it is probably due to resource exhaustion.

Some applications may enforce rate limiting or throttling. Check if the scraping
traffic is hitting such limits, causing the target to become temporarily unavailable.
Checking the pod's logs and events may help us diagnose such problems.

Then we should check if the target pod resource utilization is too high, causing
it to become unresponsive.
We can refer to the tab **Observe** -> **Dashboards** in the Openshift web Console
to have an overview of resource utilization. The Dashboard `Kubernetes/Compute Resources/Pod`
can show the CPU, memory, network and storage usage of the pod.

To view more details of CPU and memory usage, we can check these metrics:
- CPU Usage
  * `container_cpu_usage_seconds_total`: Cumulative CPU usage in seconds.
  * `pod:container_cpu_usage:sum` Represents the average CPU load of a pod over
  the last 5 minutes.
  * `container_cpu_cfs_throttled_seconds_total` Duration when the CPU was throttled
  due to limits.
- Memory Usage
  * `container_memory_usage_bytes` Current memory usage in bytes.
  * `container_memory_rss` Resident set size in bytes. This metric gives an
  understanding of the memory actively used by a pod.
  * `container_memory_swap` Swap memory usage in bytes.
  * `container_memory_working_set_bytes` Total memory in use. This includes all
  memory regardless of when it was accessed.
  * `container_memory_failcnt` Cumulative count of memory allocation failures.
- File System Usage
  * `container_fs_reads_bytes_total` and `container_fs_writes_bytes_total`
  Cumulative filesystem read and write operations in bytes.
  * `container_fs_reads_total` and `container_fs_writes_total` Cumulative
  filesystem read and write operations in bytes.
  * `kubelet_volume_stats_available_bytes` The free space in a volume in bytes.

If some basic metrics are not available, we can also use this command to get
 CPU and memory usage of a pod:
```bash
oc top pod $POD_NAME
```
As well as this command for volume free space:
```bash
oc exec -n $NAMESPACE $POD_NAME -- df
```

#### Target Application or Service Failure

Investigate if the application or service running on the target is experiencing
issues or has even crashed. Review logs and last metrics from the target pod to
identify any errors or crashes.

Here is [a guide to investigate pod issues](https://docs.openshift.com/container-platform/4.13/support/troubleshooting/investigating-pod-issues.html)
in OpenShift.

#### Incorrect Target Configuration

Verify that the scrape target configuration in Prometheus is correct. This
configuration is generated from the `ServiceMonitor` and `PodMonitors`.
We can get the `ServiceMonitor` and `PodMonitors` related to the alert with this
command using the `namespace` and `job` label. The name of `ServiceMonitor` is the
`job` name unless the property `jobLabel` is set in `ServiceMonitor`.
```bash
oc get servicemonitor $SERVICE_MONITOR_NAME -n $NAMESPACE -o yaml
```
Check the target's port, selector, scheme, TLS settings, etc for invalid values.
Please refer to [the Prometheus Operator API document](https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api.md)
for detailed specification of `ServiceMonitor` and `PodMonitors`.

About the TLS settings, even if the values are correct, it may still fail due to
certificate expiration. Please refer to the next section for details.

#### Expired SSL/TLS Certificates

If the target uses SSL/TLS for communication, check if the SSL/TLS certificate
has expired or certificate files accessible by Prometheus.

The certificate used by Prometheus to scrape metrics endpoint is indicated in the
`.spec.endpoints.tlsConfig.certFile` property of a `ServiceMonitor` or `PodMonitor`.
The path of the certificate file points to a mounted volume on the Prometheus Pod.
Therefore we can deduce which secret holds the certificate.

Here is an example.
We have a `ServiceMonitor` using `/etc/prometheus/secrets/metrics-client-certs/tls.crt`
as its certificate file.
```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  labels:
    app.kubernetes.io/component: exporter
    app.kubernetes.io/name: node-exporter
    app.kubernetes.io/part-of: openshift-monitoring
    app.kubernetes.io/version: 1.5.0
    monitoring.openshift.io/collection-profile: full
  name: node-exporter
  namespace: openshift-monitoring
spec:
  endpoints:
  - bearerTokenSecret:
      key: ""
    interval: 15s
    port: https
    relabelings:
    - action: replace
      regex: (.*)
      replacement: $1
      sourceLabels:
      - __meta_kubernetes_pod_node_name
      targetLabel: instance
    scheme: https
    tlsConfig:
      ca: {}
      caFile: /etc/prometheus/configmaps/serving-certs-ca-bundle/service-ca.crt
      cert: {}
      certFile: /etc/prometheus/secrets/metrics-client-certs/tls.crt
      keyFile: /etc/prometheus/secrets/metrics-client-certs/tls.key
      serverName: node-exporter.openshift-monitoring.svc
  jobLabel: app.kubernetes.io/name
  namespaceSelector: {}
  selector:
    matchLabels:
      app.kubernetes.io/component: exporter
      app.kubernetes.io/name: node-exporter
      app.kubernetes.io/part-of: openshift-monitoring
```
In the `Prometheus` that scrapes this target, the volume mounted at `/etc/prometheus/secrets/*`
are the secrets having the same name as the subdirectory. In this example, the secret
is `metrics-client-certs` in the namespace `openshift-monitoring`. Now we extract
the certificate from the secret using this command:
```bash
oc extract secret/$SECRET_NAME -n $NAMESPACE --keys=tls.crt --to=- > certificate.crt
```
Then we inspect is expiration date.
```bash
openssl x509 -noout -enddate -in certificate.crt
```
The output should contain `notAfter` field as its expiration date.
```bash
notAfter=Aug  6 13:11:20 2025 GMT
```

Normally OpenShift **automatically renews** the certificates before expiration date.
This date should be sometime in the future. If the certificate does expire without
automatic renewal, please contact the OpenShift support team.

If the issue requires immediate resolution, please refer to [this guide on how to
force a certificate renewal](https://access.redhat.com/solutions/5899121).

To diagnose potential issues with automatic certificate renewal, perform the
following checks:
1. Ensure the `prometheus-k8s` stateful set logs do not display errors related to
   certificates.
   ```bash
   oc logs statefulset/prometheus-k8s -n openshift-monitoring
   ```
2. Verify that the scraped target pod(s) logs are free from certificate-related errors.
3. Check that the `cluster-monitoring-operator` pod is running and its logs contain
   no errors regarding certificate rotation.
   ```bash
   oc logs deployment/cluster-monitoring-operator -n openshift-monitoring
   ```
4. Confirm the `prometheus-operator` pod is operational and its logs have no errors
   concerning certificate rotation.
   ```bash
   oc logs deployment/prometheus-operator -n openshift-monitoring
   ```


#### Prometheus Scraping Interval

Ensure that the scraping interval for the target is appropriately configured.
Too frequent scraping can degrade the performance of target pod, even causing
timeout when scraping.

The last scrape duration is visible on the **Observe** -> **Targets** tab in the
OpenShift web Console.

Otherwise we can check the metric `scrape_duration_seconds`.

If scrape duration is close to the scrape interval, we may consider to increase
the interval.

The scrape interval is configured in the `ServiceMonitor` or `PodMonitor`.


#### Target metrics path

Verify that the metrics path in the target is correctly defined in the `ServiceMonitor`
and `PodMonitor` resources. If the scraped target pod changes its metrics path in
recent code update, the metric endpoint should update accordingly.

#### Target restart or update

If the target was recently restarted or updated without replications, it might
temporarily become unavailable. Check if this is the case and allow some time for
it to stabilize.

#### Node failures

Check if the node where the target is running has experienced failures or evictions.
See [Verifying Node Health](https://docs.openshift.com/container-platform/4.13/support/troubleshooting/verifying-node-health.html)
for more information.



------------------------------


Original Filename:  TelemeterClientFailures.md

# TelemeterClientFailures

## Meaning

The alert `TelemeterClientFailures` is triggered when the Telemeter client fails
to send Telemetry data at a certain rate over a period of time
to Red Hat.

The `telemeter-client` pod running in the `openshift-monitoring`
namespace collects [selected platform metrics](https://docs.openshift.com/container-platform/latest/support/remote_health_monitoring/showing-data-collected-by-remote-health-monitoring.html#showing-data-collected-from-the-cluster_showing-data-collected-by-remote-health-monitoring)
from the `prometheus-k8s` service at
regular intervals using the `/federate` endpoint and ships them
to Red Hat using a custom secured protocol.

## Impact

When the alert fires, Red Hat support and engineering teams don't have a complete
view of the cluster anymore. It may hinder the ability for Red Hat to
proactively detect issues in the cluster.

## Diagnosis

* Review the logs for the pod `telemeter-client`
in the `openshift-monitoring` namespace.

You can review the logs for the `telemeter-client` pod in the
`openshift-monitoring` namespace by running the following command:

```console
oc logs -n openshift-monitoring deployment.apps/telemeter-client -c telemeter-client -f
```

* Open the Observe > Metrics page in the OCP admin console and execute the following
  PromQL expressions to identify where the issue happens.

  * OCP 4.17 and above

    ```console
    sum by(client, status_code) (rate(metricsclient_http_requests_total{status_code!~"200"}[15m])) > 0
    ```

    * The value of the `client` label is `federate_from` when the Telemeter client
      failed to retrieve metrics from Prometheus.
    * The value of the `client` label is `federate_to` when the Telemeter client
      failed to send metrics to Red Hat.

  * OCP 4.16 and below

    * The following query returns result when the Telemeter client failed to retrieve
      metrics from Prometheus.

      ```console
      sum by(client, status_code) (rate(metricsclient_request_retrieve{status_code!~"200"}[15m])) > 0
      ```

    * The following query returns result when the Telemeter client failed to send
      metrics to the Red Hat.

      ```console
      sum by(client, status_code) (rate(metricsclient_request_send{status_code!~"200"}[15m])) > 0
      ```

## Mitigation

The resolution of the issue depends on the origin of the failure.

* The telemeter client fails to retrieve metrics from Prometheus.
  * You need to check the availability of the Prometheus pods in the `openshift-monitoring`
    namespace. If the pods are running, check the logs of the `prometheus` container.

* The telemeter client fails to send metrics to the server.

  * If you use a firewall, make sure that it configured as specified in the
    [OCP documentation](https://docs.openshift.com/container-platform/latest/installing/install_config/configuring-firewall.html).

  * Check the `status_code` label values returned by the PromQL query executed
    at the previous step.
    * 401 and 403 codes indicate a misconfiguration of the client. A typical reason
      is the global [cluster pull secret](https://docs.openshift.com/container-platform/latest/openshift_images/managing_images/using-image-pull-secrets.html#images-update-global-pull-secret_using-image-pull-secrets).
      * Make sure your global cluster pull secret is up to date
    * Status codes between 500 and 599 indicate a problem from the Telemeter
      server side.
      * If you use HTTP proxies and/or firewalls, check their logs.
      * If the error is due to an outage on the Red Hat side and the alert
        doesn't resolve within an error, you can contact the Red Hat support.



------------------------------


Original Filename:  ThanosRuleQueueIsDroppingAlerts.md

# ThanosRuleQueueIsDroppingAlerts

## Meaning

The `ThanosRuleQueueIsDroppingAlerts` alert triggers when the Thanos Ruler queue
is found to be dropping alerting events.

The Thanos Ruler component is deployed only when user-defined monitoring is
enabled. The component enables alerting rules to be deployed as part of
user-defined monitoring. These rules can query the Prometheus instance
responsible for core cluster components and also the Prometheus instance used
for user-defined monitoring.

## Impact

Alerts for user workloads might not be delivered.

## Diagnosis

Review the logs for the Thanos Ruler pods:

```console
$ oc -n openshift-user-workload-monitoring logs -l 'thanos-ruler=user-workload'
...
level=warn ... msg="Alert notification queue full, dropping alerts" numDropped=100
level=warn ... msg="Alert batch larger than queue capacity, dropping alerts" numDropped=100
```

If this alert triggers, it is likely that the user-defined monitoring stack is
firing an extremely large number of alerts. Log into the OpenShift web console
and review the active alerts.

## Mitigation

The default queue capacity for Thanos Ruler is quite high at 10,000 items,
which means that the most likely cause of this issue is a misconfiguration that
causes the user-defined monitoring stack to overload Thanos Ruler with
duplicate or otherwise erroneous alerts. Review all active alerts in the
OpenShift web console and correct any misconfigurations. You can also consider
grouping alerts to mitigate this issue.




------------------------------


Original Filename:  ThanosRuleRuleEvaluationLatencyHigh.md

# ThanosRuleRuleEvaluationLatencyHigh

## Meaning

The `ThanosRuleRuleEvaluationLatencyHigh` alert triggers when Thanos Ruler
misses rule evaluations due to slow rule group processing.

This alert triggers only for user-defined recording and alerting rules.

## Impact

The delivery of alerts will be delayed.

## Diagnosis

Review the logs for the Thanos Ruler pods:

```console
oc -n openshift-user-workload-monitoring logs -l 'thanos-ruler=user-workload' \
-c thanos-ruler
```

Review the logs for the Thanos Querier pods:

```console
oc -n openshift-monitoring logs -l 'app.kubernetes.io/name=thanos-query' \
-c thanos-query
```

This alert triggers when rule evaluation takes longer than the configured
interval.

If the alert triggers, it might indicate that Thanos Querier is taking too much
time to evaluate the query. This alert will trigger if rule evaluation for even
a single rule is taking too long--that is, longer than the interval for that
group.

If the alert triggers, it might also mean that other problems exist, such as
StoreAPIs are responding slowly or a query expression in a rule is too complex.

## Mitigation

- Check for a misconfiguration that causes the user workload monitoring stack
  to overload Thanos Ruler with duplicate or otherwise erroneous alerts.

- Audit the rule groups that fire the alert to identify expensive queries and
  consider splitting these rule groups into smaller groups if possible.

- Verify whether resource limits are set on any monitoring components
  and whether any components are throttled.

- Check whether any of the configured `thanos-querier` storeAPI endpoints
  have connectivity issues.



------------------------------


