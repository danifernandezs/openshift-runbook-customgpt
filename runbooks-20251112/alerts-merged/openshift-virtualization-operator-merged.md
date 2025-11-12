Original Filename:  CDIDataImportCronOutdated.md

# CDIDataImportCronOutdated

## Meaning

This alert fires when `DataImportCron` cannot poll or import the latest disk
image versions.

`DataImportCron` polls disk images, checking for the latest versions, and
imports the images into persistent volume claims (PVCs) or VolumeSnapshots. This
process ensures that these sources are updated to the latest version so that
they can be used as reliable clone sources or golden images for virtual machines
(VMs).

For golden images, _latest_ refers to the latest operating system of the
distribution. For other disk images, _latest_ refers to the latest hash of the
image that is available.

**Note:** If the status of a `DataImportCron` PVC is `Pending` because there is
no
default storage class, the `CDIDataImportCronOutdated` alert is suppressed and
the
`CDINoDefaultStorageClass` alert is triggered.

## Impact

VMs might be created from outdated disk images.

VMs might fail to start because no boot source is available for cloning.

## Diagnosis

1. Check the cluster for a default OpenShift Container Platform storage class:
   ```bash
   $ oc get sc -o jsonpath='{.items[?(.metadata.annotations.storageclass\.kubernetes\.io\/is-default-class=="true")].metadata.name}'
   ```

   Check the cluster for a default virtualization storage class:
   ```bash
   $ oc get sc -o jsonpath='{.items[?(.metadata.annotations.storageclass\.kubevirt\.io\/is-default-virt-class=="true")].metadata.name}'
   ```

   The output displays the default (OpenShift Container Platform and/or
virtualization) storage
   class. You must either set a default storage class on the cluster, or ask for
   a specific storage class in the `DataImportCron` specification, in order for
   the `DataImportCron` to poll and import golden images. If the default
   storage class does not exist, the created import DataVolume and PVC will be
   in `Pending` phase.

2. List the `DataImportCron` objects that are not up-to-date:

   ```bash
   $ oc get dataimportcron -A -o jsonpath='{range .items[*]}{.status.conditions[?(@.type=="UpToDate")].status}{"\t"}{.metadata.namespace}{"/"}{.metadata.name}{"\n"}{end}' | grep False
   ```

3. If a default storage class is not defined on the cluster, check the
`DataImportCron` specification for a `DataVolume` template storage class:

   ```bash
   $ oc -n <namespace> get dataimportcron <dataimportcron> -o jsonpath='{.spec.template.spec.storage.storageClassName}{"\n"}'
   ```

4. Obtain the name of the `DataVolume` associated with the `DataImportCron`
object:

   ```bash
   $ oc -n <namespace> get dataimportcron <dataimportcron> -o jsonpath='{.status.lastImportedPVC.name}{"\n"}'
   ```

5. Check the `DataVolume` status:

   ```bash
   $ oc -n <namespace> get dv <datavolume> -o jsonpath-as-json='{.status}'
   ```

6. Set the `CDI_NAMESPACE` environment variable:

   ```bash
   $ export CDI_NAMESPACE="$(oc get deployment -A -o jsonpath='{.items[?(.metadata.name=="cdi-operator")].metadata.namespace}')"
   ```

7. Check the `cdi-deployment` log for error messages:

   ```bash
   $ oc logs -n $CDI_NAMESPACE deployment/cdi-deployment
   ```

## Mitigation

1. Set a default storage class, either on the cluster or in the `DataImportCron`
specification, to poll and import golden images. The updated Containerized Data
Importer (CDI) should resolve the issue within a few seconds.

2. If the issue does not resolve itself, or, if you have changed the default
storage class in the cluster, you must delete the existing boot sources
(data volumes or volume snapshots) in the cluster namespace that are configured
with the previous default storage class. The CDI will recreate the data volumes
with the newly configured default storage class.

3. If your cluster is installed in a restricted network environment, disable the
`enableCommonBootImageImport` feature gate in order to opt out of automatic
updates:

   ```bash
   $ oc patch hco kubevirt-hyperconverged -n $CDI_NAMESPACE --type json -p '[{"op": "replace", "path": "/spec/featureGates/enableCommonBootImageImport", "value": false}]'
   ```

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  CDIDataVolumeUnusualRestartCount.md

# CDIDataVolumeUnusualRestartCount

## Meaning

This alert fires when a `DataVolume` object restarts more than three times.

## Impact

Data volumes are responsible for importing and creating a virtual machine disk
on a persistent volume claim. If a data volume restarts more than three times,
these operations are unlikely to succeed. You must diagnose and resolve the
issue.

## Diagnosis

1. Find Containerized Data Importer (CDI) pods with more than three restarts:

   ```bash
   $ oc get pods --all-namespaces -l app=containerized-data-importer -o=jsonpath='{range .items[?(@.status.containerStatuses[0].restartCount>3)]}{.metadata.name}{"/"}{.metadata.namespace}{"\n"}'
   ```

2. Obtain the details of the pods:

   ```bash
   $ oc -n <namespace> describe pods <pod>
   ```

3. Check the pod logs for error messages:

   ```bash
   $ oc -n <namespace> logs <pod>
   ```

## Mitigation

Delete the data volume, resolve the issue, and create a new data volume.

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  CDIDefaultStorageClassDegraded.md

# CDIDefaultStorageClassDegraded

## Meaning

This alert fires if the default storage class does not support smart cloning
(CSI or snapshot-based) or the ReadWriteMany access mode. The alert does not
fire if at least one default storage class supports these features.

A default virtualization storage class has precedence over a default OpenShift
Container Platform
storage class for creating a VirtualMachine disk image.

In case of single-node OpenShift, the alert is suppressed if there is a default
storage class that supports smart cloning, but not ReadWriteMany.

## Impact

If the default storage class does not support smart cloning, the default cloning
method is host-assisted cloning, which is much less efficient.

If the default storage class does not support ReadWriteMany, virtual machines
(VMs) cannot be live migrated.

## Diagnosis

1. Get the default virtualization storage class by running the following
command:

   ```bash
   $ export CDI_DEFAULT_VIRT_SC="$(oc get sc -o jsonpath='{.items[?(.metadata.annotations.storageclass\.kubernetes\.io\/is-default-class=="true")].metadata.name}')"
   ```

2. If a default virtualization storage class exists, check that it supports
ReadWriteMany by running the following command:

   ```bash
   $ oc get storageprofile $CDI_DEFAULT_VIRT_SC -o jsonpath='{.status.claimPropertySets}' | grep ReadWriteMany
   ```

3. If there is no default virtualization storage class, get the default
OpenShift Container Platform storage class by running the following command:

   ```bash
   $ export CDI_DEFAULT_K8S_SC="$(oc get sc -o jsonpath='{.items[?(.metadata.annotations.storageclass\.kubernetes\.io\/is-default-class=="true")].metadata.name}')"
   ```

4. If a default OpenShift Container Platform storage class exists, check that
it supports
ReadWriteMany by running the following command:

   ```bash
   $ oc get storageprofile $CDI_DEFAULT_VIRT_SC -o jsonpath='{.status.claimPropertySets}' | grep ReadWriteMany
   ```

## Mitigation

Ensure that you have a default (OpenShift Container Platform or virtualization)
storage class, and
that the default storage class supports smart cloning and ReadWriteMany.

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case, attaching
the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  CDIMultipleDefaultVirtStorageClasses.md

# CDIMultipleDefaultVirtStorageClasses

## Meaning

This alert fires when more than one default virtualization storage class exists.

A default virtualization storage class has precedence over a default OpenShift
Container Platform
storage class for creating a VirtualMachine disk image.

## Impact

If more than one default virtualization storage class exists, a data volume that
requests a default storage class (storage class not explicitly specified),
receives the most recently created one.

## Diagnosis

Obtain a list of default virtualization storage classes by running the following
command:

```bash
$ oc get sc -o jsonpath='{.items[?(.metadata.annotations.storageclass\.kubevirt\.io\/is-default-virt-class=="true")].metadata.name}'
```

## Mitigation

Ensure that only one storage class has the default virtualization storage class
annotation.

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  CDINoDefaultStorageClass.md

# CDINoDefaultStorageClass

## Meaning

This alert fires when a data volume is `Pending` because there is no default
storage class.

A default virtualization storage class has precedence over a default OpenShift
Container Platform
storage class for creating a VirtualMachine disk image.

## Impact

If there is no default OpenShift Container Platform storage class and no
default virtualization
storage class, a data volume that does not have a specified storage class
remains in a `Pending` phase.

## Diagnosis

1. Check for a default OpenShift Container Platform storage class by running
the following
command:

  ```bash
  $ oc get sc -o jsonpath='{.items[?(.metadata.annotations.storageclass\.kubernetes\.io\/is-default-class=="true")].metadata.name}'
  ```

2. Check for a default virtualization storage class by running the following
command:

  ```bash
  $ oc get sc -o jsonpath='{.items[?(.metadata.annotations.storageclass\.kubevirt\.io\/is-default-virt-class=="true")].metadata.name}'
  ```

## Mitigation

Create a default storage class for OpenShift Container Platform,
virtualization, or both.

A default virtualization storage class has precedence over a default OpenShift
Container Platform
storage class for creating a virtual machine disk image.

* Create a default OpenShift Container Platform storage class by running the
following command:

  ```bash
  $ oc patch storageclass <storage-class-name> -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
  ```

* Create a default virtualization storage class by running the following
command:

  ```bash
  $ oc patch storageclass <storage-class-name> -p '{"metadata": {"annotations":{"storageclass.kubevirt.io/is-default-virt-class":"true"}}}'
  ```

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  CDINotReady.md

# CDINotReady

## Meaning

This alert fires when the Containerized Data Importer (CDI) is in a degraded
state:

- Not progressing
- Not available to use

## Impact

CDI is not usable, so users cannot build virtual machine disks on persistent
volume claims (PVCs) using CDI's data volumes. CDI components are not ready, and
they stopped progressing towards a ready state.

## Diagnosis

1. Set the `CDI_NAMESPACE` environment variable:

   ```bash
   $ export CDI_NAMESPACE="$(oc get deployment -A | grep cdi-operator | awk '{print $1}')"
   ```

2. Check the CDI deployment for components that are not ready:

   ```bash
   $ oc -n $CDI_NAMESPACE get deploy -l cdi.kubevirt.io
   ```

3. Check the details of the failing pod:

   ```bash
   $ oc -n $CDI_NAMESPACE describe pods <pod>
   ```

4. Check the logs of the failing pod:

   ```bash
   $ oc -n $CDI_NAMESPACE logs <pod>
   ```

## Mitigation

Try to identify the root cause and resolve the issue.

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  CDIOperatorDown.md

# CDIOperatorDown

## Meaning

This alert fires when the Containerized Data Importer (CDI) Operator is down.
The CDI Operator deploys and manages the CDI infrastructure components, such as
data volume and persistent volume claim (PVC) controllers. These controllers
help users build virtual machine disks on PVCs.

## Impact

The CDI components might fail to deploy or to stay in a required state. The CDI
installation might not function correctly.

## Diagnosis

1. Set the `CDI_NAMESPACE` environment variable:

   ```bash
   $ export CDI_NAMESPACE="$(oc get deployment -A | grep cdi-operator | awk '{print $1}')"
   ```

2. Check whether the `cdi-operator` pod is currently running:

   ```bash
   $ oc -n $CDI_NAMESPACE get pods -l name=cdi-operator
   ```

3. Obtain the details of the `cdi-operator` pod:

   ```bash
   $ oc -n $CDI_NAMESPACE describe pods -l name=cdi-operator
   ```

4. Check the log of the `cdi-operator` pod for errors:

   ```bash
   $ oc -n $CDI_NAMESPACE logs -l name=cdi-operator
   ```

## Mitigation

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  CDIStorageProfilesIncomplete.md

# CDIStorageProfilesIncomplete

## Meaning

This alert fires when a Containerized Data Importer (CDI) storage profile is
incomplete.

If a storage profile is incomplete, the CDI cannot infer persistent volume claim
(PVC) fields, such as `volumeMode` and  `accessModes`, which are required to
create a virtual machine (VM) disk.

## Impact

The CDI cannot create a VM disk on the PVC.

## Diagnosis

- Identify the incomplete storage profile:

  ```bash
  $ oc get storageprofile <storage_class>
  ```

## Mitigation

- Add the missing storage profile information:

  ```bash
  $ oc patch storageprofile local --type=merge -p '{"spec": \
    {"claimPropertySets": [{"accessModes": ["ReadWriteOnce"], \
    "volumeMode": "Filesystem"}]}}'
  ```

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  CnaoDown.md

# CnaoDown

## Meaning

This alert fires when the Cluster Network Addons Operator (CNAO) is down.
The CNAO deploys additional networking components on top of the cluster.

## Impact

If the CNAO is not running, the cluster cannot reconcile changes to virtual
machine components. As a result, the changes might fail to take effect.

## Diagnosis

1. Set the `NAMESPACE` environment variable:

   ```bash
   $ export NAMESPACE="$(oc get deployment -A | grep cluster-network-addons-operator | awk '{print $1}')"
   ```

2. Check the status of the `cluster-network-addons-operator` pod:

   ```bash
   $ oc -n $NAMESPACE get pods -l name=cluster-network-addons-operator
   ```

3. Check the `cluster-network-addons-operator` logs for error messages:

   ```bash
   $ oc -n $NAMESPACE logs -l name=cluster-network-addons-operator
   ```

4. Obtain the details of the `cluster-network-addons-operator` pods:

   ```bash
   $ oc -n $NAMESPACE describe pods -l name=cluster-network-addons-operator
   ```

## Mitigation

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  CnaoNmstateMigration.md

# CnaoNmstateMigration

## Meaning

This alert fires when a `kubernetes-nmstate` deployment is detected and the
OpenShift Container Platform NMState Operator is not installed. This alert only
affects OpenShift
Virtualization 4.10.

The Cluster Network Addons Operator (CNAO) does not support `kubernetes-nmstate`
deployments in OpenShift Virtualization 4.11 and later.

## Impact

You cannot upgrade your cluster to OpenShift Virtualization 4.11.

## Mitigation

Install the OpenShift Container Platform NMState Operator from the OperatorHub.
CNAO automatically
transfers the `kubernetes-nmstate` deployment to the Operator.

Afterwards, you can upgrade to OpenShift Virtualization 4.11.


------------------------------


Original Filename:  DeprecatedMachineType.md

# DeprecatedMachineType

## Meaning
This alert triggers when one or more Virtual Machines (VMs) are using machine
types that have been marked as no longer supported.

## Impact

**Running VMs**
- Continue running but are using an unsupported machine type.
- Newer nodes might not support the machine type, so the next live migration may
  fail or become unresponsive.
- This can block node maintenance and disrupt high availability.

**Stopped VMs**
- No immediate issue while stopped.
- When restarted, they might fail to schedule or become unresponsive if newer
  nodes no longer support the machine type.
- This might prevent workloads from coming back online after maintenance
  or cluster upgrades.

## Diagnosis
The alert detects VMs using unsupported machine types.

**Identify affected VMs**
Use the alert description to locate VM names, namespaces, and nodes (if
running).

**Root Cause:**
The VM's `spec.template.spec.domain.machine.type` field is set to a type
that has been marked as unsupported. This can happen due to:

- VMs created before the removal of support for a machine type.
- VM templates not updated after cluster upgrades.
- Manual VM creation using old machine type references.

## Mitigation
Update affected VMs to use a supported machine type. You can do one of the
following:

- Edit VM definitions individually by modifying the
  `spec.template.spec.domain.machine.type` field.
- For a smoother and cleaner update of multiple VMs, use the
  `kubevirt-api-lifecycle-automation` tool to transition all deprecated VMs
  in one operation. This ensures consistent, automated migration and reduces
  manual errors or downtime during cluster upgrades. For details, see [Updating
multiple

VMs](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/virtualization/managing-vms#virt-updating-multiple-vms_virt-edit-vms).

**Important:** Plan and apply these updates before performing cluster
upgrades to avoid VM restart failures or compatibility issues.

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  DuplicateWaspAgentDSDetected.md

# DuplicateWaspAgentDSDetected

## Meaning
wasp-agent is a node-local agent that enables swap for burstable QoS pods.
It mimics the behavior of kubelet swap feature.
wasp-agent deployment consists of Daemonset, serivce account,
role binding, privileged SCC. Wasp-agent currently deployed automatically
by the HCO operator when the memory overcommit percentage is set to a
value higher than 100%. In the past wasp-agent was deployed manually
according to the user-guide. It may happen that the previous wasp-agent
deployment still exists. This alert will be fired when such scenario
detected, so the user would be able to remove the old deployment
according to the steps in the mitigation section.

## Impact
When memory overcommit percentage is set to a value higher than 100% an
automatic deployment of wasp-agent will start. This may lead to two
wasp-agent deployments run at the same time on the cluster, which is undesired.

## Diagnosis
Identify the duplicate wasp-agent daemonset :
   ```bash
   oc get ds wasp-agent -n wasp
   ```

## Mitigation

1. Delete the wasp-agent Daemonset
   ```bash
   oc delete ds wasp-agent -n wasp
   ```
2. Delete the wasp-agent service account
   ```bash
   oc delete sa wasp -n wasp
   ```
3. Delete the wasp-agent cluster role binding
   ```bash
   oc delete clusterrolebinding wasp
   ```
4. Remove the `wasp` service account from privileged SCC
   ```bash
   oc adm policy remove-scc-from-user -n wasp privileged -z wasp
   ```
5. Remove the `wasp` project
   ```bash
   oc delete project wasp
   ```


## Additional notes
* [wasp-agent user-guide](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/virtualization/index#virt-configuring-higher-vm-workload-density)

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.



------------------------------


Original Filename:  GuestFilesystemAlmostOutOfSpace.md

# GuestFilesystemAlmostOutOfSpace

## Meaning

This alert triggers when a file system in a virtual machine (VM) is running out
of available disk space.

The alert has the following severity levels:

- **Warning**: Triggers when file-system usage is between 85% and 95% for 5
minutes.
- **Critical**: Triggers when file-system usage exceeds 95%.

The alert provides details about the specific file system (`disk_name`), its
mount point (`mount_point`), the VMI name, and namespace.

## Impact

When a guest file system runs out of space, the VM may experience:

- Application failures or crashes due to inability to write data
- System instability or inability to perform updates
- Potential data loss if applications cannot write to disk
- Degraded performance as the system struggles with low disk space
- The VM may become unresponsive or enter a failed state

Critical space exhaustion (>95%) significantly increases the risk of immediate
application or system failure.

## Diagnosis

1. Check the file-system usage metrics for the VMI:

   ```bash
   # Get the domain name of the VMI
   $ oc exec -it <pod-name> -n <namespace> -- virsh list
   ```

   ```bash
   # Query filesystem info via QEMU Guest Agent
   $ oc exec -it <pod-name> -n <namespace> -- virsh qemu-agent-command <domain-name> '{"execute": "guest-get-fsinfo"}'
   ```

2. You can also connect to the VMI by using the `virtctl` console to inspect
disk usage in the guest OS:

   ```bash
   $ virtctl console <vmi-name> -n <namespace>
   ```

   In the guest OS, run commands to evaluate file-system usage. For example, in
   Linux guests:

   ```bash
   $ df -h
   $ du -sh /* | sort -h
   ```

## Mitigation

### Immediate Actions

1. **Free up space in the guest file system**:

   - Remove temporary files, logs, or caches
   - Clean up old application data or archives
   - Remove unnecessary packages or applications

2. **Expand the disk size** if the underlying PVC supports volume expansion:

   a. Check if the storage class supports volume expansion:

      ```bash
      $ oc get storageclass <storage-class-name> -o yaml | grep allowVolumeExpansion
      ```

   b. Modify the PVC to request a larger size:

      ```bash
      $ oc edit pvc <pvc-name> -n <namespace>
      # Update the spec.resources.requests.storage value to a larger size
      ```

   c. Restart the VM to apply the changes:

      ```bash
      $ virtctl restart <vm-name> -n <namespace>
      ```

      This step causes the disk.img to be resized to match the new PVC size.
      While this is primarily needed for filesystem volumes, it's recommended
      to always restart for consistency.

### Long-term Solutions

1. **Set up log rotation and cleanup policies** within guest operating systems.

2. **Use appropriate volume sizes** when provisioning VMs based on expected
workload requirements.

3. **Consider using dynamic storage provisioning** with StorageClasses that
support volume expansion.

4. **Implement automated cleanup scripts** or maintenance tasks within VMs to
manage disk space proactively.

5. **Review and optimize application storage patterns** to minimize unnecessary
disk usage.

If the issue persists or the file system continues to fill up rapidly after
cleanup, investigate the root cause such as application bugs, excessive logging,
or unexpected data growth.

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  GuestVCPUQueueHighCritical.md

# GuestVCPUQueueHighCritical

## Meaning
A VirtualMachineInstance (VMI) reported a
**guest CPU run‑queue length greater than 20** runnable or
uninterruptible threads within the last scrape window (120s).
This indicates severe CPU contention.

## Impact
* Sustained backlog; high latency and throughput degradation are likely.
* Risk of timeouts, watchdog resets, or I/O amplification.

## Diagnosis

1. **Confirm queue length**
   ```promql
   kubevirt_vmi_guest_vcpu_queue{namespace="$NS",name="$VM"}
   ```
   The longer the queue is over 20, the more significant issues it might cause.

2. **Check host CPU usage**
   ```promql
   rate(kubevirt_vmi_cpu_usage_seconds_total{namespace="$NS",name="$VM"}[2m])
   ``
   If the CPU usage is more than 90%, migrate other VMs or
   mark the node as unschedulable, so that no new pods/VMs are placed on it.

3. **Inspect guest processes**
   `virtctl console <vm>` → `top -H` or `pidstat -u 1`

4. **Verify vCPU allocation**
   ```bash
   oc get vmi $VM -ojsonpath='{.spec.domain.cpu}'
   ```

## Mitigation

* **Immediately:** Live-migrate VM, hot-plug vCPUs, stop or throttle hot
threads.
* **Short term:** Raise vCPU limit or split workload across additional VMs.
* **Long term:** Adjust placement rules; add autoscaling tied to run-queue
length.

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  GuestVCPUQueueHighWarning.md

# GuestVCPUQueueHighWarning

## Meaning

Within the most recent scrape window (120 seconds), a VirtualMachineInstance
(VMI) reported a **guest CPU run‑queue length of more than 10** runnable or
uninterruptible threads. The run‑queue length is derived from
`guest_load_1m – vCPU_count`.

## Impact

* Moderate CPU contention inside the guest. Latency may spike but workload still
progresses.

* An early signal that the VM might need additional vCPUs or that a short‑lived
process is causing bursts.

## Diagnosis

1. **Confirm queue length**
   ```promql
   kubevirt_vmi_guest_vcpu_queue{namespace="$NS",name="$VM"}
   ```

2. **Check host CPU usage**
   ```promql
   rate(kubevirt_vmi_cpu_usage_seconds_total{namespace="$NS",name="$VM"}[2m])
   ```

3. **Inspect guest processes**
   `virtctl console <vm>` → `top -H` or `pidstat -u 1`

4. **Verify vCPU allocation**
   ```bash
   oc get vmi $VM -ojsonpath='{.spec.domain.cpu}'
   ```

## Mitigation

* **Immediately:** Consider live-migrating the VM to a node under a lighter
load,
or throttle demanding processes.
* **Short term:** Hot-plug or increase vCPU limit; tune application thread
pools.
* **Long term:** Implement horizontal scaling (HPA/KEDA, VMReplicaSet);
review placement rules.

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  HAControlPlaneDown.md

# HAControlPlaneDown

## Meaning

A control plane node has been detected as not ready for more than 5 minutes.

## Impact

When a control plane node is down, it affects the high availability and
redundancy of the OpenShift Container Platform control plane. This can
negatively impact:
- API server availability
- Controller manager operations
- Scheduler functionality
- etcd cluster health (if etcd is co-located)

## Diagnosis

1. Check the status of all control plane nodes:
   ```bash
   oc get nodes -l node-role.kubernetes.io/control-plane=''
   ```

2. Get detailed information about the affected node:
   ```bash
   oc describe node <node-name>
   ```

3. Review system logs on the affected node:
   ```bash
   ssh <node-address>
   ```

   ```bash
   journalctl -xeu kubelet
   ```

## Mitigation

1. Check node resources:
   - Verify CPU, memory, and disk usage
      ```bash
      # Check the node's CPU and memory resource usage
      oc top node <node-name>
      ```

      ```bash
      # Check node status conditions for DiskPressure status
      oc get node <node-name> -o yaml | jq '.status.conditions[] | select(.type == "DiskPressure")'
      ```
   - Clear disk space if necessary
   - Restart the kubelet if resource issues are resolved

2. If the node is unreachable:
   - Verify network connectivity
   - Check physical/virtual machine status
   - Ensure the node has power and is running

3. If the kubelet is generating errors:
   ```bash
   systemctl status kubelet
   ```

   ```bash
   systemctl restart kubelet
   ```

4. If the node cannot be recovered:
   - If possible, safely drain the node
      ```bash
      oc drain <node-name> --ignore-daemonsets --delete-emptydir-data
      ```
   - Investigate hardware/infrastructure issues
   - Consider replacing the node if necessary

## Additional notes
- Maintain at least three control plane nodes for high availability
- Monitor etcd cluster health if the affected node runs etcd
- Document any infrastructure-specific recovery procedures

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  HCOGoldenImageWithNoArchitectureAnnotation.md

# HCOGoldenImageWithNoArchitectureAnnotation

## Meaning

When running on a heterogeneous cluster, the DataImportCronTemplate objects
(DICTs; also known as golden images) in the hyperconverged cluster operator
(HCO) must be annotated with the `ssp.kubevirt.io/dict.architectures`
annotation. The value of this annotation is a list of architectures supported by
the image, which is defined in each DICT.

For pre-defined DICTs, this annotation is already set. For custom DICTs
(user-defined DICTs), this annotation must be set by the user in the
`HyperConverged` custom resource (CR).

For each DICT, if the `ssp.kubevirt.io/dict.architectures` annotation is
missing, HCO triggers the `HCOGoldenImageWithNoArchitectureAnnotation`
alert for this specific DICT.

> **Note:** This alert only triggers if the `enableMultiArchBootImageImport`
> feature gate is enabled in the `HyperConverged` CR.

## Impact

This alert triggers when the golden image created for this DICT does not have a
defined architecture. If this image is used as a boot image for a virtual
machine (VM), and the VM will is scheduled on a node with a CPU architecture
different than the image architecture, the VM fails to start.

## Diagnosis

1. Read the `HyperConverged` CR:

```bash
  # Get the namespace of the HyperConverged CR
  $ NAMESPACE="$(oc get hyperconverged -A --no-headers | awk '{print $1}')"

  # Read the HyperConverged CR
  $ oc get hyperconverged -n "${NAMESPACE}" -o yaml
```

2. If this command lists any DICT objects under the
`spec.dataImportCronTemplates` field in the `HyperConverged` CR, check whether
the `ssp.kubevirt.io/dict.architectures` annotation is set for each of them. If
the annotation is not set, then this alert is triggered.

   Below is an example for a HyperConverged CR with a valid DICT with the
  `ssp.kubevirt.io/dict.architectures` annotation set:
  ```yaml
  apiVersion: hco.kubevirt.io/v1beta1
  kind: HyperConverged
  ...
  spec:
  ...
    dataImportCronTemplates:
      - metadata:
          annotations:
            ...
            ssp.kubevirt.io/dict.architectures: amd64
          name: the-name-of-the-dict
        spec:
          ...
```

The `status.nodeInfo.workloadsArchitectures` field in the `HyperConverged` CR
shows the list of architectures that are supported by the cluster.

User-defined DICTs are defined in the `HyperConverged` CR, in the
`spec.dataImportCronTemplates` field.

## Mitigation

1. Check what architectures are supported by the image:

   ```bash
   $ podman manifest inspect your-registry/your-image:latest
   ```

   For details, see the
  [podman manifest inspect
documentation](https://docs.podman.io/en/latest/markdown/podman-manifest-inspect.1.html).

If the image is a multi-architecture manifest ("fat manifest"), it includes the
`manifests` field, which is a list of architectures supported by the image. If
the image is not a multi-architecture manifest, you need to find out what
is its architecture.

2. Edit the `HyperConverged` CR to add the missing
`ssp.kubevirt.io/dict.architectures` annotation.

  The format of the annotation is a comma-separated list of architectures,
  for example: `amd64,arm64,s390x`.

3. If the image does not support any of the architectures supported by the
cluster, rebuild the image for one or more of the architectures supported
by the cluster, or remove the DICT from the `HyperConverged` CR.

  For more information about building multi-architecture images, see the
  [podman
documentation](https://docs.podman.io/en/latest/markdown/podman-manifest-create.1.html).

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  HCOGoldenImageWithNoSupportedArchitecture.md

# HCOGoldenImageWithNoSupportedArchitecture

## Meaning

When running on a heterogeneous cluster, the DataImportCronTemplate objects
(DICTs; also known as golden images) in the hyperconverged cluster operator
(HCO) must be annotated with the `ssp.kubevirt.io/dict.architectures`
annotation. The value of this annotation is a list of architectures
supported by the image, which is defined in each DICT.

For pre-defined DICTs, this annotation is already set. For custom DICTs
(user-defined DICTs), this annotation must be set by the user in the
`HyperConverged` custom resource (CR).

For each DICT, if the annotation does not include any architecture that is
supported by the cluster (which means that there is no node in the cluster with
the architectures listed in the DICT annotation), HCO triggers the
`HCOGoldenImageWithNoSupportedArchitecture` alert for this specific DICT.

> **Note:** This only triggers if the `enableMultiArchBootImageImport`
> feature gate is enabled in the `HyperConverged` CR.

## Impact

This alert triggers when the DICT is not supported by any of the nodes in the
cluster. HCO will not populate the SSP CR with this DICT, and the golden image
will not be available for use in the cluster.

## Diagnosis

1. Read the HyperConverged CR:

```bash
  # Get the namespace of the HyperConverged CR
  $ NAMESPACE="$(oc get hyperconverged -A --no-headers | awk '{print $1}')"

  # Read the HyperConverged CR
  $ oc get hyperconverged -n "${NAMESPACE}" -o yaml
```

2. Examine the following fields in the `HyperConverged` CR status:

   - The `status.nodeInfo.workloadsArchitectures` shows a list of architectures
supported by the cluster.
   - The `status.dataImportCronTemplates` field shows the list of DICTs that are
managed by HCO.

3. Find the specific DICT object that is triggering this alert by its name, as
specified in the alert message.

4. Check the `ssp.kubevirt.io/dict.architectures` annotation of the DICT. Unlike
the annotation in the `spec` field, this annotation contains only architectures
that are supported by both the image and by the cluster.

   - If the annotation is empty, there is no architecture supported by the image
and by the cluster.

   - The DICT `status` field will include the `conditions` field, with the
`Deployed` condition set to `False`, and the `reason` field set to
`UnsupportedArchitectures`. For DICTs with supported architectures, the `status`
field will not contain the `conditions` field.

   - The `status.workloadsArchitectures` field of the DICT shows the list of
architectures supported by the image, which was set in the
`ssp.kubevirt.io/dict.architectures` annotation in the source DICT.

### Example

```yaml
apiVersion: hco.kubevirt.io/v1beta1
kind: HyperConverged
...
status:
  ...
  dataImportCronTemplates:
    - metadata:
        annotations:
          ssp.kubevirt.io/dict.architectures: ""
        name: my-image
      spec:
          ...
      status:
        conditions:
          - message: DataImportCronTemplate has no supported architectures for the current
              cluster
            reason: UnsupportedArchitectures
            status: "False"
            type: Deployed
        originalSupportedArchitectures: someUnsupportedArch,otherUnsupportedArch
```

## Mitigation

The steps to mitigate this issue vary based on whether you are using pre-defined
DICTs or user-defined DICTs.

### Pre-defined DataImportCronTemplates

Pre-defined DICTs are not defined in the `spec.dataImportCronTemplates`
field in the `HyperConverged` CR. Instead, they are defined internally in the
HCO application.

All pre-defined DICTs are annotated with the `ssp.kubevirt.io/dict.architectures`
annotation, and all of them support the `amd64`, `arm64`, and `s390x`
architectures. If the cluster does not support any of these architectures,
you cannot use pre-defined DICTs in the cluster.

To mitigate the `HCOGoldenImageWithNoSupportedArchitecture` issue on pre-defined
DICTs, you can do one of the following:

- Add supported nodes to the cluster

- Disable the pre-defined DICTs in the `HyperConverged` CR to turn this alert
off:

  1. Find the DICT(s) that you want to disable in the
  `status.dataImportCronTemplates` field of the `HyperConverged` CR, as
  described [in the Diagnosis section](#diagnosis).

  2. Add the DICT to the `spec.dataImportCronTemplates` field in the
  `HyperConverged` CR. Add the `dataimportcrontemplate.kubevirt.io/enable`
  annotation with the value `false` to the DICT. Only the DICT name and the
  annotation are required.

       For example, to disable the `centos-stream10-image-cron` DICT:
       ```yaml
       apiVersion: hco.kubevirt.io/v1beta1
       kind: HyperConverged
       metadata:
         name: kubevirt-hyperconverged
       spec:
         dataImportCronTemplates:
         - metadata:
             name: centos-stream10-image-cron
             annotations:
               dataimportcrontemplate.kubevirt.io/enable: 'false'
        ```

     If you have a self-built image that is supported by the nodes in the
cluster,
you can modify the pre-defined DICT to use your image. To do so, add the DICT to
the `spec.dataImportCronTemplates` field in the `HyperConverged` CR and modify
its `spec.source.registry` field.

  > Tip: you can find the pre-defined DICTs in the
  > `status.dataImportCronTemplates` field of the `HyperConverged` CR, as
  > described [in the Diagnosis section](#diagnosis). Afterwards, you can copy
  > the DICT from the field, and modify it in the `spec.dataImportCronTemplates`
  > field.

3. Set the `ssp.kubevirt.io/dict.architectures` annotation to include all the
architectures supported by your image.

   For example:
  ```yaml
  apiVersion: hco.kubevirt.io/v1beta1
  kind: HyperConverged
  metadata:
    name: kubevirt-hyperconverged
  spec:
    dataImportCronTemplates:
    - metadata:
      annotations:
        cdi.kubevirt.io/storage.bind.immediate.requested: "true"
        ssp.kubevirt.io/dict.architectures: arch1,arch2
      name: centos-stream10-image-cron
    spec:
      garbageCollect: Outdated
      managedDataSource: centos-stream10
      schedule: "0 */12 * * *"
      template:
        spec:
          source:
            registry:
              url: docker://your-registry/your-image:latest
          storage:
            resources:
              requests:
                storage: 10Gi
  ```

### User-defined DataImportCronTemplates

User-defined DICTs are defined in the `spec.dataImportCronTemplates` field of
the of the HyperConverged CR.

1. Check what architectures are supported by the image:

   ```bash
   $ podman manifest inspect your-registry/your-image:latest
   ```

   For details, see the [podman manifest inspect
documentation](https://docs.podman.io/en/latest/markdown/podman-manifest-inspect.1.html).

   If the image is a multi-architecture manifest ("fat manifest"), it includes
the
`manifests` field, which is a list of architectures supported by the image. If
the image is not a multi-architecture manifest, you need to find out what is its
architecture.

2. Check that the `ssp.kubevirt.io/dict.architectures` annotation is set with
the correct value. If not, edit the `HyperConverged` CR to fix the annotation.
The format of the annotation is a comma-separated list of architectures, for
example: `amd64,arm64,s390x`.

3. If the image does not support any of the architectures supported by the
cluster, rebuild the image for one or more of the architectures supported by the
cluster, or remove the DICT from the `HyperConverged` CR.

It is also possible to disable the DICT, by adding it
the `dataimportcrontemplate.kubevirt.io/enable` annotation, with the value
of `false`. For example:

  ```yaml
  apiVersion: hco.kubevirt.io/v1beta1
  kind: HyperConverged
  metadata:
    name: kubevirt-hyperconverged
  spec:
    dataImportCronTemplates:
    - metadata:
      annotations:
        dataimportcrontemplate.kubevirt.io/enable: "false"
        ssp.kubevirt.io/dict.architectures: unsupported-arch1,unsupported-arch2
      name: my-image
    spec:
      ...
  ```

For more information about building multi-architecture images, see the
[podman documentation](https://docs.podman.io/en/latest/markdown/podman-manifest-create.1.html).

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  HCOInstallationIncomplete.md

# HCOInstallationIncomplete

## Meaning
This alert fires when the HyperConverged Cluster Operator (HCO) runs for more
than an hour without a `HyperConverged` custom resource (CR).

This alert has the following causes:

- During the installation process, you installed the HCO but you did not create
the `HyperConverged` CR.
- During the uninstall process, you removed the `HyperConverged` CR before
uninstalling the HCO and the HCO is still running.

## Mitigation

The mitigation depends on whether you are installing or uninstalling
the HCO:

- Complete the installation by creating a `HyperConverged` CR with its
default values:

  ```bash
  $ cat <<EOF | oc apply -f -
  apiVersion: hco.kubevirt.io/v1beta1
  kind: HyperConverged
  metadata:
    name: kubevirt-hyperconverged
    namespace: openshift-cnv
  spec: {}
  EOF
  ```

- Uninstall the HCO. If the uninstall process continues to run, you must
resolve that issue in order to cancel the alert.


------------------------------


Original Filename:  HCOMisconfiguredDescheduler.md

# HCOMisconfiguredDescheduler

## Meaning

A descheduler is a OpenShift Container Platform application that causes the
control plane to
re-arrange the workloads in a better way.

The descheduler uses the OpenShift Container Platform eviction API to evict
pods, and receives
feedback from `kube-api` on whether the eviction request was granted.
In contrast, to keep a VM live and trigger a live migration,
OpenShift Virtualization handles eviction requests in a custom manner,
and a live migration takes time to perform.

Therefore, when a `virt-launcher` pod is migrating to another node in the
background,
the descheduler detects this as a pod that failed to be evicted. As a
consequence,
the manner in which OpenShift Virtualization handles eviction requests causes
the descheduler
to make incorrect decisions and take incorrect actions that might
destabilize the cluster.

To correctly handle the special case of an evicted VM pod triggering a live
migration to another node, the `Kube Descheduler Operator` introduced
a `profileCustomizations` named `devEnableEvictionsInBackground`.
This is currently considered an `alpha` feature for
on `Kube Descheduler Operator`.

## Impact

Using the descheduler operator for KubeVirt VMs without the
`devEnableEvictionsInBackground` profile customization might lead
to unstable or unpredictable behavior, which negatively impacts cluster
stability.

## Diagnosis

1. Check the CR for `Kube Descheduler Operator`:

   ```bash
   $ oc get -n openshift-kube-descheduler-operator KubeDescheduler cluster -o yaml
   ```

2. Search for the following lines in the CR:

   ```yaml
   spec:
      profileCustomizations:
         devEnableEvictionsInBackground: true
   ```

If these lines are not present, the `Kube Descheduler Operator` is not correctly
configured to work alongside OpenShift Virtualization.

## Mitigation

Do one of the following:

* Add the following lines to the CR for `Kube Descheduler Operator`:
   ```yaml
   spec:
      profileCustomizations:
         devEnableEvictionsInBackground: true
   ```

* Remove the `Kube Descheduler Operator`.

Note that `EvictionsInBackground` is an alpha feature,
and as such, it is provided as an experimental feature
and is subject to change.

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  HCOMultiArchGoldenImagesDisabled.md

# HCOMultiArchGoldenImagesDisabled

## Meaning

DataImportCron objects (DIC; also known as golden images) are used to create
boot images for virtual machines (VMs). The images are preloaded in the cluster,
and then they are used to create VM boot disks with a specific operating system.
By default, the preloaded images use the architecture of the cluster node that
was used to create the image.

If the `enableMultiArchBootImageImport` feature gate is enabled in the
HyperConverged custom resource (CR), multiple preloaded images are created for
each DataImportCronTemplate (DICT), one for each architecture supported by the
cluster and by the original image.

This allows the VMs to be scheduled on nodes with the same architecture as the
preloaded image.

This alert is triggered when running on a heterogeneous cluster (a cluster with
nodes of different architectures) while the `enableMultiArchBootImageImport`
feature gate is disabled in the HyperConverged CR.

## Impact

When running on a heterogeneous cluster, the preloaded image may use a different
architecture than the architecture of the node that the VM is scheduled on.

In this case, the VM will fail to start, as the image architecture is not
compatible with the node architecture.

## Diagnosis

HCO checks the workload node architectures in the cluster. By default, HCO
considers the worker nodes as the workload nodes. If the
`spec.workloads.nodePlacement` field in the HyperConverged CR is populated,
HCO considers the nodes that match the node selector in this field as the
workload nodes.

HCO publishes the list of the workload node architectures in the
`status.nodeInfo.workloadsArchitectures` field in the HyperConverged CR.

Read the HyperConverged CR:

```bash
oc get hyperconverged -n openshift-cnv kubevirt-hyperconverged -o yaml
```

The result will look similar to this:

```yaml
apiVersion: hco.kubevirt.io/v1beta1
kind: HyperConverged
spec:
  ...
  workloads: # check if the spec.workloads.nodePlacement field is populated
    nodePlacement:
  ...
status:
  ...
  nodeInfo:
    workloadsArchitectures:
      - amd64
      - arm64
...
```

## Mitigation

To address this issue, you can either enable the multi-arch boot image feature,
or modify the workloads node placement in the HyperConverged CR to include only
nodes with a single architecture.

### Enable the multi-arch boot image feature

The multi-arch boot image feature is in the alpha stage, and it is not enabled
by default. Enabling this feature will result in the creation of multiple
preloaded images for each DataImportCronTemplate (DICT), one for each
architecture supported by the cluster, and by the original image. However, this
feature is not generally available, and it is not fully supported.

To enable the multi-arch boot image feature, set the
`enableMultiArchBootImageImport` feature gate in the HyperConverged CR to `true`

If the HyperConverged CR contains the `spec.dataImportCronTemplates` field,
and this field is not empty, then you may need to add the
`ssp.kubevirt.io/dict.architectures` annotation to each DICT object in this
field. See
the
[HCOGoldenImageWithNoArchitectureAnnotation](HCOGoldenImageWithNoArchitectureAnnotation.md)
runbook for more details.

Edit the HyperConverged CR:

```bash
oc edit hyperconverged -n openshift-cnv kubevirt-hyperconverged -o yaml
```

The editor will be opened with the HyperConverged CR in YAML format.

Edit the CR to set the `enableMultiArchBootImageImport` feature gate to `true`,
and to add the `ssp.kubevirt.io/dict.architectures` annotation to each DICT
object in the `spec.dataImportCronTemplates` field, if needed.

```yaml
apiVersion: hco.kubevirt.io/v1beta1
kind: HyperConverged
spec:
  dataImportCronTemplates:
    ...
  ...
  featureGates:
    ...
    enableMultiArchBootImageImport: true
    ...
```

Save the changes and exit the editor.

### Modify the Workloads Node Placement

If you do not want to enable the multi arch boot image feature, you can modify
the workloads node placement in the HyperConverged CR to include only nodes with
a single architecture.

Edit the HyperConverged CR:
```bash
oc edit hyperconverged -n openshift-cnv kubevirt-hyperconverged -o yaml
```

The editor will be opened with the HyperConverged CR in YAML format.

Below is an example of how to modify the workloads node placement to include
only nodes with the `amd64` architecture, using node affinity:

```yaml
apiVersion: hco.kubevirt.io/v1beta1
kind: HyperConverged
spec:
  ...
  workloads:
    nodePlacement:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: kubernetes.io/arch
                    operator: In
                    values:
                      - amd64
  ...
```

Save the changes and exit the editor.

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  HCOOperatorConditionsUnhealthy.md

# HCOOperatorConditionsUnhealthy

## Meaning

This alert triggers when the HCO operator conditions or its secondary resources
are in an error or warning state.

## Impact

Resources maintained by the operator might not be functioning correctly.

## Diagnosis

Check the operator conditions:

```bash
oc get HyperConverged kubevirt-hyperconverged -n openshift-cnv -o jsonpath='{.status.conditions}'
```

## Mitigation

Based on the information obtained during the diagnosis procedure, try to
identify the root cause within the operator or any of its secondary resources,
and resolve the issue.

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  HPPNotReady.md

# HPPNotReady

## Meaning

This alert fires when a hostpath provisioner (HPP) installation is in a degraded
state.

The HPP dynamically provisions hostpath volumes to provide storage for
persistent volume claims (PVCs).

## Impact

HPP is not usable. Its components are not ready and they are not progressing
towards a ready state.

## Diagnosis

1. Set the `HPP_NAMESPACE` environment variable:

   ```bash
   $ export HPP_NAMESPACE="$(oc get deployment -A | grep hostpath-provisioner-operator | awk '{print $1}')"
   ```

2. Check for HPP components that are currently not ready:

   ```bash
   $ oc -n $HPP_NAMESPACE get all -l k8s-app=hostpath-provisioner
   ```

3. Obtain the details of the failing pod:

   ```bash
   $ oc -n $HPP_NAMESPACE describe pods <pod>
   ```

4. Check the logs of the failing pod:

   ```bash
   $ oc -n $HPP_NAMESPACE logs <pod>
   ```

## Mitigation

Based on the information obtained during the diagnosis procedure, try to
identify the root cause and resolve the issue.

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  HPPOperatorDown.md

# HPPOperatorDown

## Meaning

This alert fires when the hostpath provisioner (HPP) Operator is down.

The HPP Operator deploys and manages the HPP infrastructure components, such as
the daemon set that provisions hostpath volumes.

## Impact

The HPP components might fail to deploy or to remain in the required state. As a
result, the HPP installation might not work correctly in the cluster.

## Diagnosis

1. Configure the `HPP_NAMESPACE` environment variable:

   ```bash
   $ HPP_NAMESPACE="$(oc get deployment -A | grep hostpath-provisioner-operator | awk '{print $1}')"
   ```

2. Check whether the `hostpath-provisioner-operator` pod is currently running:

   ```bash
   $ oc -n $HPP_NAMESPACE get pods -l name=hostpath-provisioner-operator
   ```

3. Obtain the details of the `hostpath-provisioner-operator` pod:

   ```bash
   $ oc -n $HPP_NAMESPACE describe pods -l name=hostpath-provisioner-operator
   ```

4. Check the log of the `hostpath-provisioner-operator` pod for errors:

   ```bash
   $ oc -n $HPP_NAMESPACE logs -l name=hostpath-provisioner-operator
   ```

## Mitigation

Based on the information obtained during the diagnosis procedure, try to
identify the root cause and resolve the issue.

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  HPPSharingPoolPathWithOS.md

# HPPSharingPoolPathWithOS

## Meaning

This alert fires when the hostpath provisioner (HPP) shares a file system with
other critical components, such as `kubelet` or the operating system (OS).

HPP dynamically provisions hostpath volumes to provide storage for persistent
volume claims (PVCs).

## Impact

A shared hostpath pool puts pressure on the node's disks. The node might have
degraded performance and stability.

## Diagnosis

1. Configure the `HPP_NAMESPACE` environment variable:

   ```bash
   $ export HPP_NAMESPACE="$(oc get deployment -A | grep hostpath-provisioner-operator | awk '{print $1}')"
   ```

2. Obtain the status of the `hostpath-provisioner-csi` daemon set pods:

   ```bash
   $ oc -n $HPP_NAMESPACE get pods | grep hostpath-provisioner-csi
   ```

3. Check the `hostpath-provisioner-csi` logs to identify the shared pool and
path:

   ```bash
   $ oc -n $HPP_NAMESPACE logs <csi_daemonset> -c hostpath-provisioner
   ```

   Example output:

   ```text
   I0208 15:21:03.769731       1 utils.go:221] pool (<legacy, csi-data-dir>/csi), shares path with OS which can lead to node disk pressure
   ```

## Mitigation

Using the data obtained in the Diagnosis section, try to prevent the pool path
from being shared with the OS. The specific steps vary based on the node and
other circumstances.

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  HighCPUWorkload.md

# HighCPUWorkload

## Meaning

This alert fires when a node's CPU utilization exceeds 90% for more than 5
minutes.

## Impact

High CPU utilization can lead to:
- Degraded performance of applications running on the node
- Increased latency in request processing
- Potential service disruptions if CPU usage continues to climb

## Diagnosis

1. Identify the affected node:
   ```bash
   oc get nodes
   ```

2. Check the node's resource usage:
   ```bash
   oc describe node <node-name>
   ```

3. List pods that consume high amounts of CPU:
   ```bash
   oc top pods --all-namespaces --sort-by=cpu
   ```

4. Investigate specific pod details if needed:
   ```bash
   oc describe pod <pod-name> -n <namespace>
   ```

## Mitigation

1. If the issue was caused by a malfunctioning pod:
   - Consider restarting the pod
   - Check pod logs for anomalies
   - Review pod resource limits and requests

2. If the issue is system-wide:
   - Check for system processes that consume high amounts of CPU
   - Consider cordoning the node and migrating workloads
   - Evaluate if node scaling is needed

3. Long-term solutions to avoid the issue:
   - Implement or adjust pod resource limits
   - Consider horizontal pod autoscaling
   - Evaluate cluster capacity and scaling needs

## Additional notes
- Monitor the node after mitigation to ensure CPU usage returns to normal
- Review application logs for potential root causes
- Consider updating resource requests/limits if this is a recurring issue

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  HighNodeCPUFrequency.md

# HighNodeCPUFrequency

## Meaning

This alert triggers when a CPU frequency on a node exceeds 80% of the maximum
frequency for more than 5 minutes.

## Impact

High CPU frequency can indicate:
- High CPU utilization pushing the processor to higher frequencies
- Potential thermal issues causing frequency scaling
- Power management concerns affecting system stability
- Reduced CPU lifespan due to sustained high-frequency operation

## Diagnosis

1. Identify the affected node and CPU:
   ```bash
   oc get nodes
   ```

2. Check current CPU frequency on the node:
   ```bash
   oc debug node/<node-name> -it --image=registry.redhat.io/ubi8/ubi
   ```

   Then run inside the debug pod:
   ```bash
   cat /proc/cpuinfo | grep -i "cpu mhz"
   ```

3. Monitor CPU utilization and temperature:
   ```bash
   oc top nodes
   ```

   ```bash
   oc top pods --all-namespaces --sort-by=cpu
   ```

   Check system temperature (if available):
   ```bash
   sensors
   ```

4. Review node resource allocation:
   ```bash
   oc describe node <node-name>
   ```

5. Check for CPU-intensive workloads:
   ```bash
   ps aux --sort=-%cpu | head -20
   ```

## Mitigation

1. Immediate actions:
   - Monitor the CPU temperature to ensure it is within safe limits.
   - Check if the high frequency is due to legitimate high CPU demand.
   - Verify CPU settings if needed.

2. If caused by high CPU utilization:
   - Identify and analyze CPU-intensive pods.
   - Consider redistributing workloads across nodes.
   - Evaluate pod resource limits and requests.
   - Scale horizontally if needed.

3. If thermal throttling is suspected:
   - Check system cooling and ventilation.
   - Monitor ambient temperature.
   - Consider reducing workload temporarily.
   - Verify proper thermal management settings.

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  KubeMacPoolDuplicateMacsFound.md

# KubeMacPoolDuplicateMacsFound

## Meaning

This alert fires when `KubeMacPool` detects duplicate MAC addresses.

`KubeMacPool` is responsible for allocating MAC addresses and preventing MAC
address conflicts. When `KubeMacPool` starts, it scans the cluster for the MAC
addresses of virtual machines (VMs) in managed namespaces.

## Impact

Duplicate MAC addresses on the same LAN might cause network issues.

## Diagnosis

1. Obtain the namespace and the name of the `kubemacpool-mac-controller` pod:

   ```bash
   $ oc get pod -A -l control-plane=mac-controller-manager --no-headers \
     -o custom-columns=":metadata.namespace,:metadata.name"
   ```
2. Obtain the duplicate MAC addresses from the `kubemacpool-mac-controller`
logs:

   ```bash
   $ oc logs -n <namespace> <kubemacpool_mac_controller> | grep "already allocated"
   ```

   Example output:

   ```text
   mac address 02:00:ff:ff:ff:ff already allocated to vm/kubemacpool-test/testvm, br1,
   conflict with: vm/kubemacpool-test/testvm2, br1
   ```

## Mitigation

1. Update the VMs to remove the duplicate MAC addresses.
2. Restart the `kubemacpool-mac-controller` pod:

   ```bash
   $ oc delete pod -n <namespace> <kubemacpool_mac_controller>
   ```


------------------------------


Original Filename:  KubeVirtCRModified.md

# KubeVirtCRModified

## Meaning

This alert fires when an operand of the HyperConverged Cluster Operator (HCO) is
changed by someone or something other than HCO.

HCO configures OpenShift Virtualization and its supporting operators in an
opinionated way and
overwrites its operands when there is an unexpected change to them. Users must
not modify the operands directly. The `HyperConverged` custom resource is the
source of truth for the configuration.

## Impact

Changing the operands manually causes the cluster configuration to fluctuate and
might lead to instability.

## Diagnosis

- Check the `component_name` value in the alert details to determine the operand
  kind (`kubevirt`) and the operand name (`kubevirt-kubevirt-hyperconverged`)
  that are being changed:

  ```text
  Labels
    alertname=KubeVirtCRModified
    component_name=kubevirt/kubevirt-kubevirt-hyperconverged
    severity=warning
  ```

## Mitigation

Do not change the HCO operands directly. Use `HyperConverged` objects to
configure the cluster.

The alert resolves itself after 10 minutes if the operands are not changed
manually.


------------------------------


Original Filename:  KubeVirtComponentExceedsRequestedCPU.md

# KubeVirtComponentExceedsRequestedCPU [Deprecated]

This alert is deprecated. You can safely ignore or silence it.



------------------------------


Original Filename:  KubeVirtComponentExceedsRequestedMemory.md

# KubeVirtComponentExceedsRequestedMemory [Deprecated]

This alert is deprecated. You can safely ignore or silence it.



------------------------------


Original Filename:  KubeVirtDeprecatedAPIRequested.md

# KubeVirtDeprecatedAPIRequested

## Meaning

This alert fires when a deprecated `KubeVirt` API is used.

## Impact

Using a deprecated API is not recommended because the request will
fail when the API is removed in a future release.

## Diagnosis

- Check the __Description__ and __Summary__ sections of the alert to identify
the
  deprecated API as in the following example:

  __Description__

  `Detected requests to the deprecated virtualmachines.kubevirt.io/v1alpha3 API.`

  __Summary__

  `2 requests were detected in the last 10 minutes.`

## Mitigation

Use fully supported APIs. The alert resolves itself after 10 minutes if the
deprecated API is not used.


------------------------------


Original Filename:  KubeVirtNoAvailableNodesToRunVMs.md

# KubeVirtNoAvailableNodesToRunVMs

## Meaning

The `KubeVirtNoAvailableNodesToRunVMs` alert is triggered when all nodes in the
OpenShift Container Platform cluster are missing hardware virtualization or CPU
virtualization
extensions. This means that the cluster does not have the necessary hardware
support to run virtual machines (VMs).

## Impact

If this alert is triggered, it means that VMs will not be able to run on the
cluster. This can have a significant impact on the operations of the cluster, as
VMs may be used for critical applications or services.

## Diagnosis

To diagnose the cause of this alert, the following steps can be taken:

1. Check the hardware configuration of the nodes in the cluster. Make sure that
all nodes have hardware virtualization or CPU virtualization extensions
enabled.

2. Check the node labels in the cluster. Make sure that nodes with the necessary
hardware support are labeled as such, so that VMs can be scheduled to run on
these nodes.

## Mitigation

To mitigate the impact of this alert, add nodes to the cluster that have
hardware virtualization or CPU virtualization extensions enabled.

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  KubeVirtVMIExcessiveMigrations.md

# KubeVirtVMIExcessiveMigrations

## Meaning

This alert fires when a virtual machine instance (VMI) live migrates more than
12 times over a period of 24 hours.

This migration rate is abnormally high, even during an upgrade. This alert might
indicate a problem in the cluster infrastructure, such as network disruptions or
insufficient resources.

## Impact

A virtual machine (VM) that migrates too frequently might experience degraded
performance because memory page faults occur during the transition.

## Diagnosis

1. Verify that the worker node has sufficient resources:

   ```bash
   $ oc get nodes -l node-role.kubernetes.io/worker= -o json | jq .items[].status.allocatable
   ```

   Example output:

   ```json
   {
     "cpu": "3500m",
     "devices.kubevirt.io/kvm": "1k",
     "devices.kubevirt.io/sev": "0",
     "devices.kubevirt.io/tun": "1k",
     "devices.kubevirt.io/vhost-net": "1k",
     "ephemeral-storage": "38161122446",
     "hugepages-1Gi": "0",
     "hugepages-2Mi": "0",
     "memory": "7000128Ki",
     "pods": "250"
   }
   ```

2. Check the status of the worker node:

   ```bash
   $ oc get nodes -l node-role.kubernetes.io/worker= -o json | jq .items[].status.conditions
   ```

   Example output:

   ```json
   {
     "lastHeartbeatTime": "2022-05-26T07:36:01Z",
     "lastTransitionTime": "2022-05-23T08:12:02Z",
     "message": "kubelet has sufficient memory available",
     "reason": "KubeletHasSufficientMemory",
     "status": "False",
     "type": "MemoryPressure"
   },
   {
     "lastHeartbeatTime": "2022-05-26T07:36:01Z",
     "lastTransitionTime": "2022-05-23T08:12:02Z",
     "message": "kubelet has no disk pressure",
     "reason": "KubeletHasNoDiskPressure",
     "status": "False",
     "type": "DiskPressure"
   },
   {
     "lastHeartbeatTime": "2022-05-26T07:36:01Z",
     "lastTransitionTime": "2022-05-23T08:12:02Z",
     "message": "kubelet has sufficient PID available",
     "reason": "KubeletHasSufficientPID",
     "status": "False",
     "type": "PIDPressure"
   },
   {
     "lastHeartbeatTime": "2022-05-26T07:36:01Z",
     "lastTransitionTime": "2022-05-23T08:24:15Z",
     "message": "kubelet is posting ready status",
     "reason": "KubeletReady",
     "status": "True",
     "type": "Ready"
   }
   ```

3. Log in to the worker node and verify that the `kubelet` service is running:

   ```bash
   $ systemctl status kubelet
   ```

4. Check the `kubelet` journal log for error messages:

   ```bash
   $ journalctl -r -u kubelet
   ```

## Mitigation

Ensure that the worker nodes have sufficient resources (CPU, memory, disk) to
run VM workloads without interruption.

If the problem persists, try to identify the root cause and resolve the issue.

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  KubemacpoolDown.md

# KubemacpoolDown

## Meaning

`KubeMacPool` is down. `KubeMacPool` is responsible for allocating MAC addresses
and preventing MAC address conflicts.

## Impact

If `KubeMacPool` is down, `VirtualMachine` objects cannot be created.

## Diagnosis

1. Set the `KMP_NAMESPACE` environment variable:

   ```bash
   $ export KMP_NAMESPACE="$(oc get pod -A --no-headers -l \
      control-plane=mac-controller-manager | awk '{print $1}')"
   ```

2. Set the `KMP_NAME` environment variable:

   ```bash
   $ export KMP_NAME="$(oc get pod -A --no-headers -l \
      control-plane=mac-controller-manager | awk '{print $2}')"
   ```

3. Obtain the `KubeMacPool-manager` pod details:

   ```bash
   $ oc describe pod -n $KMP_NAMESPACE $KMP_NAME
   ```

4. Check the `KubeMacPool-manager` logs for error messages:

   ```bash
   $ oc logs -n $KMP_NAMESPACE $KMP_NAME
   ```

## Mitigation

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  KubevirtVmHighMemoryUsage.md

# KubevirtVmHighMemoryUsage

## Meaning

This alert fires when a container hosting a virtual machine (VM) has less than
20 MB free memory.

## Impact

The virtual machine running inside the container is terminated by the runtime
if the container's memory limit is exceeded.

## Diagnosis

1. Obtain the `virt-launcher` pod details:

   ```bash
   $ oc get pod <virt-launcher> -o yaml
   ```

2. Identify `compute` container processes with high memory usage in the
`virt-launcher` pod:

   ```bash
   $ oc exec -it <virt-launcher> -c compute -- top
   ```

## Mitigation

- Increase the memory limit in the `VirtualMachine` specification as in the
following example:

   ```yaml
   spec:
     running: false
     template:
       metadata:
         labels:
           kubevirt.io/vm: vm-name
       spec:
         domain:
           resources:
             limits:
               memory: 200Mi
             requests:
               memory: 128Mi
   ```


------------------------------


Original Filename:  LowKVMNodesCount.md

# LowKVMNodesCount

## Meaning

This alert fires when fewer than two nodes in the cluster have KVM resources.

## Impact

The cluster must have at least two nodes with KVM resources for live migration.

Virtual machines cannot be scheduled or run if no nodes have KVM resources.

## Diagnosis

- Identify the nodes with KVM resources:

  ```bash
  $ oc get nodes -o jsonpath='{.items[*].status.allocatable}' | grep devices.kubevirt.io/kvm
  ```

## Mitigation

Install KVM on the nodes without KVM resources.


------------------------------


Original Filename:  LowReadyVirtControllersCount.md

# LowReadyVirtControllersCount

## Meaning

This alert fires when one or more `virt-controller` pods are running, but none
of these pods has been in the `Ready` state for the last 5 minutes.

A `virt-controller` device monitors the custom resource definitions (CRDs) of a
virtual machine instance (VMI) and manages the associated pods. The device
create pods for VMIs and manages the lifecycle of the pods. The device is
critical for cluster-wide virtualization functionality.

## Impact

This alert indicates that a cluster-level failure might occur, which would cause
actions related to VM lifecycle management to fail. This notably includes
launching a new VMI or shutting down an existing VMI.

## Diagnosis

1. Set the `NAMESPACE` environment variable:

   ```bash
   $ export NAMESPACE="$(oc get kubevirt -A -o custom-columns="":.metadata.namespace)"
   ```

2. Verify a `virt-controller` device is available:

   ```bash
   $ oc get deployment -n $NAMESPACE virt-controller -o jsonpath='{.status.readyReplicas}'
   ```

3. Check the status of the `virt-controller` deployment:

   ```bash
   $ oc -n $NAMESPACE get deploy virt-controller -o yaml
   ```

4. Obtain the details of the `virt-controller` deployment to check for status
conditions, such as crashing pods or failures to pull images:

   ```bash
   $ oc -n $NAMESPACE describe deploy virt-controller
   ```

5. Check if any problems occurred with the nodes. For example, they might be in
a `NotReady` state:

   ```bash
   $ oc get nodes
   ```

## Mitigation

This alert can have multiple causes, including the following:

- The cluster has insufficient memory.
- The nodes are down.
- The API server is overloaded. For example, the scheduler might be under a
heavy load and therefore not completely available.
- There are network issues.

Try to identify the root cause and resolve the issue.

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  LowReadyVirtOperatorsCount.md

# LowReadyVirtOperatorsCount

## Meaning

This alert fires when one or more `virt-operator` pods are running, but none of
these pods has been in a `Ready` state for the last 10 minutes.

The `virt-operator` is the first Operator to start in a cluster. The
`virt-operator` deployment has a default replica of two `virt-operator` pods.

Its primary responsibilities include the following:

- Installing, live-updating, and live-upgrading a cluster
- Monitoring the lifecycle of top-level controllers, such as `virt-controller`,
`virt-handler`, `virt-launcher`, and managing their reconciliation
- Certain cluster-wide tasks, such as certificate rotation and infrastructure
management

## Impact

A cluster-level failure might occur. Critical cluster-wide management
functionalities, such as certification rotation, upgrade, and reconciliation of
controllers, might become unavailable. Such a state also triggers the
`NoReadyVirtOperator` alert.

The `virt-operator` is not directly responsible for virtual machines (VMs) in
the cluster. Therefore, its temporary unavailability does not significantly
affect VM workloads.

## Diagnosis

1. Set the `NAMESPACE` environment variable:

   ```bash
   $ export NAMESPACE="$(oc get kubevirt -A -o custom-columns="":.metadata.namespace)"
   ```

2. Obtain the name of the `virt-operator` deployment:

   ```bash
   $ oc -n $NAMESPACE get deploy virt-operator -o yaml
   ```

3. Obtain the details of the `virt-operator` deployment:

   ```bash
   $ oc -n $NAMESPACE describe deploy virt-operator
   ```

4. Check for node issues, such as a `NotReady` state:

   ```bash
   $ oc get nodes
   ```

## Mitigation

Based on the information obtained during the diagnosis procedure, try to
identify the root cause and resolve the issue.

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  LowVirtAPICount.md

# LowVirtAPICount

## Meaning

This alert fires when only one available `virt-api` pod is detected during a
60-minute period, although at least two nodes are available for scheduling.

## Impact

An API call outage might occur during node eviction because the `virt-api` pod
becomes a single point of failure.

## Diagnosis

1. Set the `NAMESPACE` environment variable:

   ```bash
   $ export NAMESPACE="$(oc get kubevirt -A -o custom-columns="":.metadata.namespace)"
   ```

2. Check the number of available `virt-api` pods:

   ```bash
   $ oc get deployment -n $NAMESPACE virt-api -o jsonpath='{.status.readyReplicas}'
   ```

3. Check the status of the `virt-api` deployment for error conditions:

   ```bash
   $ oc -n $NAMESPACE get deploy virt-api -o yaml
   ```

4. Check the nodes for issues such as nodes in a `NotReady` state:

   ```bash
   $ oc get nodes
   ```

## Mitigation

Try to identify the root cause and to resolve the issue.

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  LowVirtControllersCount.md

# LowVirtControllersCount

## Meaning

This alert fires when a low number of `virt-controller` pods is detected. At
least one `virt-controller` pod must be available in order to ensure high
availability. The default number of replicas is 2.

A `virt-controller` device monitors the custom resource definitions (CRDs) of a
virtual machine instance (VMI) and manages the associated pods. The device
create pods for VMIs and manages the lifecycle of the pods. The device is
critical for cluster-wide virtualization functionality.

## Impact

The responsiveness of OpenShift Virtualization might become negatively
affected. For example,
certain requests might be missed.

In addition, if another `virt-controller` instance terminates unexpectedly,
OpenShift Virtualization might become completely unresponsive.

## Diagnosis

1. Verify that running `virt-controller` pods are available:

   ```bash
   $ oc -n openshift-cnv get pods -l kubevirt.io=virt-controller
   ```

2. Check the `virt-controller` logs for error messages:

   ```bash
   $ oc -n openshift-cnv logs <virt-controller>
   ```

3. Obtain the details of the `virt-controller` pod to check for status
conditions such as unexpected termination or a `NotReady` state.

   ```bash
   $ oc -n openshift-cnv describe pod/<virt-controller>
   ```

## Mitigation

This alert can have a variety of causes, including:

- Not enough memory on the cluster
- Nodes are down
- The API server is overloaded. For example, the scheduler might be under a
heavy load and therefore not completely available.
- Networking issues

Identify the root cause and fix it, if possible.

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  LowVirtOperatorCount.md

# LowVirtOperatorCount

## Meaning

This alert fires when only one `virt-operator` pod in a `Ready` state has been
running for the last 60 minutes.

The `virt-operator` is the first Operator to start in a cluster. Its primary
responsibilities include the following:

- Installing, live-updating, and live-upgrading a cluster
- Monitoring the lifecycle of top-level controllers, such as `virt-controller`,
`virt-handler`, `virt-launcher`, and managing their reconciliation
- Certain cluster-wide tasks, such as certificate rotation and infrastructure
management

## Impact

The `virt-operator` cannot provide high availability (HA) for the deployment. HA
requires two or more `virt-operator` pods in a `Ready` state. The default
deployment is two pods.

The `virt-operator` is not directly responsible for virtual machines (VMs) in
the cluster. Therefore, its decreased availability does not significantly affect
VM workloads.

## Diagnosis

1. Set the `NAMESPACE` environment variable:

   ```bash
   $ export NAMESPACE="$(oc get kubevirt -A -o custom-columns="":.metadata.namespace)"
   ```

2. Check the states of the `virt-operator` pods:

   ```bash
   $ oc -n $NAMESPACE get pods -l kubevirt.io=virt-operator
   ```

3. Review the logs of the affected `virt-operator` pods:

   ```bash
   $ oc -n $NAMESPACE logs <virt-operator>
   ```

4. Obtain the details of the affected `virt-operator` pods:

   ```bash
   $ oc -n $NAMESPACE describe pod <virt-operator>
   ```

## Mitigation

Based on the information obtained during the diagnosis procedure, try to
identify the root cause and resolve the issue.

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  NetworkAddonsConfigNotReady.md

# NetworkAddonsConfigNotReady

## Meaning

This alert fires when the `NetworkAddonsConfig` custom resource (CR) of the
Cluster Network Addons Operator (CNAO) is not ready.

CNAO deploys additional networking components on the cluster. This alert
indicates that one of the deployed components is not ready.

## Impact

Network functionality is affected.

## Diagnosis

1. Check the status conditions of the `NetworkAddonsConfig` CR to identify the
deployment or daemon set that is not ready:

   ```bash
   $ oc get networkaddonsconfig -o custom-columns=':.status.conditions[*].message' | tr -d '\n'
   ```

   Example output:

   ```text
   DaemonSet "openshift-cnv/macvtap-cni" update is being processed...
   ```

2. Check the component's pod for errors:

   ```bash
   $ oc -n openshift-cnv get daemonset <daemonset> -o yaml
   ```

3. Check the component's logs:

   ```bash
   $ oc -n openshift-cnv logs <pod>
   ```

4. Check the component's details for error conditions:

   ```bash
   $ oc -n openshift-cnv describe pod <pod>
   ```

## Mitigation

Try to identify the root cause and resolve the issue.

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  NoLeadingVirtOperator.md

# NoLeadingVirtOperator

## Meaning

This alert fires when no `virt-operator` pod with a leader lease has been
detected for 10 minutes, although the `virt-operator` pods are in a `Ready`
state. The alert indicates that no leader pod is available.

The `virt-operator` is the first Operator to start in a cluster. Its primary
responsibilities include the following:

- Installing, live updating, and live upgrading a cluster

- Monitoring the lifecycle of top-level controllers, such as `virt-controller`,
`virt-handler`, `virt-launcher`, and managing their reconciliation

- Certain cluster-wide tasks, such as certificate rotation and infrastructure
management

The `virt-operator` deployment has a default replica of 2 pods, with one pod
holding a leader lease.

## Impact

This alert indicates a failure at the level of the cluster. As a result,
critical cluster-wide management functionalities, such as certification
rotation, upgrade, and reconciliation of controllers, might not be available.

## Diagnosis

1. Set the `NAMESPACE` environment variable:

   ```bash
   $ export NAMESPACE="$(oc get kubevirt -A -o custom-columns="":.metadata.namespace)"
   ```

2. Obtain the status of the `virt-operator` pods:

   ```bash
   $ oc -n $NAMESPACE get pods -l kubevirt.io=virt-operator
   ```

3. Check the `virt-operator` pod logs to determine the leader status:

   ```bash
   $ oc -n $NAMESPACE logs | grep lead
   ```

   Leader pod example:

   ```text
   {"component":"virt-operator","level":"info","msg":"Attempting to acquire leader status","pos":"application.go:400","timestamp":"2021-11-30T12:15:18.635387Z"}
   I1130 12:15:18.635452       1 leaderelection.go:243] attempting to acquire leader lease <namespace>/virt-operator...
   I1130 12:15:19.216582       1 leaderelection.go:253] successfully acquired lease <namespace>/virt-operator
   {"component":"virt-operator","level":"info","msg":"Started leading","pos":"application.go:385","timestamp":"2021-11-30T12:15:19.216836Z"}
   ```

   Non-leader pod example:

   ```text
   {"component":"virt-operator","level":"info","msg":"Attempting to acquire leader status","pos":"application.go:400","timestamp":"2021-11-30T12:15:20.533696Z"}
   I1130 12:15:20.533792       1 leaderelection.go:243] attempting to acquire leader lease <namespace>/virt-operator...
   ```

4. Obtain the details of the affected `virt-operator` pods:

   ```bash
   $ oc -n $NAMESPACE describe pod <virt-operator>
   ```

## Mitigation

Based on the information obtained during the diagnosis procedure, try to
identify the root cause and resolve the issue.

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  NoReadyVirtController.md

# NoReadyVirtController

## Meaning

This alert fires when no available `virt-controller` devices have been detected
for 5 minutes.

The `virt-controller` devices monitor the custom resource definitions of virtual
machine instances (VMIs) and manage the associated pods. The devices create pods
for VMIs and manage the lifecycle of the pods.

Therefore, `virt-controller` devices are critical for all cluster-wide
virtualization functionality.

## Impact
Any actions related to VM lifecycle management fail. This notably includes
launching a new VMI or shutting down an existing VMI.

## Diagnosis

1. Set the `NAMESPACE` environment variable:

   ```bash
   $ export NAMESPACE="$(oc get kubevirt -A -o custom-columns="":.metadata.namespace)"
   ```

2. Verify the number of `virt-controller` devices:

   ```bash
   $ oc get deployment -n $NAMESPACE virt-controller -o jsonpath='{.status.readyReplicas}'
   ```

3. Check the status of the `virt-controller` deployment:

   ```bash
   $ oc -n $NAMESPACE get deploy virt-controller -o yaml
   ```

4. Obtain the details of the `virt-controller` deployment to check for status
conditions such as crashing pods or failure to pull images:

   ```bash
   $ oc -n $NAMESPACE describe deploy virt-controller
   ```

5. Obtain the details of the `virt-controller` pods:

   ```bash
   $ get pods -n $NAMESPACE | grep virt-controller
   ```

6. Check the logs of the `virt-controller` pods for error messages:

   ```bash
   $ oc logs -n $NAMESPACE <virt-controller>
   ```

7. Check the nodes for problems, suchs as a `NotReady` state:

   ```bash
   $ oc get nodes
   ```

## Mitigation

Based on the information obtained during the diagnosis procedure, try to
identify the root cause and resolve the issue.

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  NoReadyVirtOperator.md

# NoReadyVirtOperator

## Meaning

This alert fires when no `virt-operator` pod in a `Ready` state has been
detected for 10 minutes.

The `virt-operator` is the first Operator to start in a cluster. Its primary
responsibilities include the following:

- Installing, live-updating, and live-upgrading a cluster
- Monitoring the life cycle of top-level controllers, such as `virt-controller`,
`virt-handler`, `virt-launcher`, and managing their reconciliation
- Certain cluster-wide tasks, such as certificate rotation and infrastructure
management

The default deployment is two `virt-operator` pods.

## Impact

This alert indicates a cluster-level failure. Critical cluster management
functionalities, such as certification rotation, upgrade, and reconciliation of
controllers, might not be not available.

The `virt-operator` is not directly responsible for virtual machines in the
cluster. Therefore, its temporary unavailability does not significantly affect
custom workloads.

## Diagnosis

1. Set the `NAMESPACE` environment variable:

   ```bash
   $ export NAMESPACE="$(oc get kubevirt -A -o custom-columns="":.metadata.namespace)"
   ```

2. Obtain the name of the `virt-operator` deployment:

   ```bash
   $ oc -n $NAMESPACE get deploy virt-operator -o yaml
   ```

3. Generate the description of the `virt-operator` deployment:

   ```bash
   $ oc -n $NAMESPACE describe deploy virt-operator
   ```

4. Check for node issues, such as a `NotReady` state:

   ```bash
   $ oc get nodes
   ```

## Mitigation

Based on the information obtained during the diagnosis procedure, try to
identify the root cause and resolve the issue.

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  NodeNetworkInterfaceDown.md

# NodeNetworkInterfaceDown

## Meaning

This alert fires when one or more network interfaces on a node have been down
for more than 5 minutes. The alert excludes virtual ethernet (veth) devices and
bridge tunnels.

## Impact

Network interface failures can lead to:
- Reduced network connectivity for pods on the affected node
- Potential service disruptions if critical network paths are affected
- Degraded cluster communication if management interfaces are impacted

## Diagnosis

1. Identify the affected node and interfaces:
   ```bash
   oc get nodes
   ```

   ```bash
   ssh <node-address>
   ```

   ```bash
   ip link show | grep -i down
   ```

2. Check network interface details:
   ```bash
   ip addr show
   ```

   ```bash
   ethtool <interface-name>
   ```

3. Review system logs for network-related issues:
   ```bash
   journalctl -u NetworkManager
   ```

   ```bash
   dmesg | grep -i eth
   ```

## Mitigation

1. For physical interface issues:
   - Check physical cable connections
   - Verify switch port configuration
   - Test the interface with a different cable/port

2. For software or configuration issues:

   [OCPV:NodeNetworkInterfaceDown alert for unused network
interfaces](https://access.redhat.com/solutions/7123315)

3. If the issue persists:
   - Check network interface configuration files
   - Verify driver compatibility
   - If the failure is on a physical interface, consider hardware replacement

## Additional notes
- Monitor interface status after mitigation
- Document any hardware replacements or configuration changes
- Consider implementing network redundancy for critical interfaces

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  OperatorConditionsUnhealthy.md

# OperatorConditionsUnhealthy [Deprecated]

This alert is deprecated. You can safely ignore or silence it.
y resources
are in an error or warning state.

## Impact

Resources maintained by the operator might not be functioning correctly.

## Diagnosis

Check the operator conditions:

```bash
oc get <CR> <CR_OBJECT> -n <namespace> -o jsonpath='{.status.conditions}'
```

For example:

```bash
oc get HyperConverged kubevirt-hyperconverged -n kubevirt -o jsonpath='{.status.conditions}'
```

## Mitigation

Based on the information obtained during the diagnosis procedure, try to
identify the root cause within the operator or any of its secondary resources,
and resolve the issue.

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  OrphanedVirtualMachineInstances.md

# OrphanedVirtualMachineInstances

## Meaning

This alert fires when a virtual machine instance (VMI), or `virt-launcher` pod,
runs on a node that does not have a running `virt-handler` pod. Such a VMI is
called _orphaned_.

## Impact

Orphaned VMIs cannot be managed.

## Diagnosis

1. Check the status of the `virt-handler` pods to view the nodes on which they
are running:

   ```bash
   $ oc get pods --all-namespaces -o wide -l kubevirt.io=virt-handler
   ```

2. Check the status of the VMIs to identify VMIs running on nodes that do not
have a running `virt-handler` pod:

   ```bash
   $ oc get vmis --all-namespaces
   ```

3. Check the status of the `virt-handler` daemon:

   ```bash
   $ oc get daemonset virt-handler --all-namespaces
   ```

   Example output:

   ```text
   NAME                  DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
   virt-handler          2         2         2       2            2           kubernetes.io/os=linux   4h
   ```

   The daemon set is considered healthy if the `Desired`, `Ready`, and
   `Available` columns contain the same value.

4. If the `virt-handler` daemon set is not healthy, check the `virt-handler`
daemon set for pod deployment issues:

   ```bash
   $ oc get daemonset virt-handler --all-namespaces -o yaml | jq .status
   ```

5. Check the nodes for issues such as a `NotReady` status:

   ```bash
   $ oc get nodes
   ```

6. Check the `spec.workloads` stanza of the `KubeVirt` custom resource (CR) for
a workloads placement policy:

   ```bash
   $ oc get kubevirt kubevirt --all-namespaces -o yaml
   ```

## Mitigation

If a workloads placement policy is configured, add the node with the VMI to the
policy.

Possible causes for the removal of a `virt-handler` pod from a node include
changes to the node's taints and tolerations or to a pod's scheduling rules.

Try to identify the root cause and resolve the issue.

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  OutdatedVirtualMachineInstanceWorkloads.md

# OutdatedVirtualMachineInstanceWorkloads

## Meaning

This alert fires when running virtual machine instances (VMIs) in outdated
`virt-launcher` pods are detected 24 hours after the OpenShift Virtualization
control plane has
been updated.

## Impact

Outdated VMIs might not have access to new OpenShift Virtualization features.

Outdated VMIs will not receive the security fixes associated with the
`virt-launcher` pod update.

## Diagnosis

1. Identify the outdated VMIs:

   ```bash
   $ oc get vmi -l kubevirt.io/outdatedLauncherImage --all-namespaces
   ```

2. Check the `KubeVirt` custom resource (CR) to determine whether
`workloadUpdateMethods` is configured in the `workloadUpdateStrategy` stanza:

   ```bash
   $ oc get kubevirt --all-namespaces -o yaml
   ```

3. Check each outdated VMI to determine whether it is live-migratable:

   ```bash
   $ oc get vmi <vmi> -o yaml
   ```

   Example output:

   ```yaml
   apiVersion: kubevirt.io/v1
   kind: VirtualMachineInstance
   ...
     status:
       conditions:
       - lastProbeTime: null
         lastTransitionTime: null
         message: cannot migrate VMI which does not use masquerade to connect to the pod network
         reason: InterfaceNotLiveMigratable
         status: "False"
         type: LiveMigratable
   ```

## Mitigation

### Configuring automated workload updates

Update the `HyperConverged` CR to enable automatic workload updates.

### Stopping a VM associated with a non-live-migratable VMI

If a VMI is not live-migratable and if `runStrategy: always` is set in the
corresponding `VirtualMachine` object, you can update the VMI by manually
stopping the virtual machine (VM):

  ```bash
  $ virtctl stop --namespace <namespace> <vm>
  ```

A new VMI spins up immediately in an updated `virt-launcher` pod to replace the
stopped VMI. This is the equivalent of a restart action.

Note: Manually stopping a _live-migratable_ VM is destructive and not
recommended because it interrupts the workload.

### Migrating a live-migratable VMI

If a VMI is live-migratable, you can update it by creating a
`VirtualMachineInstanceMigration` object that targets a specific running VMI.
The VMI is migrated into an updated `virt-launcher` pod.

1. Create a `VirtualMachineInstanceMigration` manifest and save it as
`migration.yaml`:

   ```yaml
   apiVersion: kubevirt.io/v1
   kind: VirtualMachineInstanceMigration
   metadata:
     name: <migration_name>
     namespace: <namespace>
   spec:
     vmiName: <vmi_name>
   ```

2. Create a `VirtualMachineInstanceMigration` object to trigger the migration:

   ```bash
   $ oc create -f migration.yaml
   ```

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  PersistentVolumeFillingUp.md

<!--
Original source from KubePersistentVolumeFillingUp

https://github.com/prometheus-operator/runbooks/blob/main/content/runbooks/kubernetes/KubePersistentVolumeFillingUp.md
-->

# PersistentVolumeFillingUp

## Meaning

A persistent volume associated with your cluster has crossed the warning
threshold of 90% used capacity and is expected to fill up within 4 days.

## Impact

Service degradation, switching to read-only mode.

## Diagnosis

- Check persistent volume claim (PVC) usage from within a pod that mounts the
PVC. You can use the *exec* command to check the mounted filesystem in a pod:

```shell
$ oc exec -it <pod-name> -n <namespace> -- df -h /path/to/mount
```

- Check if services are enabled that might use large amounts of storage.
For example, these might include snapshots or automatic data retention.

## Mitigation

### Data retention

Deleting data that you no longer need is the fastest and the cheapest solution.

Request the service owner to delete specific sets of old data.

### Data export

If data is not needed in the service but needs to be processed later,
move it to a different storage resource, such as an S3 bucket.

### Data rebalance in the cluster

Some services automatically rebalance data on the cluster when a node fills up.
Some of these make it possible to rebalance data across existing nodes, others
may require adding new nodes. If data rebalancing is supported in your cluster,
increase the number of replicas and wait for data migration, or trigger the
migration manually.

Example services that support data rebalancing:

- cassandra
- ceph
- elasticsearch/opensearch
- gluster
- hadoop
- kafka
- minio

**Note**: Some services may require special scaling conditions for data
rebalancing, such as doubling the number of active nodes.

### Direct Volume resizing

If volume resizing is available, you can increase the capacity of the volume:

1. Check that volume expansion is available. To do so, use the following command
and replace `<my-namespace>` and `<my-pvc>`:

   ```shell
   $ oc get storageclass `oc -n <my-namespace> get pvc <my-pvc> -ojson | jq -r '.spec.storageClassName'`
   NAME                 PROVISIONER            RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
   standard (default)   kubernetes.io/gce-pd   Delete          Immediate           true                   28d
   ```

   This example displays  `ALLOWVOLUMEEXPANSION` as `true`, which means you can
   use volume resizing.

2. Resize the volume:
   ```shell
   $ oc -n <my-namespace> edit pvc <my-pvc>
   ```

3. Edit `.spec.resources.requests.storage` to use the required storage size.
If this succeeds, the PVC status will state "Waiting for user to (re-)start a
pod to finish file system resize of volume on node."

4. Verify that the setting has been changed accordingly:
    ```shell
    $ oc -n <my-namespace> get pvc <my-pvc>
    ```

5. When prompted by the PVC status, restart the respective pod. The following
command automatically finds the pod that mounts the PVC and deletes it. However,
if you know the pod name, you can also directly delete that pod:

   ```shell
   $ oc -n <my-namespace> delete pod `oc -n <my-namespace> get pod -ojson | jq -r '.items[] | select(.spec.volumes[] .persistentVolumeClaim.claimName=="<my-pvc>") | .metadata.name'`
   ```

### Migrate data to a new, larger volume

If resizing is not available and the data is not safe to delete, the best
solution is to create a larger volume and migrate the data.

### Purge the volume

If the data is ephemeral and volume expansion is not available, it may be best
to purge the volume.

**WARNING**: This will permanently delete the data on the volume.

### Migrate data to a new, larger instance pool in the same cluster

In very specific scenarios, it is better to schedule data migration in the same
cluster, but to a new instance. This may be difficult to accomplish due to how
certain resources are managed in OpenShift Container Platform.

The general procedure is as follows:
1. Add new nodes with greater capacity than the existing cluster.
2. Trigger data migration.
3. Scale the original instance pool to 0, and then delete it.

### Migrate data to a new, larger cluster

This is the most common scenario for resolving filling up persistent volumes.
However, it is significantly more expensive and may be time-consuming.
Also, migrating to a new cluster might cause split-brain issues.
As an example, the general procedure may have the following steps:

1. Create a data snapshot on the existing cluster.
2. Add a new cluster with greater capacity than the existing cluster.
3. Start a data restore operation on the new cluster based on the snapshot.
4. Switch the old cluster to read-only mode
5. Reconfigure networking to point to the new cluster.
6. Trigger data migration from the old cluster to the new cluster to sync the
differences between the snapshot and the latest writes.
7. Remove the old cluster.

### Support

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  SSPCommonTemplatesModificationReverted.md

# SSPCommonTemplatesModificationReverted

## Meaning

This alert fires when the Scheduling, Scale, and Performance (SSP) Operator
reverts changes to common templates as part of its reconciliation procedure.

The SSP Operator deploys and reconciles the common templates and the Template
Validator. If a user or script changes a common template, the changes are
reverted by the SSP Operator.

## Impact

Changes to common templates are overwritten.

## Diagnosis

1. Set the `NAMESPACE` environment variable:

   ```bash
   $ export NAMESPACE="$(oc get deployment -A | grep ssp-operator | awk '{print $1}')"
   ```

2. Check the `ssp-operator` logs for templates with reverted changes:

   ```bash
   $ oc -n $NAMESPACE logs --tail=-1 -l control-plane=ssp-operator | grep 'common template' -C 3
   ```

## Mitigation

Try to identify and resolve the cause of the changes.

Ensure that changes are made only to copies of templates, and not to the
templates themselves.

<!-- No downstream link. Modules cannot contain xrefs.-->


------------------------------


Original Filename:  SSPDown.md

# SSPDown

## Meaning

This alert fires when all the Scheduling, Scale and Performance (SSP) Operator
pods are down.

The SSP Operator is responsible for deploying and reconciling the common
templates and the Template Validator.

## Impact

Dependent components might not be deployed. Changes in the components might not
be reconciled. As a result, the common templates and/or the Template Validator
might not be updated or reset if they fail.

## Diagnosis

1. Set the `NAMESPACE` environment variable:

   ```bash
   $ export NAMESPACE="$(oc get deployment -A | grep ssp-operator | awk '{print $1}')"
   ```

2. Check the status of the `ssp-operator` pods.

   ```bash
   $ oc -n $NAMESPACE get pods -l control-plane=ssp-operator
   ```

3. Obtain the details of the `ssp-operator` pods:

   ```bash
   $ oc -n $NAMESPACE describe pods -l control-plane=ssp-operator
   ```

4. Check the `ssp-operator` logs for error messages:

   ```bash
   $ oc -n $NAMESPACE logs --tail=-1 -l control-plane=ssp-operator
   ```

## Mitigation

Try to identify the root cause and resolve the issue.
If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  SSPFailingToReconcile.md

# SSPFailingToReconcile

## Meaning

This alert fires when the reconcile cycle of the Scheduling, Scale and
Performance (SSP) Operator fails repeatedly, although the SSP Operator is
running.

The SSP Operator is responsible for deploying and reconciling the common
templates and the Template Validator.

## Impact

Dependent components might not be deployed. Changes in the components might not
be reconciled. As a result, the common templates and/or the Template Validator
might not be updated or reset if they fail.

## Diagnosis

1. Export the `NAMESPACE` environment variable:

   ```bash
   $ export NAMESPACE="$(oc get deployment -A | grep ssp-operator | awk '{print $1}')"
   ```

2. Obtain the details of the `ssp-operator` pods:

   ```bash
   $ oc -n $NAMESPACE describe pods -l control-plane=ssp-operator
   ```

3. Check the `ssp-operator` logs for errors:

   ```bash
   $ oc -n $NAMESPACE logs --tail=-1 -l control-plane=ssp-operator
   ```

4. Obtain the status of the `virt-template-validator` pods:

   ```bash
   $ oc -n $NAMESPACE get pods -l name=virt-template-validator
   ```

5. Obtain the details of the `virt-template-validator` pods:

   ```bash
   $ oc -n $NAMESPACE describe pods -l name=virt-template-validator
   ```

6. Check the `virt-template-validator` logs for errors:

   ```bash
   $ oc -n $NAMESPACE logs --tail=-1 -l name=virt-template-validator
   ```

## Mitigation

Try to identify the root cause and resolve the issue.
If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  SSPHighRateRejectedVms.md

# SSPHighRateRejectedVms

## Meaning

This alert fires when a user or script attempts to create or modify a large
number of virtual machines (VMs), using an invalid configuration.

## Impact

The VMs are not created or modified. As a result, the environment might not
behave as expected.

## Diagnosis

1. Export the `NAMESPACE` environment variable:

   ```bash
   $ export NAMESPACE="$(oc get deployment -A | grep ssp-operator | awk '{print $1}')"
   ```

2. Check the `virt-template-validator` logs for errors that might indicate the
cause:

   ```bash
   $ oc -n $NAMESPACE logs --tail=-1 -l name=virt-template-validator
   ```

   Example output:

   ```text
   {"component":"kubevirt-template-validator","level":"info","msg":"evalution
   summary for ubuntu-3166wmdbbfkroku0:\nminimal-required-memory applied: FAIL,
   value 1073741824 is lower than minimum [2147483648]\n\nsucceeded=false",
   "pos":"admission.go:25","timestamp":"2021-09-28T17:59:10.934470Z"}
   ```

## Mitigation

Try to identify the root cause and resolve the issue.
If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  SSPOperatorDown.md

# SSPOperatorDown

## Meaning

This alert fires when all the Scheduling, Scale and Performance (SSP) Operator
pods are down.

The SSP Operator is responsible for deploying and reconciling the common
templates and the Template Validator.

## Impact

Dependent components might not be deployed. Changes in the components might not
be reconciled. As a result, the common templates and/or the Template Validator
might not be updated or reset if they fail.

## Diagnosis

1. Set the `NAMESPACE` environment variable:

   ```bash
   $ export NAMESPACE="$(oc get deployment -A | grep ssp-operator | awk '{print $1}')"
   ```

2. Check the status of the `ssp-operator` pods.

   ```bash
   $ oc -n $NAMESPACE get pods -l control-plane=ssp-operator
   ```

3. Obtain the details of the `ssp-operator` pods:

   ```bash
   $ oc -n $NAMESPACE describe pods -l control-plane=ssp-operator
   ```

4. Check the `ssp-operator` logs for error messages:

   ```bash
   $ oc -n $NAMESPACE logs --tail=-1 -l control-plane=ssp-operator
   ```

## Mitigation

Try to identify the root cause and resolve the issue.
If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.

**Note:** Starting from 4.14, this runbook will no longer be supported. For a
supported runbook, please see [SSPDown
Runbook](http://kubevirt.io/monitoring/runbooks/SSPDown.html).


------------------------------


Original Filename:  SSPTemplateValidatorDown.md

# SSPTemplateValidatorDown

## Meaning

This alert fires when all the Template Validator pods are down.

The Template Validator checks virtual machines (VMs) to ensure that they do not
violate their templates.

## Impact

VMs are not validated against their templates. As a result, VMs might be created
with specifications that do not match their respective workloads.

## Diagnosis

1. Set the `NAMESPACE` environment variable:

   ```bash
   $ export NAMESPACE="$(oc get deployment -A | grep ssp-operator | awk '{print $1}')"
   ```

2. Obtain the status of the `virt-template-validator` pods:

   ```bash
   $ oc -n $NAMESPACE get pods -l name=virt-template-validator
   ```

3. Obtain the details of the `virt-template-validator` pods:

   ```bash
   $ oc -n $NAMESPACE describe pods -l name=virt-template-validator
   ```

4. Check the  `virt-template-validator` logs for error messages:

   ```bash
   $ oc -n $NAMESPACE logs --tail=-1 -l name=virt-template-validator
   ```

## Mitigation

Try to identify the root cause and resolve the issue.
If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  SingleStackIPv6Unsupported.md

# SingleStackIPv6Unsupported

## Meaning

This alert fires when user tries to install OpenShift Virtualization on a single
stack IPv6 cluster.

OpenShift Virtualization is not yet supported on an OpenShift cluster configured
with single stack IPv6. It's progress is being tracked on [this
issue](https://issues.redhat.com/browse/CNV-28924).

## Impact

OpenShift Virtualization Operator can't be installed on a single stack IPv6
cluster, and hence creation virtual machines on top of such a cluster is not
possible.

## Diagnosis

- Check the cluster network configuration by running the following command:
  ```shell
  $ oc get network.config cluster -o yaml
  ```
  The output displays only an IPv6 CIDR for the cluster network.

  Example output:
  ```text
  apiVersion: config.openshift.io/v1
  kind: Network
  metadata:
    name: cluster
  spec:
    clusterNetwork:
    - cidr: fd02::/48
      hostPrefix: 64
  ```

## Mitigation

It is recommended to use single stack IPv4 or a dual stack IPv4/IPv6 networking
to use OpenShift Virtualization .Refer the
[documentation](https://docs.openshift.com/container-platform/latest/networking/ovn_kubernetes_network_provider/converting-to-dual-stack.html).


------------------------------


Original Filename:  UnsupportedHCOModification.md

# UnsupportedHCOModification

## Meaning

This alert fires when a JSON Patch annotation is used to change an operand of
the HyperConverged Cluster Operator (HCO).

HCO configures OpenShift Virtualization and its supporting operators in an
opinionated way and
overwrites its operands when there is an unexpected change to them. Users must
not modify the operands directly.

However, if a change is required and it is not supported by the HCO API, you can
force HCO to set a change in an operator by using JSON Patch annotations. These
changes are not reverted by HCO during its reconciliation process.

## Impact

Incorrect use of JSON Patch annotations might lead to unexpected results or an
unstable environment.

Upgrading a system with JSON Patch annotations is dangerous because the
structure of the component custom resources might change.

## Diagnosis

Check the `annotation_name` in the alert details to identify the JSON Patch
annotation:

  ```text
  Labels
    alertname=UnsupportedHCOModification
    annotation_name=kubevirt.kubevirt.io/jsonpatch
    severity=info
  ```

## Mitigation

It is best to use the HCO API to change an operand. However, if the change can
only be done with a JSON Patch annotation, proceed with caution.

Remove JSON Patch annotations before upgrade to avoid potential issues.


------------------------------


Original Filename:  VMCannotBeEvicted.md

# VMCannotBeEvicted

## Meaning

This alert fires when the eviction strategy of a virtual machine (VM) is set to
`LiveMigration` but the VM is not migratable.

## Impact

Non-migratable VMs prevent node eviction. This condition affects operations such
as node drain and updates.

## Diagnosis

1. Check the VMI configuration to determine whether the value of
`evictionStrategy` is `LiveMigrate` of the VMI:

   ```bash
   $ oc get vmis -o yaml
   ```

2. Check for a `False` status in the `LIVE-MIGRATABLE` column to identify VMIs
that are not migratable:

   ```bash
   $ oc get vmis -o wide
   ```

3. Obtain the details of the VMI and check `spec.conditions` to identify the
issue:

   ```bash
   $ oc get vmi <vmi> -o yaml
   ```

   Example output:

   ```yaml
   status:
     conditions:
     - lastProbeTime: null
       lastTransitionTime: null
       message: cannot migrate VMI which does not use masquerade to connect to the pod network
       reason: InterfaceNotLiveMigratable
       status: "False"
       type: LiveMigratable
   ```

## Mitigation

Set the `evictionStrategy` of the VMI to `shutdown` or resolve the issue that
prevents the VMI from migrating.


------------------------------


Original Filename:  VMStorageClassWarning.md

# VMStorageClassWarning

## Meaning

When running VMs using ODF storage with 'rbd' mounter or 'rbd.csi.ceph.com'
provisioner, Windows VMs may cause reports of bad crc/signature errors due to
certain I/O patterns. Cluster performance can be severely degraded if the number
of re-transmissions due to crc errors causes network saturation. 'krbd:rxbounce'
should be configured for the VM storage class to prevent these crc errors, the
"ocs-storagecluster-ceph-rbd-virtualization" storage class uses this option by
default, if available.

## Impact

Cluster may report a huge number of CRC errors and the cluster might experience
major service outages.

## Diagnosis

Obtain a list of VirtualMachines with an incorrectly configured storage class by
running the following PromQL query:

**Note:** You can use the Openshift metrics explorer available at
'https://{OPENSHIFT_BASE_URL}/monitoring/query-browser'.

```promql
$ kubevirt_ssp_vm_rbd_block_volume_without_rxbounce == 1
```

Example output:

```plaintext
kubevirt_ssp_vm_rbd_block_volume_without_rxbounce{name="testvmi-gwgdqp22k7", namespace="test_ns_1"} 1
kubevirt_ssp_vm_rbd_block_volume_without_rxbounce{name="testvmi-rjqbjg47a8", namespace="test_ns_2"} 1
```

The output displays a list of VirtualMachines that use a storage class without
`rxbounce_enabled`.

Obtain the VM volumes by running the following command:

```bash
$ oc get vm <vm-name> -o json | jq -r '.spec.template.spec.volumes[] | if .dataVolume then "DataVolume - " + .dataVolume.name elif .persistentVolumeClaim then "PersistentVolumeClaim - " + .persistentVolumeClaim.claimName else empty end'
```

## Mitigation

It is recommended to create a dedicated StorageClass with "krbd:rxbounce" map
option for the disks of virtual machines, to use a bounce buffer when receiving
data. The default behavior is to read directly into the destination buffer. A
bounce buffer is required if the stability of the destination buffer cannot be
guaranteed.

Note that changing the used storage class will not have any impact on existing
PVCs/VMs, meaning that new VMs will be provisioned with the optimized settings
but existing VMs need to be transitioned or the alert will continue to fire for
those.

```bash
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: vm-sc
parameters:
  # ...
  mounter: rbd
  mapOptions: "krbd:rxbounce"
provisioner: openshift-storage.rbd.csi.ceph.com
# ...
```

See [Optimizing ODF PersistentVolumes for Windows VMs](https://access.redhat.com/articles/6978371)
for details.

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  VirtAPIDown.md

# VirtAPIDown

## Meaning

This alert fires when all the API Server pods are down.

## Impact

OpenShift Virtualization objects cannot send API calls.

## Diagnosis

1. Set the `NAMESPACE` environment variable:

   ```bash
   $ export NAMESPACE="$(oc get kubevirt -A -o custom-columns="":.metadata.namespace)"
   ```

2. Check the status of the `virt-api` pods:

   ```bash
   $ oc -n $NAMESPACE get pods -l kubevirt.io=virt-api
   ```

3. Check the status of the `virt-api` deployment:

   ```bash
   $ oc -n $NAMESPACE get deploy virt-api -o yaml
   ```

4. Check the `virt-api` deployment details for issues such as crashing pods or
image pull failures:

   ```bash
   $ oc -n $NAMESPACE describe deploy virt-api
   ```

5. Check for issues such as nodes in a `NotReady` state:

   ```bash
   $ oc get nodes
   ```

## Mitigation

Try to identify the root cause and resolve the issue.
If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  VirtApiRESTErrorsBurst.md

# VirtApiRESTErrorsBurst

## Meaning

For the last 10 minutes or longer, over 80% of the REST calls made to `virt-api`
pods have failed.

## Impact

A very high rate of failed REST calls to `virt-api` might lead to slow response
and execution of API calls, and potentially to API calls being completely
dismissed.

However, currently running virtual machine workloads are not likely to be
affected.

## Diagnosis

1. Set the `NAMESPACE` environment variable:

   ```bash
   $ export NAMESPACE="$(oc get kubevirt -A -o custom-columns="":.metadata.namespace)"
   ```

2. Obtain the list of `virt-api` pods on your deployment:

   ```bash
   $ oc -n $NAMESPACE get pods -l kubevirt.io=virt-api
   ```

3. Check the `virt-api` logs for error messages:

   ```bash
   $ oc logs -n $NAMESPACE <virt-api>
   ```

4. Obtain the details of the `virt-api` pods:

   ```bash
   $ oc describe -n $NAMESPACE <virt-api>
   ```

5. Check if any problems occurred with the nodes. For example, they might be in
a `NotReady` state:

   ```bash
   $ oc get nodes
   ```

6. Check the status of the `virt-api` deployment:

   ```bash
   $ oc -n $NAMESPACE get deploy virt-api -o yaml
   ```

7. Obtain the details of the `virt-api` deployment:

   ```bash
   $ oc -n $NAMESPACE describe deploy virt-api
   ```

## Mitigation

Based on the information obtained during the diagnosis procedure, try to
identify the root cause and resolve the issue.

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  VirtApiRESTErrorsHigh.md

# VirtApiRESTErrorsHigh

## Meaning

More than 5% of REST calls have failed in the `virt-api` pods in the last 60
minutes.

## Impact

A high rate of failed REST calls to `virt-api` might lead to slow response and
execution of API calls.

However, currently running virtual machine workloads are not likely to be
affected.

## Diagnosis

1. Set the `NAMESPACE` environment variable as follows:

   ```bash
   $ export NAMESPACE="$(oc get kubevirt -A -o custom-columns="":.metadata.namespace)"
   ```

2. Check the status of the `virt-api` pods:

   ```bash
   $ oc -n $NAMESPACE get pods -l kubevirt.io=virt-api
   ```

3. Check the `virt-api` logs:

   ```bash
   $ oc logs -n $NAMESPACE <virt-api>
   ```

4. Obtain the details of the `virt-api` pods:

   ```bash
   $ oc describe -n $NAMESPACE <virt-api>
   ```

5. Check if any problems occurred with the nodes. For example, they might be in
a `NotReady` state:

   ```bash
   $ oc get nodes
   ```

6. Check the status of the `virt-api` deployment:

   ```bash
   $ oc -n $NAMESPACE get deploy virt-api -o yaml
   ```

7. Obtain the details of the `virt-api` deployment:

   ```bash
   $ oc -n $NAMESPACE describe deploy virt-api
   ```

## Mitigation

Based on the information obtained during the diagnosis procedure, try to
identify the root cause and resolve the issue.

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  VirtControllerDown.md

# VirtControllerDown

## Meaning
No running `virt-controller` pod has been detected for 5 minutes.

## Impact
Any actions related to virtual machine (VM) lifecycle management fail. This
notably includes launching a new virtual machine instance (VMI) or shutting down
an existing VMI.

## Diagnosis

1. Set the `NAMESPACE` environment variable:

   ```bash
   $ export NAMESPACE="$(oc get kubevirt -A -o custom-columns="":.metadata.namespace)"
   ```

2. Check the status of the `virt-controller` deployment:

   ```bash
   $ oc get deployment -n $NAMESPACE virt-controller -o yaml
   ```

3. Review the logs of the `virt-controller` pod:

   ```bash
   $ oc get logs <virt-controller>
   ```

## Mitigation

This alert can have a variety of causes, including the following:

- Node resource exhaustion
- Not enough memory on the cluster
- Nodes are down
- The API server is overloaded. For example, the scheduler might be under a
heavy load and therefore not completely available.
- Networking issues

Identify the root cause and fix it, if possible.

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  VirtControllerRESTErrorsBurst.md

# VirtControllerRESTErrorsBurst

## Meaning

For the last 10 minutes or longer, over 80% of the REST calls made to
`virt-controller` pods have failed.

The `virt-controller` has likely fully lost the connection to the API server.

This error is frequently caused by one of the following problems:

- The API server is overloaded, which causes timeouts. To verify if this is the
case, check the metrics of the API server, and view its response times and
overall calls.

- The `virt-controller` pod cannot reach the API server. This is commonly caused
by DNS issues on the node and networking connectivity issues.

## Impact

Status updates are not propagated and actions like migrations cannot take place.
However, running workloads are not impacted.

## Diagnosis

1. Set the `NAMESPACE` environment variable:

   ```bash
   $ export NAMESPACE="$(oc get kubevirt -A -o custom-columns="":.metadata.namespace)"
   ```

2. List the available `virt-controller` pods:

   ```bash
   $ oc get pods -n $NAMESPACE -l=kubevirt.io=virt-controller
   ```

3. Check the `virt-controller` logs for error messages when connecting to the
API server:

   ```bash
   $ oc logs -n $NAMESPACE <virt-controller>
   ```

## Mitigation

- If the `virt-controller` pod cannot connect to the API server, delete the pod
to force a restart:

  ```bash
  $ oc delete -n $NAMESPACE <virt-controller>
  ```

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  VirtControllerRESTErrorsHigh.md

# VirtControllerRESTErrorsHigh

## Meaning

More than 5% of REST calls failed in `virt-controller` in the last 60 minutes.

This is most likely because `virt-controller` has partially lost connection to
the API server.

This error is frequently caused by one of the following problems:

- The API server is overloaded, which causes timeouts. To verify if this is the
case, check the metrics of the API server, and view its response times and
overall calls.

- The `virt-controller` pod cannot reach the API server. This is commonly caused
by DNS issues on the node and networking connectivity issues.

## Impact

Node-related actions, such as starting and migrating, and scheduling virtual
machines, are delayed. Running workloads are not affected, but reporting their
current status might be delayed.

## Diagnosis

1. Set the `NAMESPACE` environment variable:

   ```bash
   $ export NAMESPACE="$(oc get kubevirt -A -o custom-columns="":.metadata.namespace)"
   ```

2. List the available `virt-controller` pods:

   ```bash
   $ oc get pods -n $NAMESPACE -l=kubevirt.io=virt-controller
   ```

3. Check the `virt-controller` logs for error messages when connecting to the
API server:

   ```bash
   $ oc logs -n $NAMESPACE <virt-controller>
   ```

## Mitigation

- If the `virt-controller` pod cannot connect to the API server, delete the pod
to force a restart:

  ```bash
  $ oc delete -n $NAMESPACE <virt-controller>
  ```

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  VirtHandlerDaemonSetRolloutFailing.md

# VirtHandlerDaemonSetRolloutFailing

## Meaning

The `virt-handler` daemon set has failed to deploy on one or more worker nodes
after 15 minutes.

## Impact

This alert is a warning. It does not indicate that all `virt-handler` daemon
sets have failed to deploy. Therefore, the normal lifecycle of virtual machines
is not affected unless the cluster is overloaded.

## Diagnosis

Identify worker nodes that do not have a running `virt-handler` pod:

1. Export the `NAMESPACE` environment variable:

   ```bash
   $ export NAMESPACE="$(oc get kubevirt -A -o jsonpath='{.items[].metadata.namespace}')"
   ```

2. Check the status of the `virt-handler` pods to identify pods that have not
deployed:

   ```bash
   $ oc get pods -n $NAMESPACE -l=kubevirt.io=virt-handler
   ```

3. Obtain the name of the worker node of the `virt-handler` pod:

   ```bash
   $ oc -n $NAMESPACE get pod <virt-handler> -o jsonpath='{.spec.nodeName}'
   ```

## Mitigation

If the `virt-handler` pods failed to deploy because of insufficient resources,
you can delete other pods on the affected worker node.


------------------------------


Original Filename:  VirtHandlerRESTErrorsBurst.md

# VirtHandlerRESTErrorsBurst

## Meaning

For the last 10 minutes or longer, over 80% of the REST calls made to
`virt-handler` pods have failed.

This alert usually indicates that the `virt-handler` pods cannot connect to the
API server.

This error is frequently caused by one of the following problems:

- The API server is overloaded, which causes timeouts. To verify if this is the
case, check the metrics of the API server, and view its response times and
overall calls.

- The `virt-handler` pod cannot reach the API server. This is commonly caused by
DNS issues on the node and networking connectivity issues.

## Impact

Status updates are not propagated and node-related actions, such as migrations,
fail. However, running workloads on the affected node are not impacted.

## Diagnosis

1. Set the `NAMESPACE` environment variable:

   ```bash
   $ export NAMESPACE="$(oc get kubevirt -A -o custom-columns="":.metadata.namespace)"
   ```

2. Check the status of the `virt-handler` pod:

   ```bash
   $ oc get pods -n $NAMESPACE -l=kubevirt.io=virt-handler
   ```

3. Check the `virt-handler` logs for error messages when connecting to the API
server:

   ```bash
   $ oc logs -n $NAMESPACE <virt-handler>
   ```

## Mitigation

- If the `virt-handler` cannot connect to the API server, delete the pod to
force a restart:

  ```bash
  $ oc delete -n $NAMESPACE <virt-handler>
  ```

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  VirtHandlerRESTErrorsHigh.md

# VirtHandlerRESTErrorsHigh

## Meaning

More than 5% of REST calls failed in `virt-handler` in the last 60 minutes. This
alert usually indicates that the `virt-handler` pods have partially lost
connection to the API server.

This error is frequently caused by one of the following problems:

- The API server is overloaded, which causes timeouts. To verify if this is the
case, check the metrics of the API server, and view its response times and
overall calls.

- The `virt-handler` pod cannot reach the API server. This is commonly caused by
DNS issues on the node and networking connectivity issues.

## Impact

Node-related actions, such as starting and migrating workloads, are delayed on
the node that `virt-handler` is running on. Running workloads are not affected,
but reporting their current status might be delayed.

## Diagnosis

1. Set the `NAMESPACE` environment variable:

   ```bash
   $ export NAMESPACE="$(oc get kubevirt -A -o custom-columns="":.metadata.namespace)"
   ```

2. List the available `virt-handler` pods to identify the failing `virt-handler`
pod:

   ```bash
   $ oc get pods -n $NAMESPACE -l=kubevirt.io=virt-handler
   ```

3. Check the failing `virt-handler` pod log for error messages when connecting
to the API server:

   ```bash
   $ oc logs -n $NAMESPACE <virt-handler>
   ```

   Example error message:

   ```json
   {"component":"virt-handler","level":"error","msg":"Can't patch node my-node","pos":"heartbeat.go:96","reason":"the server has received too many API requests and has asked us to try again later","timestamp":"2023-11-06T11:11:41.099883Z","uid":"132c50c2-8d82-4e49-8857-dc737adcd6cc"}
   ```

## Mitigation

If the `virt-handler` cannot connect to the API server, delete the pod to force
a restart:

```bash
$ oc delete -n $NAMESPACE <virt-handler>
```

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  VirtOperatorDown.md

# VirtOperatorDown

## Meaning

This alert fires when no `virt-operator` pod in the `Running` state has been
detected for 10 minutes.

The `virt-operator` is the first Operator to start in a cluster. Its primary
responsibilities include the following:

- Installing, live-updating, and live-upgrading a cluster
- Monitoring the life cycle of top-level controllers, such as `virt-controller`,
`virt-handler`, `virt-launcher`, and managing their reconciliation
- Certain cluster-wide tasks, such as certificate rotation and infrastructure
management

The `virt-operator` deployment has a default replica of 2 pods.

## Impact

This alert indicates a failure at the level of the cluster. Critical
cluster-wide management functionalities, such as certification rotation,
upgrade, and reconciliation of controllers, might not be available.

The `virt-operator` is not directly responsible for virtual machines (VMs) in
the cluster. Therefore, its temporary unavailability does not significantly
affect VM workloads.

## Diagnosis

1. Set the `NAMESPACE` environment variable:

   ```bash
   $ export NAMESPACE="$(oc get kubevirt -A -o custom-columns="":.metadata.namespace)"
   ```

2. Check the status of the `virt-operator` deployment:

   ```bash
   $ oc -n $NAMESPACE get deploy virt-operator -o yaml
   ```

3. Obtain the details of the `virt-operator` deployment:

   ```bash
   $ oc -n $NAMESPACE describe deploy virt-operator
   ```

4. Check the status of the `virt-operator` pods:

   ```bash
   $ oc get pods -n $NAMESPACE -l=kubevirt.io=virt-operator
   ```

5. Check for node issues, such as a `NotReady` state:

   ```bash
   $ oc get nodes
   ```

## Mitigation

Based on the information obtained during the diagnosis procedure, try to
identify the root cause and resolve the issue.

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  VirtOperatorRESTErrorsBurst.md

# VirtOperatorRESTErrorsBurst

## Meaning

For the last 10 minutes or longer, over 80% of the REST calls made to
`virt-operator` pods have failed.

This usually indicates that the `virt-operator` pods cannot connect to the API
server.

This error is frequently caused by one of the following problems:

- The API server is overloaded, which causes timeouts. To verify if this is the
case, check the metrics of the API server, and view its response times and
overall calls.

- The `virt-operator` pod cannot reach the API server. This is commonly caused
by DNS issues on the node and networking connectivity issues.

## Impact

Cluster-level actions, such as upgrading and controller reconciliation, might
not be available.

However, customer workloads, such as virtual machines (VMs) and VM instances
(VMIs), are not likely to be affected.

## Diagnosis

1. Set the `NAMESPACE` environment variable:

   ```bash
   $ export NAMESPACE="$(oc get kubevirt -A -o custom-columns="":.metadata.namespace)"
   ```

2. Check the status of the `virt-operator` pods:

   ```bash
   $ oc -n $NAMESPACE get pods -l kubevirt.io=virt-operator
   ```

3. Check the `virt-operator` logs for error messages when connecting to the API
server:

   ```bash
   $ oc -n $NAMESPACE logs <virt-operator>
   ```

4. Obtain the details of the `virt-operator` pod:

   ```bash
   $ oc -n $NAMESPACE describe pod <virt-operator>
   ```

## Mitigation

- If the `virt-operator` pod cannot connect to the API server, delete the pod to
force a restart:

  ```bash
  $ oc delete -n $NAMESPACE <virt-operator>
  ```

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  VirtOperatorRESTErrorsHigh.md

# VirtOperatorRESTErrorsHigh

## Meaning

This alert fires when more than 5% of the REST calls in `virt-operator` pods
failed in the last 60 minutes. This usually indicates the `virt-operator` pods
cannot connect to the API server.

This error is frequently caused by one of the following problems:

- The API server is overloaded, which causes timeouts. To verify if this is the
case, check the metrics of the API server, and view its response times and
overall calls.

- The `virt-operator` pod cannot reach the API server. This is commonly caused
by DNS issues on the node and networking connectivity issues.

## Impact

Cluster-level actions, such as upgrading and controller reconciliation, might be
delayed.

However, customer workloads, such as virtual machines (VMs) and VM instances
(VMIs), are not likely to be affected.

## Diagnosis

1. Set the `NAMESPACE` environment variable:

   ```bash
   $ export NAMESPACE="$(oc get kubevirt -A -o custom-columns="":.metadata.namespace)"
   ```

2. Check the status of the `virt-operator` pods:

   ```bash
   $ oc -n $NAMESPACE get pods -l kubevirt.io=virt-operator
   ```

3. Check the `virt-operator` logs for error messages when connecting to the API
server:

   ```bash
   $ oc -n $NAMESPACE logs <virt-operator>
   ```

4. Obtain the details of the `virt-operator` pod:

   ```bash
   $ oc -n $NAMESPACE describe pod <virt-operator>
   ```

## Mitigation

- If the `virt-operator` pod cannot connect to the API server, delete the pod to
force a restart:

  ```bash
  $ oc delete -n <install-namespace> <virt-operator>
  ```

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.


------------------------------


Original Filename:  VirtualMachineCRCErrors.md

# VirtualMachineCRCErrors [Deprecated]

This alert is deprecated. You can safely ignore or silence it.



------------------------------


Original Filename:  VirtualMachineStuckInUnhealthyState.md

# VirtualMachineStuckInUnhealthyState

## Meaning

This alert triggers when a VirtualMachine (VM) has been in an unhealthy state
for more than 10 minutes and does not have an associated VMI
(VirtualMachineInstance).

The alert indicates that a VM is experiencing early-stage lifecycle issues
before a VMI can be successfully created. This typically occurs during the
initial phases of VM startup when OpenShift Virtualization is trying to
provision resources,
pull images, or schedule the workload.

**Affected States:**
- `Provisioning` - Resources (DataVolumes, PVCs) are being prepared
- `Starting` - VM is attempting to start but no VMI exists yet
- `Terminating` - VM is being deleted but without an active VMI
- `Error` states - Various scheduling, image, or resource allocation errors

## Impact

- **Severity:** Warning
- **User Impact:** VMs cannot start or are stuck in error states
- **Business Impact:** Workloads cannot be deployed, which affects application
  availability

## Possible Causes

### Resource-Related Issues
- Insufficient cluster resources (CPU, memory, storage)
- Missing or misconfigured storage classes
- PVC provisioning failures
- DataVolume creation/import failures

### Image and Registry Issues
- Container image pull failures for containerDisk volumes
- Registry authentication problems
- Network connectivity issues to image registries
- Missing or corrupted VM disk images

### Scheduling and Node Issues
- No schedulable nodes available (all nodes cordoned/unschedulable)
- Insufficient resources like KVM/GPU on available nodes
- A mismatch between requested and available CPU models
- Node selector constraints cannot be satisfied
- Taints and tolerations preventing scheduling

### Configuration Issues
- Invalid VM specifications (malformed YAML, unsupported features)
- Missing required Secrets or ConfigMaps
- Incorrect resource requests/limits
- Network configuration errors

## Diagnosis

### 1. Check VM Status and Events
```bash
# Get VM details and status
oc get vm <vm-name> -n <namespace> -o yaml

# Check VM events for error messages
oc describe vm <vm-name> -n <namespace>

# Look for related events in the namespace
oc get events -n <namespace> --sort-by='.lastTimestamp'
```

### 2. Verify Resource Availability
```bash
# Check node resources and schedulability
oc get nodes -o wide
oc describe nodes

# Check storage classes and provisioners
oc get storageclass
oc get pv,pvc -n <namespace>

# For DataVolumes (if using)
oc get datavolume -n <namespace>
oc describe datavolume <dv-name> -n <namespace>
```

### 3. Check Image Availability (for containerDisk)
```bash
# If using containerDisk, verify image accessibility from the affected node
# Start a debug session on the node hosting the VM (or a representative node)
oc debug node/<node-name> -it --image=busybox

# Inside the debug pod, check which container runtime is used
ps aux | grep -E "(containerd|dockerd|crio)"

# For CRI-O/containerd clusters use crictl to pull the image
crictl pull <vm-disk-image>

# For Docker-based clusters (less common)
docker pull <vm-disk-image>

# Exit the debug session when done
exit

# Check image pull secrets if required
oc get secrets -n <namespace>
```

### 4. Verify KubeVirt Configuration
```bash
# Discover the KubeVirt installation namespace
export NAMESPACE="$(oc get kubevirt -A -o custom-columns="":.metadata.namespace)"

# Check KubeVirt CR conditions (expect Available=True)
oc get kubevirt -n "$NAMESPACE" \
  -o jsonpath='{range .items[*].status.conditions[*]}{.type}={.status}{"\n"}{end}'

# Or check a single CR named 'kubevirt'
oc get kubevirt kubevirt -n "$NAMESPACE" \
  -o jsonpath='{.status.conditions[?(@.type=="Available")].status}'

# Verify virt-controller is running
oc get pods -n "$NAMESPACE" \
  -l kubevirt.io=virt-controller

# Check virt-controller logs for errors
# Replace <virt-controller-pod> with a pod name from the list above
oc logs -n "$NAMESPACE" <virt-controller-pod>

# Verify virt-handler is running
oc get pods -n "$NAMESPACE" \
  -l kubevirt.io=virt-handler -o wide

# Check virt-handler logs for errors (daemonset uses per-node pods)
# Replace <virt-handler-pod> with a pod name from the list above
oc logs -n "$NAMESPACE" <virt-handler-pod>
```

### 5. Review VM Specification
Inspect the following details in the VM's spec to catch common
misconfigurations:

- Disks and volumes (in spec.template.spec.domain.devices and volumes):
  - A bootable disk is defined using *bootOrder: 1*
  - Each disk name matches a volume name
  - Volume sources are valid: PVC, DataVolume, containerDisk, secret, or
    configMap

- Resources (in spec.template.spec.domain.resources):
  - Resource requests and limits are set and do not exceed node capacity

- Scheduling (in spec.template.spec):
  - nodeSelector, affinity, and tolerations are not overly restrictive

- Image pull configuration (in spec.template.spec.imagePullSecrets):
  - imagePullSecrets are configured if using a private image registry

- Power strategy (in spec.runStrategy or spec.running):
  - Only one of spec.runStrategy or spec.running is set, and it matches the
    desired behavior

## Mitigation

### Resource Issues
1. **Scale up the cluster** if the issue is insufficient resources
2. **Create missing storage classes** or configure default storage
3. **Resolve PVC/DataVolume failures**:
   ```bash
   oc get pvc -n <namespace>
   oc describe pvc <pvc-name> -n <namespace>
   ```

### Image Issues
1. **Verify image accessibility**:
   ```bash
   # Validate from the node
   oc debug node/<node-name> -it --image=busybox

   # Inside the debug pod, detect runtime and pull
   ps aux | grep -E "(containerd|dockerd|crio)"

   # For CRI-O/containerd clusters:
   crictl pull <image-name>

   # For Docker-based clusters (less common):
   docker pull <image-name>

   exit
   ```
2. **Configure image pull secrets** if needed:
   ```bash
   oc create secret docker-registry <secret-name> \
     --docker-server=<registry-url> \
     --docker-username=<username> \
     --docker-password=<password>
   ```

### Scheduling Issues
1. **Review VM scheduling constraints** and relax if too restrictive:
   - nodeSelector, affinity, and tolerations
   - Required CPU model, host devices, or features

2. **Verify that node taints and tolerations** allow scheduling:
   - Ensure the VM tolerates node taints that apply to target nodes

3. **Ensure that nodes have required capabilities**:
   - KVM availability, CPU features, GPU, SR-IOV, or storage access

4. If nodes were intentionally cordoned for maintenance, **uncordon** when
   appropriate:
   ```bash
   oc uncordon <node-name>
   ```

### Configuration Issues Resolution
1. **Fix VM specification errors** based on the *oc describe* output:
   ```bash
   # Edit VM specification directly
   oc edit vm <vm-name> -n <namespace>

   # Or patch specific fields
   oc patch vm <vm-name> -n <namespace> --type='merge' \
     -p='{"spec":{"template":{"spec":{"domain":{"resources": \
       {"requests":{"memory":"2Gi"}}}}}}}'
   ```
2. **Create missing secrets/configmaps**:
   ```bash
   oc create secret generic <secret-name> \
     --from-literal=key=value
   ```
3. **Adjust resource requests** if they exceed node capacity

### Emergency Workarounds
- **Restart the VM** to apply specification changes:
  ```bash
  # Restart the VM to pick up spec changes
  virtctl restart <vm-name> -n <namespace>
  ```
- **Scale down non-critical workloads** temporarily if resource
  constraints exist
- **Change storage class** if PVC provisioning fails:
  ```bash
  # Check current storage class status
  oc get storageclass
  oc describe storageclass <current-storage-class>

  # Look for PVC provisioning errors
  oc describe pvc <pvc-name> -n <namespace>

  # If seeing "no volume provisioner" or similar errors,
  # specify a working storage class in VM spec:
  # spec.dataVolumeTemplates[].spec.pvc.storageClassName:
  #   <working-class>
  ```

## Prevention

1. **Resource Planning:**
   - Monitor cluster resource utilization
   - Set appropriate VM guest resources in the VM domain guest spec.
   - Plan storage capacity and provisioning

2. **Image Management:**
   - Use local image registries where possible to reduce
     latency
   - Configure DataVolume import methods appropriately:
     * **Pod import method**: Images pulled to temporary pods (default)
     * **Node import method**: Images pulled directly to nodes
       (requires pre-pulling)
   - Pre-pull critical containerDisk images to nodes only if
     using node import method

3. **Monitoring:**
   - Set up alerts for cluster resource exhaustion
   - Monitor storage provisioner health
   - Track VM startup success rates

4. **Testing:**
   - Validate VM templates in development environments
   - Test VM deployments after cluster changes
   - Regularly verify image accessibility

## Escalation

Escalate to the cluster administrator if:
- Multiple VMs are affected simultaneously (possible cluster-wide issue)
- Issue persists after following resolution steps
- A malfunction of OpenShift Virtualization components is suspected
- You are unable to access system logs for further diagnosis
- You do not have enough permissions to run the diagnosis or mitigation steps

## Related Alerts

- `VirtControllerDown` - May indicate controller issues preventing
  VM processing
- `LowKVMNodesCount` - Related to insufficient KVM-capable nodes
- `KubeVirtNoAvailableNodesToRunVMs` - Indicates no nodes available
  for VM scheduling

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support
case, attaching the artifacts gathered during the diagnosis
procedure.


------------------------------


Original Filename:  VirtualMachineStuckOnNode.md

# VirtualMachineStuckOnNode

## Meaning

This alert triggers when a VirtualMachine (VM) with an associated
VirtualMachineInstance (VMI) has been stuck in an unhealthy state for more than
5 minutes on a specific node.

The alert indicates that the VM has progressed past initial scheduling and has
an active VMI, but is experiencing runtime issues on the assigned node. This
typically occurs after the VM has been scheduled to a node but encounters
problems during startup, operation, or shutdown phases.

**Affected States:**
- `Starting` - VMI exists but VM is failing to reach running state
- `Stopping` - VM is attempting to stop but the process is stuck
- `Terminating` - VM is being deleted but the termination process is hanging
- `Error` states - Runtime errors occurring on the node (ErrImagePull,
  ImagePullBackOff, etc.)

## Impact

- **Severity:** Warning
- **User Impact:** VMs are unresponsive or stuck in transition states
- **Business Impact:** Running workloads may be disrupted, which affects
application performance and availability
- **Node Impact:** Resources may be tied up by unresponsive VMs, which affects
other workloads on the same node

## Possible Causes

### Node-Level Issues
- **Node resource exhaustion** (CPU, memory, storage)
- **Container runtime problems** (issues with containerd or CRI-O)
- **Insufficient storage** on the node
- **Network connectivity issues** from the node
- **Node entering the NotReady state** or maintenance mode

### QEMU/KVM Issues
- **QEMU process failures** or hangs
- **KVM acceleration problems** on the node
- **Nested virtualization** configuration issues
- **Hardware compatibility** problems

### Image and Storage Issues
- **Container image pull failures** specific to the node
- **Local image cache corruption**
- **PVC mount failures** on the node
- **Storage backend connectivity** issues from the node
- **Volume attachment timeouts**

### virt-launcher Pod Issues
- **virt-launcher pod** stuck in non-ready state
- **Pod resource limits** being exceeded
- **Security policy violations** (SELinux, AppArmor)
- **Networking problems** within the pod

### libvirt/Domain Issues
- **libvirt daemon** problems on the node
- **Domain definition** conflicts or corruption
- **Migration failures** (if VM was being migrated)
- **Hot-plug operations** that failed and left VM in inconsistent
  state

## Diagnosis

### 1. Check VM and VMI Status
```bash
# Get VM details with node information
oc get vm <vm-name> -n <namespace> -o yaml

# Check VMI status and node assignment
oc get vmi <vm-name> -n <namespace> -o yaml
oc describe vmi <vm-name> -n <namespace>

# Look for related events
oc get events -n <namespace> \
  --field-selector involvedObject.name=<vm-name>
```

### 2. Examine virt-launcher Pod
```bash
# Find the virt-launcher pod for this VM
oc get pods -n <namespace> -l kubevirt.io/domain=<vm-name>

# Check pod status and events
oc describe pod <virt-launcher-pod> -n <namespace>

# Check pod logs for errors
oc logs <virt-launcher-pod> -n <namespace> -c compute
oc logs <virt-launcher-pod> -n <namespace> -c istio-proxy \
  # if using Istio

# Optional: Check resource usage for the virt-launcher pod
oc top pod <virt-launcher-pod> -n <namespace>
```

### 3. Investigate Node Health
```bash
# Check node status and conditions (may require admin
# permissions)
oc describe node <node-name>

# Discover the KubeVirt installation namespace
export NAMESPACE="$(oc get kubevirt -A -o custom-columns="":.metadata.namespace)"

# Check virt-handler on the affected node
oc get pods -n "$NAMESPACE" -o wide | grep <node-name>
oc logs <virt-handler-pod> -n "$NAMESPACE"
```

### 4. Check Storage and Volumes
```bash
# Verify PVC status and mounting
oc get pvc -n <namespace>
oc describe pvc <pvc-name> -n <namespace>

# Check volume attachments on the node
oc get volumeattachment | grep <node-name>

# For DataVolumes, check their status
oc get dv -n <namespace>
oc describe dv <dv-name> -n <namespace>
```

### 5. Verify Image Accessibility from Node
```bash
# Verify image accessibility from the affected node
oc debug node/<node-name> -it --image=busybox

# Inside the debug pod, check which container runtime is used
ps aux | grep -E "(containerd|dockerd|crio)"

# For CRI-O/containerd clusters:
crictl pull <vm-disk-image>

# For Docker-based clusters (less common):
docker pull <vm-disk-image>

# Exit the debug session when done
exit
```

### 6. Exec into the virt‑launcher pod’s compute container and inspect
domains
```bash
oc exec -it <virt-launcher-pod> -n <namespace> -c compute \
  -- virsh list --all | grep <vm-name>
oc exec -it <virt-launcher-pod> -n <namespace> -c compute \
  -- virsh dumpxml <domain-name>

```

## Mitigation

### Pod-Level Issues
1. **Restart the virt-launcher pod**:
   ```bash
   oc delete pod <virt-launcher-pod> -n <namespace>
   # The VMI controller will recreate it
   ```

2. **Check resource constraints**:
   ```bash
   oc describe pod <virt-launcher-pod> -n <namespace>
   # Look for resource limit violations
   ```

### Image Issues on Node
1. **Inspect and, if necessary, clear image cache** on the node:
   ```bash
   # SSH to the node or start a debug session on the node:
   oc debug node/<node-name> -it --image=busybox

   # Detect which container runtime is in use
   ps aux | grep -E "(containerd|dockerd|crio)"

   # List cached images first
   # For CRI-O/containerd clusters:
   crictl images
   # For Docker-based clusters:
   docker images

   # Remove only if a corrupted/stale image is suspected
   # For CRI-O/containerd clusters:
   crictl rmi <problematic-image>
   # For Docker-based clusters:
   docker rmi <problematic-image>

   exit
   ```

2. **Force image re-pull**:
   ```bash
   # Delete and recreate the virt-launcher pod
   oc delete pod <virt-launcher-pod> -n <namespace>
   ```

### Storage Issues
1. **Check PVC binding and mounting**:
   ```bash
   oc get pvc -n <namespace>
   # If PVC is stuck, check the storage provisioner
   ```

2. **Resolve volume attachment issues**:
   ```bash
   oc get volumeattachment
   # Delete stuck volume attachments if necessary
   oc delete volumeattachment <attachment-name>
   ```

### Node-Level Issues Resolution
1. **Drain and uncordon the node** if it is in a bad state:
   ```bash
   oc drain <node-name> --ignore-daemonsets \
     --delete-emptydir-data
   oc uncordon <node-name>
   ```

2. **Restart node-level components**:
   ```bash
   # Restart virt-handler on the node
   oc delete pod <virt-handler-pod> -n "$NAMESPACE"
   ```

### VM-Level Resolution
1. **Force‑delete the VMI (triggers creating a new VMI)**:
   ```bash
   oc delete vmi <vm-name> -n <namespace> --force \
     --grace-period=0
   ```

2. **Migrate the VM to a different node**:
   ```bash
   virtctl migrate <vm-name> -n <namespace>
   ```

### Emergency Actions
- **Live migrate** critical VMs away from the problematic node
- **Force delete** the unresponsive VMI if safe to do so:
  ```bash
  oc delete vmi <vm-name> -n <namespace> --force --grace-period=0
  ```
- **Cordon the node** to prevent new VM scheduling while investigating

## Prevention

1. **Node Health Monitoring:**
   - Monitor node resource utilization (CPU, memory,
     storage)
   - Set up alerts for node conditions and taints
   - Perform regular health checks on container runtime

2. **Resource Management:**
   - Set appropriate resource requests/limits on VMs
   - Monitor PVC and storage utilization
   - Plan for node capacity and VM density

3. **Image Management:**
   - Use image pull policies appropriately (Always,
     IfNotPresent)
   - Pre-pull critical images to nodes
   - Monitor image registry health and connectivity

4. **Networking:**
   - Ensure stable network connectivity between nodes and storage
   - Monitor DNS resolution and service discovery
   - Validate network policies do not block required traffic

5. **Regular Maintenance:**
   - Keep nodes and OpenShift Virtualization components updated

## Escalation

Escalate to the cluster administrator if:
- Multiple VMs are affected on the same node simultaneously
- VMs consistently fail to start or become unresponsive after
  following troubleshooting steps
- Node‑specific issues persist (Like kubelet or kernel panic) and
  require a node reboot
- A malfunction of OpenShift Virtualization components is suspected
- You are unable to access system logs for further diagnosis
- You do not have enough permissions to run the diagnosis and/or mitigation
  steps.

## Related Alerts

- `OrphanedVirtualMachineInstances` - May indicate virt-handler
  problems on nodes
- `VirtHandlerDown` - Related to virt-handler pod failures
- `VirtualMachineStuckInUnhealthyState` - For VMs that haven't
  progressed to having VMIs

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support
case, attaching the artifacts gathered during the diagnosis
procedure.


------------------------------


