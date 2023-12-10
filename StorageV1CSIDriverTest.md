# Progress <code>[8/8]</code>

-   [X] APISnoop org-flow : [StorageV1CSIDriverTest.org](https://github.com/apisnoop/ticket-writing/blob/master/StorageV1CSIDriverTest.org)
-   [X] test approval issue : [Write e2e test for StorageV1CSIDriver Endpoints + 3 Endpoints #118098](https://issues.k8s.io/118098)
-   [X] test pr : [Write e2e test for StorageV1CSIDriver Endpoints + 3 Endpoints #118099](https://pr.k8s.io/118099)
-   [X] two weeks soak start date : [testgrid-link](https://testgrid.k8s.io/sig-release-master-blocking#gce-cos-master-default&width=5&graph-metrics=test-duration-minutes&include-filter-by-regex=should.run.through.the.lifecycle.of.a.CSIDriver) 26 May 2023
-   [X] two weeks soak end date : 9 June 2023
-   [X] test promotion pr : [Promote test for StorageV1CSIDriver Endpoints + 3 Endpoints #118478](https://pr.k8s.io/118478)
-   [X] remove endpoints from [pending<sub>eligible</sub><sub>endpoints.yaml</sub>](https://github.com/kubernetes/kubernetes/blob/master/test/conformance/testdata/pending_eligible_endpoints.yaml) : [Remove csidriver endpoints from pending<sub>eligible</sub><sub>endpoints.yaml</sub> #118479](https://pr.k8s.io/118479)
-   [X] End of release 1.28 Release: Remove duplicate Conformance test that do not cover Patch, Replace, DeleteCollection.[Remove conformance test for StorageV1CSIDriver Endpoints #119025](https://github.com/kubernetes/kubernetes/pull/119025)


# Identifying an untested feature Using APISnoop

According to following APIsnoop query, there are still 3 CSIDriver endpoints that are not tested for Conformance.

```sql-mode
    SELECT
      endpoint,
      path,
      kind
      FROM testing.untested_stable_endpoint
      where eligible is true
      and endpoint ilike '%CSIDriver'
      order by kind, endpoint
      limit 10;
```

```example
                endpoint              |                   path                    |   kind
  ------------------------------------+-------------------------------------------+-----------
   deleteStorageV1CollectionCSIDriver | /apis/storage.k8s.io/v1/csidrivers        | CSIDriver
   patchStorageV1CSIDriver            | /apis/storage.k8s.io/v1/csidrivers/{name} | CSIDriver
   replaceStorageV1CSIDriver          | /apis/storage.k8s.io/v1/csidrivers/{name} | CSIDriver
  (3 rows)

```

-   <https://apisnoop.cncf.io/1.27.0/stable/storage/deleteStorageV1CollectionCSIDriver>
-   <https://apisnoop.cncf.io/1.27.0/stable/storage/patchStorageV1CSIDriver>
-   <https://apisnoop.cncf.io/1.27.0/stable/storage/replaceStorageV1CSIDriver>


# API Reference and feature documentation

-   [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/kubernetes-api/)
-   [Kubernetes API / Config and Storage Resources / CSIDriver](https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/csi-driver-v1/)
-   [client-go - CSIDriver](https://github.com/kubernetes/client-go/tree/master/kubernetes/typed/storage/v1/csidriver.go)


# Test outline

```
Scenario: Test the lifecycle of a CSI driver

  Given the e2e test has created two csi drivers
  When the test reads each csi driver
  Then the requested action is accepted without any error
  And for each retrieved driver the UID equals the created driver's UID

  Given the e2e test has created two csi drivers
  When the test patches a csi driver with a new label
  Then the requested action is accepted without any error
  And the retrieved driver has a label with a value of "patched"

  Given the e2e test has created two csi drivers
  When the test updates a csi driver label
  Then the requested action is accepted without any error
  And the retrieved driver has a label with a value of "updated"

  Given the e2e test has created two csi drivers
  When the test lists all the csi drivers with a label
  Then the requested action is accepted without any error
  And the retrieved driverList has a length of two

  Given the e2e test has created two csi drivers
  When the test deletes a csi driver
  Then the requested action is accepted without any error
  And when that driver is subsequently read it is not found

  Given the e2e test has deleted one csi drivers
  When the test deletes the other csi driver via deleteCollection
  Then the requested action is accepted without any error
  And when that driver is subsequently read it is not found
```


# E2E Test

Using a number of existing e2e test practices a new [ginkgo test](https://github.com/ii/kubernetes/blob/create-csidriver-test/test/e2e/storage/csi_inline.go#L233-L346) has been created to address these 3 endpoints. The e2e logs for this test are listed below.

```
[sig-storage] CSIInlineVolumes should run through the lifecycle of a csiDriver
/home/ii/go/src/k8s.io/kubernetes/test/e2e/storage/csi_inline.go:233
  STEP: Creating a kubernetes client @ 05/18/23 09:03:47.527
  May 18 09:03:47.527: INFO: >>> kubeConfig: /home/ii/.kube/config
  STEP: Building a namespace api object, basename csiinlinevolumes @ 05/18/23 09:03:47.528
  STEP: Waiting for a default service account to be provisioned in namespace @ 05/18/23 09:03:47.554
  STEP: Waiting for kube-root-ca.crt to be provisioned in namespace @ 05/18/23 09:03:47.555
  STEP: Creating two CSIDrivers @ 05/18/23 09:03:47.557
  STEP: Getting "inline-driver-bbba5a5b-5180-47f5-87cc-6afdfb35f77a" & "inline-driver-d834159c-f7a2-4668-9501-48eb292adb5b" @ 05/18/23 09:03:47.578
  STEP: Patching the CSIDriver "inline-driver-d834159c-f7a2-4668-9501-48eb292adb5b" @ 05/18/23 09:03:47.581
  STEP: Updating the CSIDriver "inline-driver-d834159c-f7a2-4668-9501-48eb292adb5b" @ 05/18/23 09:03:47.621
  STEP: Listing all CSIDrivers with the labelSelector: "e2e-test=csiinlinevolumes-5332" @ 05/18/23 09:03:47.654
  STEP: Deleting csiDriver "inline-driver-bbba5a5b-5180-47f5-87cc-6afdfb35f77a" @ 05/18/23 09:03:47.658
  STEP: Confirm deletion of csiDriver "inline-driver-bbba5a5b-5180-47f5-87cc-6afdfb35f77a" @ 05/18/23 09:03:47.691
  STEP: Deleting csiDriver "inline-driver-d834159c-f7a2-4668-9501-48eb292adb5b" via DeleteCollection @ 05/18/23 09:03:47.695
  STEP: Confirm deletion of csiDriver "inline-driver-d834159c-f7a2-4668-9501-48eb292adb5b" @ 05/18/23 09:03:47.706
  May 18 09:03:47.709: INFO: Waiting up to 7m0s for all (but 0) nodes to be ready
  STEP: Destroying namespace "csiinlinevolumes-5332" for this suite. @ 05/18/23 09:03:47.713
```


# Verifying increase in coverage with APISnoop


## Listing endpoints hit by the new e2e test

This query shows the following csiDriver endpoints are hit within a short period of running this e2e test.

```sql-mode
select distinct substring(endpoint from '\w+') AS endpoint,
                right(useragent,47) AS useragent
from testing.audit_event
where useragent like 'e2e%should%'
  and release_date::BIGINT > round(((EXTRACT(EPOCH FROM NOW()))::numeric)*1000,0) - 20000
  and endpoint ilike '%CSIDriver%'
order by endpoint
limit 10;
```

```example
              endpoint              |                    useragent
------------------------------------+-------------------------------------------------
 createStorageV1CSIDriver           | should run through the lifecycle of a csiDriver
 deleteStorageV1CollectionCSIDriver | should run through the lifecycle of a csiDriver
 deleteStorageV1CSIDriver           | should run through the lifecycle of a csiDriver
 listStorageV1CSIDriver             | should run through the lifecycle of a csiDriver
 patchStorageV1CSIDriver            | should run through the lifecycle of a csiDriver
 readStorageV1CSIDriver             | should run through the lifecycle of a csiDriver
 replaceStorageV1CSIDriver          | should run through the lifecycle of a csiDriver
(7 rows)

```


# Final notes

If a test with these calls gets merged, **test coverage will go up by 3 points**

This test is also created with the goal of conformance promotion.

---

/sig testing

/sig architecture

/area conformance
