# Progress <code>[1/6]</code>

-   [ ] APISnoop org-flow : [StorageV1VolumeAttachment-LifecycleTest.org](https://github.com/apisnoop/ticket-writing/blob/master/StorageV1VolumeAttachment-LifecycleTest.org)
-   [ ] test approval issue : [#](https://issues.k8s.io/)
-   [ ] test pr : [!](https://pr.k8s.io/)
-   [ ] two weeks soak start date : [testgrid-link](https://testgrid.k8s.io/)
-   [ ] two weeks soak end date : xxxx-xx-xx
-   [ ] test promotion pr : [!](https://pr.k8s.io/)


# Identifying an untested feature Using APISnoop


## Untested Endpoints

According to following APIsnoop query, there are six VolumeAttachment endpoints that are untested.

```sql-mode
select   endpoint,
         path,
         kind
from     testing.untested_stable_endpoint
where    eligible is true
and      endpoint ilike '%VolumeAttachment'
order by kind, endpoint
limit    10;
```

```example
                 endpoint                  |                       path                       |       kind
-------------------------------------------+--------------------------------------------------+------------------
 createStorageV1VolumeAttachment           | /apis/storage.k8s.io/v1/volumeattachments        | VolumeAttachment
 deleteStorageV1CollectionVolumeAttachment | /apis/storage.k8s.io/v1/volumeattachments        | VolumeAttachment
 deleteStorageV1VolumeAttachment           | /apis/storage.k8s.io/v1/volumeattachments/{name} | VolumeAttachment
 listStorageV1VolumeAttachment             | /apis/storage.k8s.io/v1/volumeattachments        | VolumeAttachment
 patchStorageV1VolumeAttachment            | /apis/storage.k8s.io/v1/volumeattachments/{name} | VolumeAttachment
 replaceStorageV1VolumeAttachment          | /apis/storage.k8s.io/v1/volumeattachments/{name} | VolumeAttachment
(6 rows)

```

-   <https://apisnoop.cncf.io/1.28.0/stable/storage/createStorageV1VolumeAttachment>
-   <https://apisnoop.cncf.io/1.28.0/stable/storage/deleteStorageV1CollectionVolumeAttachment>
-   <https://apisnoop.cncf.io/1.28.0/stable/storage/deleteStorageV1VolumeAttachment>
-   <https://apisnoop.cncf.io/1.28.0/stable/storage/listStorageV1VolumeAttachment>
-   <https://apisnoop.cncf.io/1.28.0/stable/storage/patchStorageV1VolumeAttachment>
-   <https://apisnoop.cncf.io/1.28.0/stable/storage/replaceStorageV1VolumeAttachment>


## Endpoints that are not Conformance tested

-   <https://apisnoop.cncf.io/1.28.0/stable/storage/readStorageV1VolumeAttachment>


# API Reference and feature documentation

-   [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/kubernetes-api/)
-   [Kubernetes API / Config and Storage Resources / VolumeAttachment](https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/volume-attachment-v1/)
-   [client-go - VolumeAttachment](https://github.com/kubernetes/client-go/blob/master/kubernetes/typed/storage/v1/volumeattachment.go)


# Test outline

```
Scenario: Test the lifecycle of a VolumeAttachment

  Given the e2e test has created the settings for a VolumeAttachment
  When the test creates the VolumeAttachment
  Then the requested action is accepted without any error
  And the test confirms the name of the created VolumeAttachment

  Given the e2e test has created a VolumeAttachment
  When the test reads the VolumeAttachment
  Then the requested action is accepted without any error
  And the test confirms the name of the read VolumeAttachment

  Given the e2e test has read a VolumeAttachment
  When the test patches the VolumeAttachment with a label
  Then the requested action is accepted without any error
  And the test confirms that the "patched" label is found

  Given the e2e test has patched a VolumeAttachment and created a "patched" LabelSelector
  When the test lists the VolumeAttachment with a "patched" labelSelector
  Then the requested action is accepted without any error
  And the retrieved list has a single item

  Given the e2e test has listed the VolumeAttachment
  When the test deletes the VolumeAttachment
  Then the requested action is accepted without any error

  Given the e2e test has deleted the VolumeAttachment
  When the test lists for the VolumeAttachment with a "patched" labelSelector
  Then the requested action is accepted without any error
  And the deletion of the VolumeAttachment is confirmed

  Given the e2e test has no VolumeAttachment
  When the test recreates a new VolumeAttachment
  Then the requested action is accepted without any error

  Given the e2e test has created a replacement VolumeAttachment
  When the test updates the VolumeAttachment with a label
  Then the requested action is accepted without any error
  And the test confirms that the "updated" label is found

  Given the e2e test has created a "updated" LabelSelector for the VolumeAttachment
  When the test applies the deleteCollection action with a "updated" labelSelector
  Then the requested action is accepted without any error

  Given the e2e test has deleted the VolumeAttachment
  When the test lists for the VolumeAttachment with a "updated" labelSelector
  Then the requested action is accepted without any error
  And the deletion of the VolumeAttachment is confirmed

```


# E2E Test

Using a number of existing e2e test practices a new [ginkgo test](https://github.com/ii/kubernetes/blob/create-volume-attachment-lifecycle-test/test/e2e/storage/volume_attachment.go#L44-L159) has been created to provide future Conformance coverage for the 7 endpoints. The e2e logs for this test are listed below.

```
[sig-storage] VolumeAttachment Conformance should run through the lifecycle of a VolumeAttachment [sig-storage]
/home/ii/go/src/k8s.io/kubernetes/test/e2e/storage/volume_attachment.go:44
  STEP: Creating a kubernetes client @ 11/28/23 10:11:48.55
  Nov 28 10:11:48.550: INFO: >>> kubeConfig: /home/ii/.kube/config
  STEP: Building a namespace api object, basename volumeattachment @ 11/28/23 10:11:48.55
  STEP: Waiting for a default service account to be provisioned in namespace @ 11/28/23 10:11:48.571
  STEP: Waiting for kube-root-ca.crt to be provisioned in namespace @ 11/28/23 10:11:48.576
  STEP: Create VolumeAttachment "va-e2e-bhfxw" on node "kind-worker" @ 11/28/23 10:11:48.596
  STEP: Get VolumeAttachment "va-e2e-bhfxw" on node "kind-worker" @ 11/28/23 10:11:48.605
  STEP: Patch VolumeAttachment "va-e2e-bhfxw" on node "kind-worker" @ 11/28/23 10:11:48.608
  STEP: List VolumeAttachments with "va-e2e-bhfxw=patched" label @ 11/28/23 10:11:48.617
  STEP: Delete VolumeAttachment "va-e2e-bhfxw" on node "kind-worker" @ 11/28/23 10:11:48.621
  STEP: Confirm deletion of VolumeAttachment "va-e2e-bhfxw" on node "kind-worker" @ 11/28/23 10:11:48.63
  STEP: Create replacement VolumeAttachment "va-e2e-llt5b" on node "kind-worker" @ 11/28/23 10:11:48.634
  STEP: Update the VolumeAttachment "va-e2e-llt5b" on node "kind-worker" @ 11/28/23 10:11:48.643
  STEP: DeleteCollection of VolumeAttachments with "va-e2e-bhfxw=updated" label @ 11/28/23 10:11:48.66
  STEP: Confirm deletion of VolumeAttachments with "va-e2e-bhfxw=updated" label @ 11/28/23 10:11:48.664
```


# Verifying increase in coverage with APISnoop


## Listing endpoints hit by the new e2e test

This query shows the following VolumeAttachment endpoints are hit within a short period of running this e2e test.

```sql-mode
select distinct substring(endpoint from '\w+') AS endpoint,
                right(useragent,55) AS useragent
from  testing.audit_event
where useragent like 'e2e%should%'
  and release_date::BIGINT > round(((EXTRACT(EPOCH FROM NOW()))::numeric)*1000,0) - 20000
  and endpoint ilike '%VolumeAttachment%'
order by endpoint
limit 10;
```

```example
                 endpoint                  |                        useragent
-------------------------------------------+---------------------------------------------------------
 createStorageV1VolumeAttachment           |  should run through the lifecycle of a VolumeAttachment
 deleteStorageV1CollectionVolumeAttachment |  should run through the lifecycle of a VolumeAttachment
 deleteStorageV1VolumeAttachment           |  should run through the lifecycle of a VolumeAttachment
 listStorageV1VolumeAttachment             |  should run through the lifecycle of a VolumeAttachment
 patchStorageV1VolumeAttachment            |  should run through the lifecycle of a VolumeAttachment
 readStorageV1VolumeAttachment             |  should run through the lifecycle of a VolumeAttachment
 replaceStorageV1VolumeAttachment          |  should run through the lifecycle of a VolumeAttachment
(7 rows)

```


# Final notes

If a test with these calls gets merged, **test coverage will go up by 7 points**

This test is also created with the goal of conformance promotion.

---

/sig testing

/sig architecture

/area conformance