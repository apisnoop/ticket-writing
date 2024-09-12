# Progress <code>[1/6]</code>

-   [X] APISnoop org-flow : [StorageV1CSINode-LifecycleTest.org](https://github.com/apisnoop/ticket-writing/blob/master/StorageV1CSINode-LifecycleTest.org)
-   [ ] test approval issue : [!](https://issues.k8s.io/)
-   [ ] test pr : [!](https://pr.k8s.io/)
-   [ ] two weeks soak start date : [testgrid-link](https://testgrid.k8s.io/)
-   [ ] two weeks soak end date : xxxx-xx-xx
-   [ ] test promotion pr : [!](https://pr.k8s.io/)


# Identifying an untested feature Using APISnoop


## Untested Endpoints

According to following APIsnoop query, there are six CSINode endpoints that are untested.

```sql-mode
select   endpoint,
         path,
         kind
from     testing.untested_stable_endpoint
where    eligible is true
and      endpoint ilike '%CSINode'
order by kind, endpoint
limit    10;
```

```example
             endpoint             |                  path                   |  kind
----------------------------------+-----------------------------------------+---------
 createStorageV1CSINode           | /apis/storage.k8s.io/v1/csinodes        | CSINode
 deleteStorageV1CollectionCSINode | /apis/storage.k8s.io/v1/csinodes        | CSINode
 deleteStorageV1CSINode           | /apis/storage.k8s.io/v1/csinodes/{name} | CSINode
 listStorageV1CSINode             | /apis/storage.k8s.io/v1/csinodes        | CSINode
 patchStorageV1CSINode            | /apis/storage.k8s.io/v1/csinodes/{name} | CSINode
 replaceStorageV1CSINode          | /apis/storage.k8s.io/v1/csinodes/{name} | CSINode
(6 rows)

```

-   <https://apisnoop.cncf.io/1.31.0/stable/storage/createStorageV1CSINode>
-   <https://apisnoop.cncf.io/1.31.0/stable/storage/deleteStorageV1CSINode>
-   <https://apisnoop.cncf.io/1.31.0/stable/storage/deleteStorageV1CollectionCSINode>
-   <https://apisnoop.cncf.io/1.31.0/stable/storage/listStorageV1CSINode>
-   <https://apisnoop.cncf.io/1.31.0/stable/storage/patchStorageV1CSINode>
-   <https://apisnoop.cncf.io/1.31.0/stable/storage/replaceStorageV1CSINode>


## Endpoints that are not Conformance tested

-   <https://apisnoop.cncf.io/1.31.0/stable/storage/readStorageV1CSINode>


# API Reference and feature documentation

-   [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/kubernetes-api/)
-   [Kubernetes API / Config and Storage Resources / CSINode](https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/csi-node-v1/)
-   [client-go - CSINode](https://github.com/kubernetes/client-go/blob/master/kubernetes/typed/storage/v1/csinode.go)


# Test outline

```
Scenario: Test the lifecycle of a CSINode

  Given the e2e test has created the settings for a Node
  When the test creates the Node
  Then the requested action is accepted without any error
  And the test confirms the name of the created Node

  Given the e2e test has created a Node
  When the test reads the Node
  Then the requested action is accepted without any error
  And the test confirms the name of the Node

  Given the e2e test has created the settings for a CSINode
  When the test creates the CSINode
  Then the requested action is accepted without any error
  And the test confirms the name of the created CSINode

  Given the e2e test has created a CSINode
  When the test reads the CSINode
  Then the requested action is accepted without any error
  And the test confirms the name of the read CSINode

  Given the e2e test has read a CSINode
  When the test patches the CSINode with a label
  Then the requested action is accepted without any error
  And the test confirms that the "patched" label is found

  Given the e2e test has patched a CSINode and created a "patched" LabelSelector
  When the test lists the CSINode with a "patched" labelSelector
  Then the requested action is accepted without any error
  And the retrieved list has a single item

  Given the e2e test has listed the CSINode
  When the test deletes the CSINode
  Then the requested action is accepted without any error

  Given the e2e test has deleted the CSINode
  When the test lists the CSINode with a "patched" labelSelector
  Then the requested action is accepted without any error
  And the deletion of the CSINode is confirmed

  Given the e2e test has confirmed the deletion of the CSINode
  When the test deletes the Node
  Then the requested action is accepted without any error

  Given the e2e test has deleted the Node
  When the test gets the Node
  Then the requested action is accepted without any error
  And the deletion of the Node is confirmed

  Given the e2e test has no Node
  When the test recreates a replacement Node
  Then the requested action is accepted without any error
  And the test confirms the name of the created Node

  Given the e2e test has no CSINode
  When the test recreates a replacement CSINode
  Then the requested action is accepted without any error
  And the test confirms the name of the created CSINode

  Given the e2e test has created a replacement CSINode
  When the test reads the CSINode
  Then the requested action is accepted without any error
  And the test confirms the name of the read CSINode

  Given the e2e test has read the replacement CSINode
  When the test updates the CSINode with a label
  Then the requested action is accepted without any error
  And the test confirms that the "updated" label is found

  Given the e2e test has created a "updated" LabelSelector for the replacement CSINode
  When the test applies the deleteCollection action with an "updated" labelSelector
  Then the requested action is accepted without any error

  Given the e2e test has deleted the replacement CSINode
  When the test lists the CSINode with an "updated" labelSelector
  Then the requested action is accepted without any error
  And the deletion of the CSINode is confirmed

  Given the e2e test has confirmed the deleted the replacement CSINode
  When the test deletes the Node
  Then the requested action is accepted without any error

  Given the e2e test has deleted the replacement Node
  When the test gets the replacement Node
  Then the requested action is accepted without any error
  And the deletion of the Node is confirmed
```


# E2E Test

Using a number of existing e2e test practices a new [ginkgo test](https://github.com/ii/kubernetes/blob/create-csinode-lifecycle-test/test/e2e/storage/csi_node.go#L45-L212) has been created to provide future Conformance coverage for the 7 endpoints. The e2e logs for this test are listed below.

```
[sig-storage] CSINodes CSI Conformance should run through the lifecycle of a csinode [sig-storage]
/home/ii/go/src/k8s.io/kubernetes/test/e2e/storage/csi_node.go:45
  STEP: Creating a kubernetes client @ 09/12/24 11:53:05.724
  I0912 11:53:05.724978 286994 util.go:502] >>> kubeConfig: /home/ii/.kube/config
  STEP: Building a namespace api object, basename csinodes @ 09/12/24 11:53:05.725
  STEP: Waiting for a default service account to be provisioned in namespace @ 09/12/24 11:53:05.748
  STEP: Waiting for kube-root-ca.crt to be provisioned in namespace @ 09/12/24 11:53:05.749
  STEP: Creating initial node "e2e-fake-node-9wncg" @ 09/12/24 11:53:05.763
  STEP: Getting initial node: "e2e-fake-node-9wncg" @ 09/12/24 11:53:05.772
  STEP: Creating initial csiNode "e2e-fake-node-9wncg" @ 09/12/24 11:53:05.775
  STEP: Getting initial csiNode "e2e-fake-node-9wncg" @ 09/12/24 11:53:05.784
  STEP: Patching initial csiNode: "e2e-fake-node-9wncg" @ 09/12/24 11:53:05.787
  STEP: Listing csiNodes with LabelSelector "e2e-fake-node-9wncg=patched" @ 09/12/24 11:53:05.797
  STEP: Delete initial csiNode: "e2e-fake-node-9wncg" @ 09/12/24 11:53:05.81
  STEP: Confirm deletion of csiNode with LabelSelector "e2e-fake-node-9wncg=patched" @ 09/12/24 11:53:05.83
  STEP: Delete initial node "e2e-fake-node-9wncg" @ 09/12/24 11:53:05.833
  STEP: Confirm deletion of node "e2e-fake-node-9wncg" @ 09/12/24 11:53:05.842
  STEP: Creating replacement node "e2e-fake-node-gvm52" @ 09/12/24 11:53:05.846
  STEP: Getting replacement node: "e2e-fake-node-gvm52" @ 09/12/24 11:53:05.854
  STEP: Creating replacement csiNode "e2e-fake-node-gvm52" @ 09/12/24 11:53:05.858
  STEP: Getting replacement csiNode "e2e-fake-node-gvm52" @ 09/12/24 11:53:05.868
  STEP: Updating replacement csiNode "e2e-fake-node-gvm52" @ 09/12/24 11:53:05.875
  STEP: DeleteCollection of CSINodes with "e2e-fake-node-gvm52=updated" label @ 09/12/24 11:53:05.886
  STEP: Confirm deletion of replacement csiNode with LabelSelector "e2e-fake-node-gvm52=updated" @ 09/12/24 11:53:05.902
  STEP: Delete replacement node "e2e-fake-node-gvm52" @ 09/12/24 11:53:05.906
  STEP: Confirm deletion of replacement node "e2e-fake-node-gvm52" @ 09/12/24 11:53:05.915
  I0912 11:53:05.919018 286994 helper.go:122] Waiting up to 7m0s for all (but 0) nodes to be ready
  STEP: Destroying namespace "csinodes-5354" for this suite. @ 09/12/24 11:53:05.922
```


# Verifying increase in coverage with APISnoop


## Listing endpoints hit by the new e2e test

This query shows the following CSINode endpoints are hit within a short period of running this e2e test.

```sql-mode
select distinct substring(endpoint from '\w+') AS endpoint,
                right(useragent,45) AS useragent
from  testing.audit_event
where useragent like 'e2e%should%'
  and release_date::BIGINT > round(((EXTRACT(EPOCH FROM NOW()))::numeric)*1000,0) - 20000
  and endpoint ilike '%CSINode%'
order by endpoint
limit 10;
```

```example
             endpoint             |                   useragent
----------------------------------+-----------------------------------------------
 createStorageV1CSINode           | should run through the lifecycle of a csinode
 deleteStorageV1CollectionCSINode | should run through the lifecycle of a csinode
 deleteStorageV1CSINode           | should run through the lifecycle of a csinode
 listStorageV1CSINode             | should run through the lifecycle of a csinode
 patchStorageV1CSINode            | should run through the lifecycle of a csinode
 readStorageV1CSINode             | should run through the lifecycle of a csinode
 replaceStorageV1CSINode          | should run through the lifecycle of a csinode
(7 rows)

```


# Final notes

If a test with these calls gets merged, **test coverage will go up by 6 points**

This test is also created with the goal of conformance promotion.

---

/sig testing

/sig architecture

/area conformance