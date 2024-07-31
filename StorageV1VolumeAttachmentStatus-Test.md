# Progress <code>[1/6]</code>

-   [X] APISnoop org-flow : [StorageV1VolumeAttachmentStatus-Test.org](https://github.com/apisnoop/ticket-writing/blob/master/StorageV1VolumeAttachmentStatus-Test.org)
-   [ ] test approval issue : [!](https://issues.k8s.io/)
-   [ ] test pr : [!](https://pr.k8s.io/)
-   [ ] two weeks soak start date : [testgrid-link](https://testgrid.k8s.io/)
-   [ ] two weeks soak end date : xxxx-xx-xx
-   [ ] test promotion pr : [!](https://pr.k8s.io/)


# Identifying an untested feature Using APISnoop


## Untested Endpoints

According to following APIsnoop query, there are three VolumeAttachmentStatus endpoints that are untested.

```sql-mode
select   endpoint,
         path,
         kind
from     testing.untested_stable_endpoint
where    eligible is true
and      endpoint ilike '%VolumeAttachmentStatus'
order by kind, endpoint
limit    20;
```

```example
                endpoint                |                          path                           |       kind
----------------------------------------+---------------------------------------------------------+------------------
 patchStorageV1VolumeAttachmentStatus   | /apis/storage.k8s.io/v1/volumeattachments/{name}/status | VolumeAttachment
 readStorageV1VolumeAttachmentStatus    | /apis/storage.k8s.io/v1/volumeattachments/{name}/status | VolumeAttachment
 replaceStorageV1VolumeAttachmentStatus | /apis/storage.k8s.io/v1/volumeattachments/{name}/status | VolumeAttachment
(3 rows)

```

-   <https://apisnoop.cncf.io/1.31.0/stable/storage/patchStorageV1VolumeAttachmentStatus>
-   <https://apisnoop.cncf.io/1.31.0/stable/storage/readStorageV1VolumeAttachmentStatus>
-   <https://apisnoop.cncf.io/1.31.0/stable/storage/replaceStorageV1VolumeAttachmentStatus>


# API Reference and feature documentation

-   [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/kubernetes-api/)
-   [Kubernetes API / Config and Storage Resources / VolumeAttachment](https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/volume-attachment-v1/)
-   [client-go - VolumeAttachment](https://github.com/kubernetes/client-go/blob/master/kubernetes/typed/storage/v1/volumeattachment.go)


# Test outline

```
Scenario: Apply changes to a VolumeAttachment Status

  Given the e2e test has created the settings for a VolumeAttachment
  When the test creates the VolumeAttachment
  Then the requested action is accepted without any error
  And the test confirms the name of the created VolumeAttachment

  Given the e2e test has created a VolumeAttachment
  When the test patches the VolumeAttachment with a label
  Then the requested action is accepted without any error
  And the test confirms that the "patched" label is found

  Given the e2e test has patched a VolumeAttachment
  When the test reads the VolumeAttachment status
  Then the requested action is accepted without any error
  And the test confirms the status of the VolumeAttachment

  Given the e2e test has read a VolumeAttachment status
  When the test patches the VolumeAttachment status
  Then the requested action is accepted without any error
  And the test confirms the new status

  Given the e2e test has patched the VolumeAttachment status
  When the test updates the VolumeAttachment status
  Then the requested action is accepted without any error
  And the test confirms the new status

  Given the e2e test has updated the VolumeAttachment status
  When the test deletes the VolumeAttachment
  Then the requested action is accepted without any error

  Given the e2e test has deleted the VolumeAttachment
  When the test lists for the VolumeAttachment with a "patched" labelSelector
  Then the requested action is accepted without any error
  And the deletion of the VolumeAttachment is confirmed
```


# E2E Test

Using a number of existing e2e test practices a new [ginkgo test](https://github.com/ii/kubernetes/blob/create-volume-attachment-status-test/test/e2e/storage/volume_attachment.go#L170-L259) has been created to provide future Conformance coverage for the 3 endpoints. The e2e logs for this test are listed below.

```
[sig-storage] VolumeAttachment Conformance should apply changes to a volumeattachment status [sig-storage]
/home/ii/go/src/k8s.io/kubernetes/test/e2e/storage/volume_attachment.go:170
  STEP: Creating a kubernetes client @ 07/31/24 12:27:23.94
  I0731 12:27:23.940415 361258 util.go:499] >>> kubeConfig: /home/ii/.kube/config
  STEP: Building a namespace api object, basename volumeattachment @ 07/31/24 12:27:23.941
  STEP: Waiting for a default service account to be provisioned in namespace @ 07/31/24 12:27:23.983
  STEP: Waiting for kube-root-ca.crt to be provisioned in namespace @ 07/31/24 12:27:23.987
  STEP: Create VolumeAttachment "va-e2e-f9xpk" on node "kind-control-plane" @ 07/31/24 12:27:23.994
  STEP: Patch VolumeAttachment "va-e2e-f9xpk" on node "kind-control-plane" @ 07/31/24 12:27:24.003
  STEP: Reading "va-e2e-f9xpk" Status @ 07/31/24 12:27:24.012
  STEP: Patching "va-e2e-f9xpk" Status @ 07/31/24 12:27:24.016
  I0731 12:27:24.025849 361258 volume_attachment.go:214] "va-e2e-f9xpk" Status.Attached: true
  STEP: Updating "va-e2e-f9xpk" Status @ 07/31/24 12:27:24.025
  I0731 12:27:24.042866 361258 volume_attachment.go:230] "va-e2e-f9xpk" Status.Attached: false
  STEP: Delete VolumeAttachment "va-e2e-f9xpk" on node "kind-control-plane" @ 07/31/24 12:27:24.042
  STEP: Confirm deletion of VolumeAttachment "va-e2e-f9xpk" on node "kind-control-plane" @ 07/31/24 12:27:24.052
  I0731 12:27:24.055592 361258 helper.go:122] Waiting up to 7m0s for all (but 0) nodes to be ready
  STEP: Destroying namespace "volumeattachment-2781" for this suite. @ 07/31/24 12:27:24.059
```


# Verifying increase in coverage with APISnoop


## Listing endpoints hit by the new e2e test

This query shows the following VolumeAttachmentStatus endpoints are hit within a short period of running this e2e test.

```sql-mode
select distinct substring(endpoint from '\w+') AS endpoint,
                right(useragent,49) AS useragent
from  testing.audit_event
where useragent like 'e2e%should%'
  and release_date::BIGINT > round(((EXTRACT(EPOCH FROM NOW()))::numeric)*1000,0) - 20000
  and endpoint ilike '%VolumeAttachmentStatus%'
order by endpoint
limit 10;
```

```example
                endpoint                |                     useragent
----------------------------------------+---------------------------------------------------
 patchStorageV1VolumeAttachmentStatus   | should apply changes to a volumeattachment status
 readStorageV1VolumeAttachmentStatus    | should apply changes to a volumeattachment status
 replaceStorageV1VolumeAttachmentStatus | should apply changes to a volumeattachment status
(3 rows)

```


# Final notes

If a test with these calls gets merged, **test coverage will go up by 3 points**

This test is also created with the goal of conformance promotion.

---

/sig testing

/sig architecture

/area conformance