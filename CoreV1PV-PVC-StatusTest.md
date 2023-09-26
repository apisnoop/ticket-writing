# Progress <code>[1/6]</code>

-   [ ] APISnoop org-flow : [CoreV1PV-PVC-StatusTest.org](https://github.com/apisnoop/ticket-writing/blob/master/CoreV1PV-PVC-StatusTest.org)
-   [ ] test approval issue : [#](https://issues.k8s.io/)
-   [ ] test pr : [!](https://pr.k8s.io/)
-   [ ] two weeks soak start date : [testgrid-link](https://testgrid.k8s.io/)
-   [ ] two weeks soak end date : xxxx-xx-xx
-   [ ] test promotion pr : [!](https://pr.k8s.io/)


# Identifying an untested feature Using APISnoop


## Untested Endpoints

According to following APIsnoop query, there are three PersistentVolume and three PersistentVolumeClaim endpoints that are untested.

```sql-mode
    SELECT
      endpoint,
      path,
      kind
      FROM testing.untested_stable_endpoint
      where eligible is true
      and endpoint ilike '%PersistentVolume%'
      order by kind, endpoint
      limit 10;
```

```example
                        endpoint                      |                                path                                 |         kind
  ----------------------------------------------------+---------------------------------------------------------------------+-----------------------
   patchCoreV1PersistentVolumeStatus                  | /api/v1/persistentvolumes/{name}/status                             | PersistentVolume
   readCoreV1PersistentVolumeStatus                   | /api/v1/persistentvolumes/{name}/status                             | PersistentVolume
   replaceCoreV1PersistentVolumeStatus                | /api/v1/persistentvolumes/{name}/status                             | PersistentVolume
   patchCoreV1NamespacedPersistentVolumeClaimStatus   | /api/v1/namespaces/{namespace}/persistentvolumeclaims/{name}/status | PersistentVolumeClaim
   readCoreV1NamespacedPersistentVolumeClaimStatus    | /api/v1/namespaces/{namespace}/persistentvolumeclaims/{name}/status | PersistentVolumeClaim
   replaceCoreV1NamespacedPersistentVolumeClaimStatus | /api/v1/namespaces/{namespace}/persistentvolumeclaims/{name}/status | PersistentVolumeClaim
  (6 rows)

```

-   <https://apisnoop.cncf.io/1.28.0/stable/core/patchCoreV1NamespacedPersistentVolumeClaimStatus>
-   <https://apisnoop.cncf.io/1.28.0/stable/core/readCoreV1NamespacedPersistentVolumeClaimStatus>
-   <https://apisnoop.cncf.io/1.28.0/stable/core/replaceCoreV1NamespacedPersistentVolumeClaimStatus>
-   <https://apisnoop.cncf.io/1.28.0/stable/core/patchCoreV1PersistentVolumeStatus>
-   <https://apisnoop.cncf.io/1.28.0/stable/core/readCoreV1PersistentVolumeStatus>
-   <https://apisnoop.cncf.io/1.28.0/stable/core/replaceCoreV1PersistentVolumeStatus>


# API Reference and feature documentation

-   [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/kubernetes-api/)
-   [Kubernetes API / Config and Storage Resources / PersistentVolume](https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/persistent-volume-v1/)
-   [Kubernetes API / Config and Storage Resources / PersistentVolumeClaim](https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/persistent-volume-claim-v1/)
-   [client-go - PersistentVolume](https://github.com/kubernetes/client-go/tree/master/kubernetes/typed/core/v1/persistentvolume.go)
-   [client-go - PersistentVolumeClaim](https://github.com/kubernetes/client-go/tree/master/kubernetes/typed/core/v1/persistentvolumeclaim.go)


# Test outline

```
Scenario: Test the status endpoints for a pv and a pvc

  Given the e2e test has created a PVC
  When the test reads the PVC status
  Then the requested action is accepted without any error
  And the phase of the retrieved PVC status equals "Pending"

  Given the e2e test has created a PV
  When the test reads the PV status
  Then the requested action is accepted without any error
  And the phase of the retrieved PVC status equals "Available"

  Given the e2e test has created a PVC
  When the test patches the PVC status with a new condition
  Then the requested action is accepted without any error
  And the test finds the new PVC status condition with the required "patched" values

  Given the e2e test has created a PV
  When the test patches the PV status with a new "message" and "reason"
  Then the requested action is accepted without any error
  And the test finds the new "patched" values for the PV status "message" and "reason"

  Given the e2e test has patched a PVC status
  When the test updates the PVC status with a new condition
  Then the requested action is accepted without any error
  And the test finds the new PVC status condition with the required "updated" values

  Given the e2e test has patched a PV status
  When the test updates the PV status with a new "message" and "reason"
  Then the requested action is accepted without any error
  And the test finds the new "updated" values for the PV status "message" and "reason"
```


# E2E Test

Using a number of existing e2e test practices a new [ginkgo test](https://github.com/ii/kubernetes/blob/create-pv-pvc-status-test/test/e2e/storage/persistent_volumes.go#L655-L784) has been created to provide future Conformance coverage for the 6 endpoints. The e2e logs for this test are listed below.

```
[sig-storage] PersistentVolumes CSI Conformance should apply changes to a pv/pvc status
/home/ii/go/src/k8s.io/kubernetes/test/e2e/storage/persistent_volumes.go:655
  STEP: Creating a kubernetes client @ 09/26/23 11:47:17.336
  Sep 26 11:47:17.336: INFO: >>> kubeConfig: /home/ii/.kube/config
  STEP: Building a namespace api object, basename pv @ 09/26/23 11:47:17.336
  STEP: Waiting for a default service account to be provisioned in namespace @ 09/26/23 11:47:17.378
  STEP: Waiting for kube-root-ca.crt to be provisioned in namespace @ 09/26/23 11:47:17.383
  STEP: Creating initial PV and PVC @ 09/26/23 11:47:17.388
  Sep 26 11:47:17.388: INFO: Creating a PV followed by a PVC
  STEP: Listing all PVs with the labelSelector: "e2e-pv-pool=pv-6988" @ 09/26/23 11:47:17.419
  STEP: Listing PVCs in namespace "pv-6988" @ 09/26/23 11:47:17.428
  STEP: Reading "pvc-4rl4x" Status @ 09/26/23 11:47:17.435
  STEP: Reading "pv-6988-2nthc" Status @ 09/26/23 11:47:17.439
  STEP: Patching "pvc-4rl4x" Status @ 09/26/23 11:47:17.454
  STEP: Patching "pv-6988-2nthc" Status @ 09/26/23 11:47:17.465
  STEP: Updating "pvc-4rl4x" Status @ 09/26/23 11:47:17.487
  STEP: Updating "pv-6988-2nthc" Status @ 09/26/23 11:47:17.501
  Sep 26 11:47:17.523: INFO: AfterEach: deleting 1 PVCs and 1 PVs...
  Sep 26 11:47:17.524: INFO: Deleting PersistentVolumeClaim "pvc-4rl4x"
  Sep 26 11:47:17.534: INFO: Deleting PersistentVolume "pv-6988-2nthc"
  Sep 26 11:47:17.544: INFO: Waiting up to 7m0s for all (but 0) nodes to be ready
  STEP: Destroying namespace "pv-6988" for this suite. @ 09/26/23 11:47:17.55
```


# Verifying increase in coverage with APISnoop


## Listing endpoints hit by the new e2e test

This query shows the following PV and PVC endpoints are hit within a short period of running this e2e test.

```sql-mode
select distinct substring(endpoint from '\w+') AS endpoint,
                right(useragent,39) AS useragent
from testing.audit_event
where useragent like 'e2e%should%'
  and release_date::BIGINT > round(((EXTRACT(EPOCH FROM NOW()))::numeric)*1000,0) - 20000
  and endpoint ilike '%Status%'
order by endpoint
limit 10;
```

```example
                      endpoint                      |                useragent
----------------------------------------------------+-----------------------------------------
 patchCoreV1NamespacedPersistentVolumeClaimStatus   | should apply changes to a pv/pvc status
 patchCoreV1PersistentVolumeStatus                  | should apply changes to a pv/pvc status
 readCoreV1NamespacedPersistentVolumeClaimStatus    | should apply changes to a pv/pvc status
 readCoreV1PersistentVolumeStatus                   | should apply changes to a pv/pvc status
 replaceCoreV1NamespacedPersistentVolumeClaimStatus | should apply changes to a pv/pvc status
 replaceCoreV1PersistentVolumeStatus                | should apply changes to a pv/pvc status
(6 rows)

```


# Final notes

If a test with these calls gets merged, **test coverage will go up by 6 points**

This test is also created with the goal of conformance promotion.

---

/sig testing

/sig architecture

/area conformance