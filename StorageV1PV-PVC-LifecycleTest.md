# Progress <code>[7/7]</code>

-   [X] APISnoop org-flow : [StorageV1PV-PVC-LifecycleTest.org](https://github.com/apisnoop/ticket-writing/blob/master/StorageV1PV-PVC-LifecycleTest.org)
-   [X] test approval issue : [Write e2e test for PersistentVolume & PersistentVolumeClaim Endpoints + 13 Endpoints #119694](https://issues.k8s.io/119694)
-   [X] test pr : [Write e2e test for PersistentVolume & PersistentVolumeClaim Endpoints + 13 Endpoints #119695](https://pr.k8s.io/119695)
-   [X] two weeks soak start date : 29 Aug 2023 [testgrid-link](https://testgrid.k8s.io/sig-release-master-blocking#gce-cos-master-default&width=5&graph-metrics=test-duration-minutes&include-filter-by-regex=should.run.through.the.lifecycle.of.a.PV.and.a.PVC)
-   [X] two weeks soak end date : 11 Sep 2023
-   [X] test promotion pr : [Promote e2e test for PersistentVolume & PersistentVolumeClaim Endpoints + 13 Endpoints #120552](https://pr.k8s.io/120552)
-   [X] remove endpoints from [pending<sub>eligible</sub><sub>endpoints.yaml</sub>](https://github.com/kubernetes/kubernetes/blob/master/test/conformance/testdata/pending_eligible_endpoints.yaml) : [Remove persistentvolume endpoints from pending<sub>eligible</sub><sub>endpoints.yaml</sub> #120553](https://github.com/kubernetes/kubernetes/pull/120553)


# Identifying an untested feature Using APISnoop


## Untested Endpoints

According to following APIsnoop query, there are two PersistentVolume and three PersistentVolumeClaim endpoints that are untested.

```sql-mode
    SELECT
      endpoint,
      path,
      kind
      FROM testing.untested_stable_endpoint
      where eligible is true
      and endpoint ilike '%PersistentVolume%'
      and endpoint not ilike '%Status'
      order by kind, endpoint
      limit 10;
```

```example
                         endpoint                        |                             path                             |         kind
  -------------------------------------------------------+--------------------------------------------------------------+-----------------------
   deleteCoreV1CollectionPersistentVolume                | /api/v1/persistentvolumes                                    | PersistentVolume
   patchCoreV1PersistentVolume                           | /api/v1/persistentvolumes/{name}                             | PersistentVolume
   deleteCoreV1CollectionNamespacedPersistentVolumeClaim | /api/v1/namespaces/{namespace}/persistentvolumeclaims        | PersistentVolumeClaim
   listCoreV1PersistentVolumeClaimForAllNamespaces       | /api/v1/persistentvolumeclaims                               | PersistentVolumeClaim
   patchCoreV1NamespacedPersistentVolumeClaim            | /api/v1/namespaces/{namespace}/persistentvolumeclaims/{name} | PersistentVolumeClaim
  (5 rows)

```

-   <https://apisnoop.cncf.io/1.27.0/stable/core/deleteCoreV1CollectionNamespacedPersistentVolumeClaim>
-   <https://apisnoop.cncf.io/1.27.0/stable/core/deleteCoreV1CollectionPersistentVolume>
-   <https://apisnoop.cncf.io/1.27.0/stable/core/listCoreV1PersistentVolumeClaimForAllNamespaces>
-   <https://apisnoop.cncf.io/1.27.0/stable/core/patchCoreV1NamespacedPersistentVolumeClaim>
-   <https://apisnoop.cncf.io/1.27.0/stable/core/patchCoreV1PersistentVolume>


## Endpoints that are not Conformance tested

-   <https://apisnoop.cncf.io/1.27.0/stable/core/createCoreV1NamespacedPersistentVolumeClaim>
-   <https://apisnoop.cncf.io/1.27.0/stable/core/createCoreV1PersistentVolume>
-   <https://apisnoop.cncf.io/1.27.0/stable/core/deleteCoreV1NamespacedPersistentVolumeClaim>
-   <https://apisnoop.cncf.io/1.27.0/stable/core/deleteCoreV1PersistentVolume>
-   <https://apisnoop.cncf.io/1.27.0/stable/core/readCoreV1NamespacedPersistentVolumeClaim>
-   <https://apisnoop.cncf.io/1.27.0/stable/core/readCoreV1PersistentVolume>
-   <https://apisnoop.cncf.io/1.27.0/stable/core/replaceCoreV1NamespacedPersistentVolumeClaim>
-   <https://apisnoop.cncf.io/1.27.0/stable/core/replaceCoreV1PersistentVolume>


## Endpoints that are already Conformance tested

-   <https://apisnoop.cncf.io/1.27.0/stable/core/listCoreV1NamespacedPersistentVolumeClaim>
-   <https://apisnoop.cncf.io/1.27.0/stable/core/listCoreV1PersistentVolume>


# API Reference and feature documentation

-   [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/kubernetes-api/)
-   [Kubernetes API / Config and Storage Resources / PersistentVolume](https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/persistent-volume-v1/)
-   [Kubernetes API / Config and Storage Resources / PersistentVolumeClaim](https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/persistent-volume-claim-v1/)
-   [client-go - PersistentVolume](https://github.com/kubernetes/client-go/tree/master/kubernetes/typed/core/v1/persistentvolume.go)
-   [client-go - PersistentVolumeClaim](https://github.com/kubernetes/client-go/tree/master/kubernetes/typed/core/v1/persistentvolumeclaim.go)


# Test outline

```
Scenario: Test the lifecycle of a PV and a PVC

  Given the e2e test has created the settings for a PV and a PVC
  When the test creates the PV and the PVC
  Then the requested action is accepted without any error

  Given the e2e test has created a PV
  When the test lists the PVs with a labelSelector
  Then the requested action is accepted without any error
  And the retrieved list has a single item

  Given the e2e test has created a PVC
  When the test lists the PVC for the namespace
  Then the requested action is accepted without any error
  And the retrieved list has a single item

  Given the e2e test has created a PV
  When the test patches the PV with a new label
  Then the requested action is accepted without any error
  And the test finds the new PV label with the required "patched" value

  Given the e2e test has created a PVC
  When the test patches the PVC with a new label
  Then the requested action is accepted without any error
  And the test finds the new PVC label with the required "patched" value

  Given the e2e test has patched the PV
  When the test reads the PV
  Then the requested action is accepted without any error
  And the UID of the retrieved PV equals the UID of the patched PV

  Given the e2e test has patched the PVC
  When the test reads the PVC
  Then the requested action is accepted without any error
  And the UID of the retrieved PVC equals the UID of the patched PVC

  Given the e2e test has retrieved the PVC
  When the test deletes the PVC
  Then the requested action is accepted without any error

  Given the e2e test has deleted the PVC
  When the test lists for the PVC
  Then the requested action is accepted without any error
  And the deletion of the PVC is confirmed

  Given the e2e test has retrieved the PV
  When the test deletes the PV
  Then the requested action is accepted without any error

  Given the e2e test has deleted the PV
  When the test lists for the PV with a labelSelector set
  Then the requested action is accepted without any error
  And the deletion of the PV is confirmed

  Given the e2e test has no PV or PVC
  When the test recreates a new PV and PVC
  Then the requested action is accepted without any error

  Given the e2e test has created a PV
  When the test updates the PV label
  Then the requested action is accepted without any error
  And the test finds the PV label with the required "updated" value

  Given the e2e test has created a PVC
  When the test updates the PVC label
  Then the requested action is accepted without any error
  And the test finds the PVC label with the required "updated" value

  Given the e2e test has updated a PVC
  When the test lists PVCs in all namespaces with a label selector
  Then the requested action is accepted without any error
  And only one PVC is found

  Given the e2e test has created a LabelSelector for the PVC
  When the test applies the deleteCollection action with a labelSelector
  Then the requested action is accepted without any error
  And the PVC with the label is not found

  Given the e2e test has created a LabelSelector for the PV
  When the test applies the deleteCollection action with a labelSelector
  Then the requested action is accepted without any error
  And the PV with the label is not found
```


# E2E Test

Using a number of existing e2e test practices a new [ginkgo test](https://github.com/ii/kubernetes/blob/create-pv-pvc-lifecycle-test/test/e2e/storage/persistent_volumes.go#L329-L539) has been created to provide future Conformance coverage for the 13 endpoints. The e2e logs for this test are listed below.

```
[sig-storage] PersistentVolumes CSI Conformance should run through the lifecycle of a PV and a PVC
/home/ii/go/src/k8s.io/kubernetes/test/e2e/storage/persistent_volumes.go:346
  STEP: Creating a kubernetes client @ 07/31/23 13:58:14.575
  Jul 31 13:58:14.575: INFO: >>> kubeConfig: /home/ii/.kube/config
  STEP: Building a namespace api object, basename pv @ 07/31/23 13:58:14.576
  STEP: Waiting for a default service account to be provisioned in namespace @ 07/31/23 13:58:14.665
  STEP: Waiting for kube-root-ca.crt to be provisioned in namespace @ 07/31/23 13:58:14.669
  STEP: Creating initial PV and PVC @ 07/31/23 13:58:14.674
  Jul 31 13:58:14.674: INFO: Creating a PV followed by a PVC
  STEP: Listing all PVs with the labelSelector: "e2e-pv-pool=pv-4499" @ 07/31/23 13:58:14.721
  STEP: Listing PVCs in namespace "pv-4499" @ 07/31/23 13:58:14.725
  STEP: Patching the PV "pv-4499-cpvlq" @ 07/31/23 13:58:14.73
  STEP: Patching the PVC "pvc-r7lsv" @ 07/31/23 13:58:14.776
  STEP: Getting PV "pv-4499-cpvlq" @ 07/31/23 13:58:14.797
  STEP: Getting PVC "pvc-r7lsv" @ 07/31/23 13:58:14.801
  STEP: Deleting PVC "pvc-r7lsv" @ 07/31/23 13:58:14.809
  STEP: Confirm deletion of PVC "pvc-r7lsv" @ 07/31/23 13:58:14.819
  STEP: Deleting PV "pv-4499-cpvlq" @ 07/31/23 13:58:15.825
  STEP: Confirm deletion of PV "pv-4499-cpvlq" @ 07/31/23 13:58:15.85
  STEP: Recreating another PV & PVC @ 07/31/23 13:58:16.855
  Jul 31 13:58:16.855: INFO: Creating a PV followed by a PVC
  STEP: Updating the PV "pv-4499-hrfvs" @ 07/31/23 13:58:16.894
  STEP: Updating the PVC "pvc-kplcf" @ 07/31/23 13:58:16.916
  STEP: Listing PVCs in all namespaces with the labelSelector: "pvc-kplcf=updated" @ 07/31/23 13:58:16.938
  STEP: Deleting PVC "pvc-kplcf" via DeleteCollection @ 07/31/23 13:58:16.943
  STEP: Confirm deletion of PVC "pvc-kplcf" @ 07/31/23 13:58:16.959
  STEP: Deleting PV "pv-4499-hrfvs" via DeleteCollection @ 07/31/23 13:58:17.964
  STEP: Confirm deletion of PV "pv-4499-hrfvs" @ 07/31/23 13:58:17.982
```


# Verifying increase in coverage with APISnoop


## Listing endpoints hit by the new e2e test

This query shows the following PV and PVC endpoints are hit within a short period of running this e2e test.

```sql-mode
select distinct substring(endpoint from '\w+') AS endpoint,
                right(useragent,50) AS useragent
from testing.audit_event
where useragent like 'e2e%should%'
  and release_date::BIGINT > round(((EXTRACT(EPOCH FROM NOW()))::numeric)*1000,0) - 20000
  and endpoint ilike '%Volume%'
order by endpoint
limit 20;
```

```example
                       endpoint                        |                     useragent
-------------------------------------------------------+----------------------------------------------------
 createCoreV1NamespacedPersistentVolumeClaim           | should run through the lifecycle of a PV and a PVC
 createCoreV1PersistentVolume                          | should run through the lifecycle of a PV and a PVC
 deleteCoreV1CollectionNamespacedPersistentVolumeClaim | should run through the lifecycle of a PV and a PVC
 deleteCoreV1CollectionPersistentVolume                | should run through the lifecycle of a PV and a PVC
 deleteCoreV1NamespacedPersistentVolumeClaim           | should run through the lifecycle of a PV and a PVC
 deleteCoreV1PersistentVolume                          | should run through the lifecycle of a PV and a PVC
 listCoreV1NamespacedPersistentVolumeClaim             | should run through the lifecycle of a PV and a PVC
 listCoreV1PersistentVolume                            | should run through the lifecycle of a PV and a PVC
 listCoreV1PersistentVolumeClaimForAllNamespaces       | should run through the lifecycle of a PV and a PVC
 patchCoreV1NamespacedPersistentVolumeClaim            | should run through the lifecycle of a PV and a PVC
 patchCoreV1PersistentVolume                           | should run through the lifecycle of a PV and a PVC
 readCoreV1NamespacedPersistentVolumeClaim             | should run through the lifecycle of a PV and a PVC
 readCoreV1PersistentVolume                            | should run through the lifecycle of a PV and a PVC
 replaceCoreV1NamespacedPersistentVolumeClaim          | should run through the lifecycle of a PV and a PVC
 replaceCoreV1PersistentVolume                         | should run through the lifecycle of a PV and a PVC
(15 rows)

```


# Final notes

If a test with these calls gets merged, **test coverage will go up by 13 points**

This test is also created with the goal of conformance promotion.

---

/sig testing

/sig architecture

/area conformance