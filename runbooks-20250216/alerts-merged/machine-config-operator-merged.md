Original Filename:  MachineConfigControllerDrainError.md

# MCCDrainError

## Meaning

Alerts the user to when the Machine Config Operator (MCO)
fails to drain a node, which prevents the MCO from restarting.

>Alerts the user to a failed node drain. Always triggers when the failure
>happens one or more times.

This alert will fire as a warning when:

- The MCO is unable to drain the node for an hour
- The failure occurs one or more times in a node

## Impact

If the MCO fails to drain a node, it will be unable to reboot the node,
which prevents any changes to the cluster through
a MachineConfig and prevents a cluster upgrade.
If the MCO fails to drain a node during an upgrade,
the upgrade will not be able to progress/complete.

## Diagnosis

If a node fails to drain, first check the `machine-config-controller` pod
inside the `openshift-machine-config-operator` namespace by using the following command.
The `machine-config-controller` pod is the central point of management
for incoming updates to machines.

For the following command, replace the $CONTROLLERPOD variable
with the name of your own `machine-config-controller` pod name.

```console
oc -n openshift-machine-config-operator logs $CONTROLLERPOD -c machine-config-controller
```
When the MCO starts draining a node,
the Machine Config Controller (MCC) records the following log entry:

```console
1 drain_controller.go:173] node xxxxxxx-xxxxxx-xxxxxx-xxxxx: initiating drain
```
The MCC then logs the name of each pod that is drained from the node.

```console
  1 drain_controller.go:173] node xxxxxxx-xxxxxx-xxxxxx-xxxxx: Evicted pod <namespace>/<pod-name>
```

If the MCO/MCC is unable to drain a pod after 1m30s,
the MCC logs the following error message:

```console
1 drain_controller.go:173] node xxxxxxx-xxxxxx-xxxxxx-xxxxx: Drain failed. Waiting 1 minute then retrying. Error message from drain: error when waiting for pod "xxxx-xxxx-xx" in namespace "xxxxxxx" to terminate: global timeout reached: 1m30s
```

If the drain continues to fail, the MCC logs a second error message:

```console
 1 drain_controller.go:173] node xxxxxxx-xxxxxx-xxxxxx-xxxxx: Drain failed. Drain has been failing for more than 10 minutes. Waiting 5 minutes then retrying. Error message from drain: error when waiting for pod "xxxx-xxxx-xx" in namespace "xxxxxxx" to terminate: global timeout reached: 1m30s
```

After one hour has passed and the drain is still failing,
the MCC logs the following error messages
and the node is marked degraded.

```console
1 drain_controller.go:352] node xxxxxxx-xxxxxx-xxxxxx-xxxxx: drain exceeded timeout: 1h0m0s. Will continue to retry.
```

```console
1 status.go:126] Degraded Machine: xxxxxxx-xxxxxx-xxxxxx-xxxxx: and Degraded Reason: failed to drain node: xxxxxxx-xxxxxx-xxxxxx-xxxxx after 1 hour. Please see machine-config-controller logs for more information
```

The MCC logs explicitly list which pods are failing to drain.
You should start examining the listed pods
for the problem that is causing the drain to fail.
Common reasons why a node cannot drain a pod include the following conditions:

- The pod has a PodDisruptionBudget (PBD)
  that prevents the MCO/MCC from deleting the pod.
- The pod has storage attached and the kubelet is unable to unmount the storage.
- The pod has a webhook that is configured to target UPDATE
  operations or the webhook is not being called by the kube-apiserver.
- The pod has finalizers set in the pod that are preventing it from terminating.

## Mitigation

- If a PDB is causing the failure you can temporarily patch
  it to set the `minAvailable` to 0 so it can scale the pod down successfully.
  Then patch it to the previous value after the upgrade completes.

   ```console
   oc patch pdb $PDB -n $NS --type=merge -p '{"spec":{"minAvailable":0}}'
   ```
- If a webhook is preventing the pod deletion:

    1. Check the `openshift-kube-apiserver` logs to see
       exactly what webhook is preventing deletion.

       ```console
       Failed calling webhook, failing open vault.hashicorp.com: failed calling webhook "webhook_name": failed to call webhook: Post "https://hashi-vault-agent-injector-svc.vault-injector.svc:443/mutate?timeout=30s": context canceled2022-10-11T19:13:53.345381984Z E1011 19:13:53.345348      16 dispatcher.go:184] failed calling webhook "webhook_name": failed to call webhook: Post "https://name-injector-svc.vault-injector.svc:443/mutate?timeout=30s": context canceled
       ```
    2. Check if it's a `mutating` or `validating` webhook.
        ```console
        $ oc get validatingwebhookconfiguration
        $ oc get mutatingwebhookconfiguration
        ```
    3. Backup and delete the webhook
        ```console
        $ oc get validatingwebhookconfiguration/<webhook_name> -o yaml > webhook.yaml
        $ oc delete <webhook_type> <webhook_name>         
        ```
    4. This should allow the drain to continue and if the webhook
       does not come back automatically you can recreate it via the backup.

- If a pod cannot unmount storage, troubleshoot why it's failing.
  For example, if you are using NFS storage,
  the problem could be a network issue with the storage server.

- Otherwise, if you are comfortable with possible data loss,
  you can force delete the pod and immediately remove resources
  from the API and bypass graceful deletion:

    ```console
    $ oc delete pod <pod-name> --force=true --grace-period=0
    ```
- If the finalizers are causing the pod to be stuck
  in terminating status you can try patching the finalizers to null:

    ```console
    oc patch pod <pod_name> -p '{"metadata":{"finalizers":null}}' -n <namespace_name>
    ```
- Or, you can force delete the pod using the previous command.





------------------------------


Original Filename:  MachineConfigControllerPausedPoolKubeletCA.md

# MachineConfigControllerPausedPoolKubeletCA

## Meaning

The apiserver has performed a certificate rotation, but the specified
MachineConfigPool is paused, preventing deployment of the MachineConfig
containing the rotated  `kublet-ca.crt` bundle to the pool's nodes.

>You will  need to unpause the specified pool to allow the new certificate
>through before the existing one expires.

This alert fires as a warning for a pool when:

- A MachineConfigPool is paused AND
- There is a new `kubelet-ca.crt` specified in the MachineConfigPool's spec AND
- The pool has been in this state for more than `1 hour`

This alert becomes critical for a pool when:

- The above conditions are met, and there are only two weeks ( `14 days` )
  remaining until the expiry date of the pool's most recent
  `kube-apiserver-to-kubelet-signer` certificate.

For clarity, the pool has a MachineConfig specified in
`status.Configuration.Name`. That MachineConfig has a file inside it with a path
of `/etc/kubernetes/kubelet-ca.crt`.  Inside that file is a certificate
`kube-apiserver-to-kubelet-signer` which has to be valid for your nodes to work.
The MachineConfigPool's `pause` feature is preventing that configuration from
being updated.

## Impact

If the pool remains paused, the nodes in the specified pool will stop working
when the certificates in the pool's existing `kubelet-ca.crt`  bundle expire.

### Short term: warning

> NOTE: This is not a desirable state to be in unless you know what you're
> doing.

After (at most) 12 hours following a certificate rotation, you will experience
the following negative symptoms if your pool is still paused:

- Pod logs for nodes in the specified pool will not be viewable in the web
  console
- The commands `oc logs`  ,  `oc debug` ,  `oc attach`,  `oc exec`  will not be
  usable.

This happens because:

- These features depend on having a  `kubelet-client` certificate in the cluster
  that matches the node's `kube-apiserver-to-kubelet-signer`
- The `kubelet-client` certificate in the cluster rotates every 12 hours
- The `kubelet-client` is signed by the *most recent*
  `kube-apiserver-to-kubelet-signer`
- When a certificate rotation happens, nodes in the paused pool no longer have
  the most recent `kube-apiserver-to-kubelet-signer` (it is in `kubelet-ca.crt`,
  which is stuck behind pause)
- So once `kubelet-client` rotates and gets signed with the most recent signer,
  nodes in the paused pool cannot verify `kubelet-client` and therefore do not
  trust it.

Other than these symptoms, your nodes should work normally until the
kube-apiserver-to-kubelet-signer expires.

### Long term: critical

The `kube-apiserver-to-kubelet-signer` certificate in the `kubelet-ca.crt`
bundle is what enables trust between your node's kubelet and your cluster. The
apiserver schedules a rotation when this certificate reaches 80% of its
(currently 365 day) lifetime. The new one *must* be deployed before all of the
previous ones expire.

The kubelets on the nodes in the specified pool will stop communicating with the
cluster apiserver if the `kube-apiserver-to-kubelet-signer`  is allowed to
expire. The nodes will no longer be able to participate in the cluster. *This is
very bad*.

To avoid this, you will need to unpause the specified pool to allow the new
`kubelet-ca.crt` bundle to be deployed.

## Diagnosis

If a pool is paused, it was paused by an administrator; pools do not pause
themselves automatically.

>NOTE: there are some operators (like SR-IOV) that may briefly pause a pool to
>do some work, but they will not leave the pool paused long-term.

For the commands below, replace `$MCP_NAME` with the name of your pool.

You can see the pool's paused status by looking at the `spec.paused` field for
the pool:

```console
oc -n openshift-machine-config-operator get mcp $MCP_NAME -o jsonpath='{.spec.paused}'
```

For the `kube-apiserver-to-kubelet-signer` certificate in the cluster, you can
check its annotations to see when it was rotated:

```console
oc -n openshift-kube-apiserver-operator describe secret kube-apiserver-to-kubelet-signer
```

For the `kubelet-client` cert (the one that is responsible for `oc logs`, etc
working) in the cluster, you can check which signer it was signed with:

```console
oc -n openshift-kube-apiserver describe secret/kubelet-client
```

You can also check the certificates that are present in the `kublet-ca.crt`
bundle on one of your nodes to see when they expire:

```console
openssl crl2pkcs7 -nocrl -certfile /etc/kubernetes/kubelet-ca.crt | openssl pkcs7 -print_certs -text -noout
``````

>NOTE: There may be multiple `kube-apiserver-to-kubelet-signer` certificates in
>the certificate bundles, kube-apiserver does not pull them out until they
>expire. You want to look at the *newest* `kube-apiserver-to-kubelet-signer`.

You can find which MachineConfig a pool is currently using by looking at the
pool status:

```console
oc -n openshift-machine-config-operator get mcp $MCP_NAME -o jsonpath='{.status.configuration.name}'
```

Use the following commands to check the expiry dates, based on how the bundle is
encoded.

If the bundle is URL-encoded, use the following command with the desired
MachineConfig to decode it:

```console
oc get mc rendered-worker-bc1470f2331a3136999e0b49d85e1e21 -o jsonpath='{.spec.config.storage.files[?(@.path=="/etc/kubernetes/kubelet-ca.crt")].contents.source}' | python3 -c 'import sys, urllib.parse; print(urllib.parse.unquote(sys.stdin.read()))' | openssl x509 -text -noout
```

If the bundle is base64-encoded and gzipped, use the following command with the
desired MachineConfig to decode it:

```console
ENCODEDCERT=$(oc get mc rendered-worker-bc1470f2331a3136999e0b49d85e1e21 -o jsonpath='{.spec.config.storage.files[?(@.path=="/etc/kubernetes/kubelet-ca.crt")].contents.source}') CHOMPED=${ENCODEDCERT#"data:;base64,"} echo $CHOMPED | base64 -d | gzip -d | openssl x509 -text -noout
```

## Mitigation

You must unpause the pool.

>NOTE: Unpausing the pool will result in **ALL** pending configuration that was
>"waiting behind pause" being applied, and not just the certificate bundle.

Unpause the pool (substitute the pool name for $MCP_NAME):

```console
oc patch mcp $MCP_NAME --type='json' -p='[{"op": "replace", "path": "/spec/paused", "value":false}]'
```

You can also unpause manually by:

```console
oc edit mcp $MCP_NAME
```

and changing `spec.paused` to `false`.



------------------------------


Original Filename:  MachineConfigDaemonPivotError.md

# MCDPivotError

## Meaning

This alert is triggered when the Machine Config Daemon (MCD)
detects an error when trying to pivot the
operating system (OS) image to a new version or a kernel
change. If the MCD is unable to complete
the pivot or change within 2 minutes the alert
will fire.

## Impact

If the MCD is unable to update the OS and
finish pivoting then this can prevent an
OpenShift upgrade from completing.
This can leave the cluster in a
unstable state and further affect the operation of the cluster.

## Diagnosis

When a node pivots to update the OS image,
the `rpm-ostree` service logs any
actions taken to the `machine-config-daemon-*` pod.

If the MCD fails to
update or pivot a node's OS or kernel,
the first logs that you should
check are the `machine-config-daemon-*`
pod logs for the cluster.

For the following command, replace the $DAEMONPOD variable
with the name of your own machine-config-daemon-* pod name.
That is scheduled on the node expriencing the error.

```console
oc logs -f -n openshift-machine-config-operator $DAEMONPOD -c machine-config-daemon
```
When a pivot is occuring the following will be logged.

```console
I1126 17:15:38.991090    3069 rpm-ostree.go:243] Executing rebase to quay.io/my-registry/custom-image@blah
```
The MCD will log its attempt to pivot.

```console
I1126 17:15:38.991115    3069 update.go:2618] Running: rpm-ostree rebase --experimental ostree-unverified-registry:quay.io/my-registry/custom-image@blah
Pulling manifest: ostree-unverified-registry:quay.io/my-registry/custom-image@blah
```
If the MCD fails to update the OS it will rollback.

```console
E1126 17:16:07.549890    3069 writer.go:226] Marking Degraded due to: failed to update OS to quay.io/my-registry/custom-image@blah : error running rpm-ostree rebase --experimental ostree-unverified-registry:quay.io/my-registry/custom-image@blah: error: Creating importer: Failed to invoke skopeo proxy method OpenImage: remote error: invalid reference format
: exit status 1
```

The MCD will then mark the node degraded.

```console
2024-06-20T17:56:33.930222523Z E0620 17:56:33.930211 4168959 writer.go:135] Marking Degraded due to: failed to update OS to quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:368d9b871acb9fc29eea6a4f66e42894677594e91834958c015ed15c03ebe79e : error running rpm-ostree rebase --experimental /run/mco-machine-os-content/os-content-501945936/srv/repo:afdc646803e2d9d774fbf3429cf91de6222e45a85ceabbafe4ee78aca74c2d7b --custom-origin-url pivot://quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:368d9b871acb9fc29eea6a4f66e42894677594e91834958c015ed15c03ebe79e --custom-origin-description Managed by machine-config-operator: error: Timeout was reached
```

The node will continue trying to pivot despite the error.
You should start troubleshooting
by examining the main error message and the
stated reason it gives for not being able to pivot. The following are
common reasons a pivot can fail.

- The rpm-ostree service is unable to
pull the image from quay succesfully.
- There are issues with the rpm-ostree service itself such as
being unable to start, or unable to build the OsImage folder,
unable to pivot from the current configuration.
- The rpm-ostree service gets stuck and client is unable to finish
the transaction and gets stuck in a loop as a result.
- The ostree-finalize-staged.service
  (responsible for rolling out pending updates) is having issues.
- Networking issues on the node prevent quay from
being reachable, such as an interface being
down, a firewall blocking the connection, the proxy, etc.

## Mitigation

- If the machine-config-daemon pod is
  logging the following errors from rpm-ostree,
  it is likely that rpm-ostree is stuck in a
  loop and cannot finish the transaction
  or there are issues related to the rpm-ostree service itself.

  ```console
   error: Transaction in progress: (null)
  ```
  You should restart the `rpm-ostreed`
  service on the node that are failing.

  ```console
  $ oc debug node <Node-name>
  # chroot /host
  # systemctl restart rpm-ostreed
  ```
- If the machine-config-daemon pod is
  logging the following errors, it is likely due to networking errors related to
  timeouts or Internal Server errors in the daemon or controller pods.

     ```console
    received unexpected HTTP status: 500 Internal Server Error
     ```

  - Make sure that `quay.io` and
    it's subdomains are whitelisted by your firewall and proxy.
    You can test manual pulls with `podman pull`.

    ```console
    $ podman pull quay.io/startx/couchbase:ubi8 --log-level debug
    ```
    - You should also validate that the internal
     network on the node and the external network
     are healthy and there are no blockers
     such as a firewall or switch issues.

- You can also try to force a manual upgrade to the new image
  if the pivot is stuck.

  ```console
  -delete the currentconfig(rm /etc/machine-config-daemon/currentconfig)
  -create a forcefile(touch /run/machine-config-daemon-force) to retry the OS upgrade.
  ```

  - If you want to dive deeper you can also use the
    rpm-ostree command line tool to attempt to force a pivot

    ```console
     rpm-ostree rebase --experimental ostree-unverified-registry:quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    ```

- If these troubleshooting steps do not fix the problem, gather
  the following logs, which will be helpful
  for identifying the issue.

    ```console
    # rpm-ostree status
    # journalctl -u ostree-finalize-staged
    # journalctl -b -1 -u rpm-ostreed.service
    ```


------------------------------


Original Filename:  SystemMemoryExceedsReservation.md

# SystemMemoryExceedsReservation

## Meaning

This alert is triggered when system daemons are
detected to be using more memory
than is reserved by the
kubelet. This alert will fire if system daemons
are exceeding 95% of the reservation for 15
minutes or more.

## Impact

This alert is a warning to let a system admin
know system daemons are using up the memory
equivalent to more then 95%
of the system reserved.
The system daemons needs this memory in order to
run and satisfy system processes. If other workloads
start to use this memory then system daemons
can be impacted. This alert
firing does not nessarily mean the node is
resource exhausted at the moment.

## Diagnosis

This alert is triggered by an expression
which consists of a Prometheus query. The
full query is as follows:

```console
sum by (node) (container_memory_rss{id="/system.slice"}) > ((sum by (node) (kube_node_status_capacity{resource="memory"} - kube_node_status_allocatable{resource="memory"})) * 0.95)
```

This can be split into two commands with
the greater operator as the split
point.

The right side of the query consists of
static values.

`((sum by (node) (kube_node_status_capacity{resource="memory"}-
kube_node_status_allocatable{resource="memory"})) * 0.95)`

This query takes the total memory capacity of the node
minus the the amount of memory allocatable for pods.
This gives the amount of memory reserved
for the system daemons. This is then multiplied by 0.95
to get the 95th percentile.

  `container_memory_rss{id="/system.slice"}`
(The total resident set slice which is a
portion of the system's memory occupied by
a process that is held in the main memory)

  If this value is greather then the 95th
  percentile of the allocatable memory for
  the node then the alert will go into pending.
  After 15 minutes in this state the alert
  will fire.

Because this is a comparator operation, if the
condition is not met, there will be no datapoints
displayed by the query.

## Mitigation

By default the `system-reserved` value
for memory is 1Gi. This value can be changed
manually post install. You can also have
the kubelet automatically determine and allocate the
system-reserved value via a script on each
node. This will take into account the CPU
and memory capacity that is installed on
the node.

To manually set the system-reserve value
or automatically set it, you must create a
KubeletConfig and give it the appropriate
`machineConfigPoolSelector` so it propagates
to the correct nodes you want to target.

- For manual allocation:
  
  ```console
  apiVersion: machineconfiguration.openshift.io/v1
  kind: KubeletConfig
  metadata:
    name: set-allocatable
  spec:
    machineConfigPoolSelector:
      matchLabels:
        pools.operator.machineconfiguration.openshift.io/worker: ""
    kubeletConfig:
      systemReserved:
        cpu: 1000m
        memory: 3Gi
  ```
- For automatic allocation:

  ```console
  apiVersion: machineconfiguration.openshift.io/v1
  kind: KubeletConfig
  metadata:
    name: dynamic-node
  spec:
    autoSizingReserved: true
    machineConfigPoolSelector:
      matchLabels:
        pools.operator.machineconfiguration.openshift.io/worker: ""
  ```
If increasing the memory value for
system-reserved is not an option,
you will need to investigate
and troubleshoot which processes
are consuming the host's memory.

The following commands are
useful for troubleshooting:

- You can use the `top` command on
the host to get a dynamic update of
the largest memory consuming proccesses.
For instance, to get the top 100 memory
consuming processes on a node.

   ```console
     $ oc debug node/<node>
     $ chroot /host
     $ top -b -n100 -d2
   ```

- Another host-level command is the `free`
command which allows you to check the memory
statistics of the node.

- Each node also contains a file called
`/proc/meminfo`. This file provides a usage
report about memory on the system. You can
learn how to interperet the fields [here](https://access.redhat.com/solutions/406773).

- For kubelet-level commands you can get
the memory usage of individual pods by
using the `oc adm top pods` command.
You can further tune it to look at
individual containers by adding the
`--containers=true` flag.

- You can use Prometheus to deep
dive into the memory usage of nodes and
pods. Red Hat provides multiple pre-built
dashboards and PromQL queries to track
memory usage over time. All within the
`Observe` section of the OpenShift
console.


------------------------------


