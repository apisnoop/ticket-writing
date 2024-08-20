# Progress <code>[1/6]</code>

-   [X] APISnoop org-flow : [CoreV1Node-LifecycleTest.org](https://github.com/apisnoop/ticket-writing/blob/master/CoreV1Node-LifecycleTest.org)
-   [ ] test approval issue : [!](https://issues.k8s.io/)
-   [ ] test pr : [!](https://pr.k8s.io/)
-   [ ] two weeks soak start date : [testgrid-link](https://testgrid.k8s.io/)
-   [ ] two weeks soak end date : xxxx-xx-xx
-   [ ] test promotion pr : [!](https://pr.k8s.io/)


# Identifying an untested feature Using APISnoop


## Untested Endpoints

According to following APIsnoop query, there are two Node endpoints that are untested.

```sql-mode
select   endpoint,
         path,
         kind
from     testing.untested_stable_endpoint
where    eligible is true
and      endpoint ilike '%V1Node'
order by kind, endpoint
limit    10;
```

```example
     endpoint     |         path         | kind
------------------+----------------------+------
 createCoreV1Node | /api/v1/nodes        | Node
 deleteCoreV1Node | /api/v1/nodes/{name} | Node
(2 rows)

```

-   <https://apisnoop.cncf.io/1.31.0/stable/core/createCoreV1Node>
-   <https://apisnoop.cncf.io/1.31.0/stable/core/deleteCoreV1Node>


# API Reference and feature documentation

-   [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/kubernetes-api/)
-   [Kubernetes API / Cluster Resources / Node](https://kubernetes.io/docs/reference/kubernetes-api/cluster-resources/node-v1/)
-   [client-go - Node](https://github.com/kubernetes/client-go/blob/master/kubernetes/typed/core/v1/node.go)


# Test outline

```
Scenario: Test the lifecycle of a Node

  Given the e2e test has created the settings for a Node
  When the test creates the Node
  Then the requested action is accepted without any error
  And the test confirms the name of the created Node

  Given the e2e test has created a Node
  When the test reads the Node
  Then the requested action is accepted without any error
  And the test confirms the name of the Node

  Given the e2e test has read a Node
  When the test patches the Node with a label
  Then the requested action is accepted without any error
  And the test confirms that the "patched" label is found

  Given the e2e test has patched a Node and created a "patched" LabelSelector
  When the test lists the Node with a "patched" labelSelector
  Then the requested action is accepted without any error
  And the retrieved list has a single item

  Given the e2e test has listed the Node
  When the test updates the Node with a label
  Then the requested action is accepted without any error
  And the test confirms that the "updated" label is found

  Given the e2e test has created a "updated" LabelSelector for the Node
  When the test deletes the Node
  Then the requested action is accepted without any error

  Given the e2e test has deleted the Node
  When the test lists for the Node with a "updated" labelSelector
  Then the requested action is accepted without any error
  And the deletion of the Node is confirmed

```


# E2E Test

Using a number of existing e2e test practices a new [ginkgo test](https://github.com/ii/kubernetes/blob/create-node-lifecycle-test/test/e2e/node/create.go#L46-L129) has been created to provide future Conformance coverage for the 2 endpoints. The e2e logs for this test are listed below.

```
[sig-node] Conformance should run through the lifecycle of a node [sig-node]
/home/ii/go/src/k8s.io/kubernetes/test/e2e/node/create.go:46
  STEP: Creating a kubernetes client @ 08/01/24 11:01:22.449
  I0801 11:01:22.449350 177288 util.go:499] >>> kubeConfig: /home/ii/.kube/config
  STEP: Building a namespace api object, basename fake-node @ 08/01/24 11:01:22.449
  STEP: Waiting for a default service account to be provisioned in namespace @ 08/01/24 11:01:22.471
  STEP: Waiting for kube-root-ca.crt to be provisioned in namespace @ 08/01/24 11:01:22.473
  STEP: Create "e2e-fake-node-gl9nr" @ 08/01/24 11:01:22.491
  STEP: Getting "e2e-fake-node-gl9nr" @ 08/01/24 11:01:22.497
  STEP: Patching "e2e-fake-node-gl9nr" @ 08/01/24 11:01:22.498
  STEP: Listing nodes with LabelSelector "e2e-fake-node-gl9nr=patched" @ 08/01/24 11:01:22.504
  STEP: Updating "e2e-fake-node-gl9nr" @ 08/01/24 11:01:22.509
  STEP: Delete "e2e-fake-node-gl9nr" @ 08/01/24 11:01:22.559
  STEP: Confirm deletion of "e2e-fake-node-gl9nr" @ 08/01/24 11:01:22.568
  I0801 11:01:22.572248 177288 helper.go:122] Waiting up to 7m0s for all (but 0) nodes to be ready
  STEP: Destroying namespace "create-fake-node-3185" for this suite. @ 08/01/24 11:01:22.576
```


# Verifying increase in coverage with APISnoop


## Listing endpoints hit by the new e2e test

This query shows the following Node endpoints are hit within a short period of running this e2e test.

```sql-mode
select distinct substring(endpoint from '\w+') AS endpoint,
                right(useragent,42) AS useragent
from  testing.audit_event
where useragent like 'e2e%should%'
  and release_date::BIGINT > round(((EXTRACT(EPOCH FROM NOW()))::numeric)*1000,0) - 20000
  and endpoint ilike '%Node%'
order by endpoint
limit 10;
```

```example
     endpoint      |                 useragent
-------------------+--------------------------------------------
 createCoreV1Node  | should run through the lifecycle of a node
 deleteCoreV1Node  | should run through the lifecycle of a node
 listCoreV1Node    | should run through the lifecycle of a node
 patchCoreV1Node   | should run through the lifecycle of a node
 readCoreV1Node    | should run through the lifecycle of a node
 replaceCoreV1Node | should run through the lifecycle of a node
(6 rows)

```


# Final notes

If a test with these calls gets merged, **test coverage will go up by 2 points**

This test is also created with the goal of conformance promotion.

---

/sig testing

/sig architecture

/area conformance