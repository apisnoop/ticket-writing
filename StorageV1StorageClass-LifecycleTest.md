# Progress <code>[7/7]</code>

-   [X] APISnoop org-flow : [StorageV1StorageClass-LifecycleTest.org](https://github.com/apisnoop/ticket-writing/blob/master/StorageV1StorageClass-LifecycleTest.org)
-   [X] test approval issue : [Write e2e test for StorageClass Endpoints + 7 Endpoints #120470](https://issues.k8s.io/120470)
-   [X] test pr : [Write e2e test for StorageClass Endpoints + 7 Endpoints #120471](https://pr.k8s.io/120471)
-   [X] two weeks soak start date : 8 Sept 2023 [testgrid-link](https://testgrid.k8s.io/sig-release-master-blocking#gce-cos-master-default&width=5&graph-metrics=test-duration-minutes&include-filter-by-regex=should.run.through.the.lifecycle.of.a.StorageClass)
-   [X] two weeks soak end date : 22 Sept 2023
-   [X] test promotion pr : [Promote e2e test for StorageClass Endpoints + 7 Endpoints #120761](https://pr.k8s.io/120761)
-   [X] remove endpoints from [pending<sub>eligible</sub><sub>endpoints.yaml</sub>](https://github.com/kubernetes/kubernetes/blob/master/test/conformance/testdata/pending_eligible_endpoints.yaml) : [remove storageclass endpoints from pending<sub>eligible</sub><sub>endpoints.yaml</sub> #120762](https://github.com/kubernetes/kubernetes/pull/120762)


# Identifying an untested feature Using APISnoop


## Untested Endpoints

According to following APIsnoop query, there are three StorageClass endpoints that are untested.

```sql-mode
select   endpoint,
         path,
         kind
from     testing.untested_stable_endpoint
where    eligible is true
and      endpoint ilike '%StorageClass'
order by kind, endpoint
limit    10;
```

```example
               endpoint                |                     path                      |     kind
---------------------------------------+-----------------------------------------------+--------------
 deleteStorageV1CollectionStorageClass | /apis/storage.k8s.io/v1/storageclasses        | StorageClass
 patchStorageV1StorageClass            | /apis/storage.k8s.io/v1/storageclasses/{name} | StorageClass
 replaceStorageV1StorageClass          | /apis/storage.k8s.io/v1/storageclasses/{name} | StorageClass
(3 rows)

```

-   <https://apisnoop.cncf.io/1.27.0/stable/storage/deleteStorageV1CollectionStorageClass>
-   <https://apisnoop.cncf.io/1.27.0/stable/storage/patchStorageV1StorageClass>
-   <https://apisnoop.cncf.io/1.27.0/stable/storage/replaceStorageV1StorageClass>


## Endpoints that are not Conformance tested

-   <https://apisnoop.cncf.io/1.27.0/stable/storage/createStorageV1StorageClass>
-   <https://apisnoop.cncf.io/1.27.0/stable/storage/deleteStorageV1StorageClass>
-   <https://apisnoop.cncf.io/1.27.0/stable/storage/listStorageV1StorageClass>
-   <https://apisnoop.cncf.io/1.27.0/stable/storage/readStorageV1StorageClass>


# API Reference and feature documentation

-   [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/kubernetes-api/)
-   [Kubernetes API / Config and Storage Resources / StorageClass](https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/storage-class-v1/)
-   [client-go - StorageClass](https://github.com/kubernetes/client-go/blob/master/kubernetes/typed/storage/v1/storageclass.go)


# Test outline

```
Scenario: Test the lifecycle of a StorageClass

  Given the e2e test has created the settings for a StorageClass
  When the test creates the StorageClass
  Then the requested action is accepted without any error

  Given the e2e test has created the StorageClass
  When the test reads the StorageClass
  Then the requested action is accepted without any error

  Given the e2e test has retrived a StorageClass
  When the test patches the StorageClass with a new label
  Then the requested action is accepted without any error
  And the test finds the new StorageClass label with the required "patched" value

  Given the e2e test has patched the StorageClass
  When the test deletes the StorageClass
  Then the requested action is accepted without any error
  And the deletion of the StorageClass is confirmed

  Given the e2e test has no StorageClass
  When the test recreates a new StorageClass
  Then the requested action is accepted without any error

  Given the e2e test has created a StorageClass
  When the test updates the StorageClass label
  Then the requested action is accepted without any error
  And the test finds the StorageClass label with the required "updated" value

  Given the e2e test has created a LabelSelector for the StorageClass
  When the test lists the StorageClasses with a labelSelector
  Then the requested action is accepted without any error
  And the retrieved list has a single item

  Given the e2e test has updated a StorageClass
  When the test applies the deleteCollection action with a labelSelector
  Then the requested action is accepted without any error
  And the StorageClass with the label is not found
```


# E2E Test

Using a number of existing e2e test practices a new [ginkgo test](https://github.com/ii/kubernetes/blob/create-storageclass-lifecycle-test/test/e2e/storage/storageclass.go#L43-L159) has been created to provide future Conformance coverage for the 7 endpoints. The e2e logs for this test are listed below.

```
[sig-storage] StorageClasses CSI Conformance should run through the lifecycle of a StorageClass
/home/ii/go/src/k8s.io/kubernetes/test/e2e/storage/storageclass.go:43
  STEP: Creating a kubernetes client @ 09/05/23 23:48:05.729
  Sep  5 23:48:05.729: INFO: >>> kubeConfig: /home/ii/.kube/config
  STEP: Building a namespace api object, basename csi-storageclass @ 09/05/23 23:48:05.736
  STEP: Waiting for a default service account to be provisioned in namespace @ 09/05/23 23:48:05.758
  STEP: Waiting for kube-root-ca.crt to be provisioned in namespace @ 09/05/23 23:48:05.765
  STEP: Creating a StorageClass @ 09/05/23 23:48:05.772
  STEP: Get StorageClass "e2e-64xnx" @ 09/05/23 23:48:05.778
  STEP: Patching the StorageClass "e2e-64xnx" @ 09/05/23 23:48:05.783
  STEP: Delete StorageClass "e2e-64xnx" @ 09/05/23 23:48:05.79
  STEP: Confirm deletion of StorageClass "e2e-64xnx" @ 09/05/23 23:48:05.796
  STEP: Create a replacement StorageClass @ 09/05/23 23:48:05.801
  STEP: Updating StorageClass "e2e-v2-bg6gz" @ 09/05/23 23:48:05.806
  STEP: Listing all StorageClass with the labelSelector: "e2e-v2-bg6gz=updated" @ 09/05/23 23:48:05.817
  STEP: Deleting StorageClass "e2e-v2-bg6gz" via DeleteCollection @ 09/05/23 23:48:05.822
  STEP: Confirm deletion of StorageClass "e2e-v2-bg6gz" @ 09/05/23 23:48:05.83
  Sep  5 23:48:05.834: INFO: Waiting up to 7m0s for all (but 0) nodes to be ready
  STEP: Destroying namespace "csi-storageclass-7858" for this suite. @ 09/05/23 23:48:05.841
```


# Verifying increase in coverage with APISnoop


## Listing endpoints hit by the new e2e test

This query shows the following StorageClass endpoints are hit within a short period of running this e2e test.

```sql-mode
select distinct substring(endpoint from '\w+') AS endpoint,
                right(useragent,50) AS useragent
from  testing.audit_event
where useragent like 'e2e%should%'
  and release_date::BIGINT > round(((EXTRACT(EPOCH FROM NOW()))::numeric)*1000,0) - 20000
  and endpoint ilike '%StorageClass%'
order by endpoint
limit 10;
```

```example
               endpoint                |                     useragent
---------------------------------------+----------------------------------------------------
 createStorageV1StorageClass           | should run through the lifecycle of a StorageClass
 deleteStorageV1CollectionStorageClass | should run through the lifecycle of a StorageClass
 deleteStorageV1StorageClass           | should run through the lifecycle of a StorageClass
 listStorageV1StorageClass             | should run through the lifecycle of a StorageClass
 patchStorageV1StorageClass            | should run through the lifecycle of a StorageClass
 readStorageV1StorageClass             | should run through the lifecycle of a StorageClass
 replaceStorageV1StorageClass          | should run through the lifecycle of a StorageClass
(7 rows)

```


# Final notes

If a test with these calls gets merged, **test coverage will go up by 7 points**

This test is also created with the goal of conformance promotion.

---

/sig testing

/sig architecture

/area conformance