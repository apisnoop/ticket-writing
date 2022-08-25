# Progress <code>[6/6]</code>

-   [X] APISnoop org-flow: [Appsv1ControllerRevisionLifecycleTest.org](https://github.com/apisnoop/ticket-writing/blob/master/Appsv1ControllerRevisionLifecycleTest.org)
-   [X] Test approval issue: [#110121](https://issues.k8s.io/110121)
-   [X] Test PR: [#110122](https://pr.k8s.io/110122)
-   [X] Two weeks soak start date: [8 July 2022](https://testgrid.k8s.io/sig-apps#gce-serial&width=20&include-filter-by-regex=should.manage.the.lifecycle.of.a.ControllerRevision)
-   [X] Two weeks soak end date: 22 July 2022
-   [X] Test promotion PR: [#111449](https://pr.k8s.io/111449)


# Identifying an untested feature Using APISnoop

According to this APIsnoop query, there are still some remaining Controller Revision endpoints which are untested.

```sql-mode
    SELECT
      endpoint,
      path,
      kind
      FROM testing.untested_stable_endpoint
      where eligible is true
      and endpoint ilike '%ControllerRevision%'
      order by kind, endpoint desc
      limit 10;
```

```example
                        endpoint                      |                              path                               |        kind
  ----------------------------------------------------+-----------------------------------------------------------------+--------------------
   replaceAppsV1NamespacedControllerRevision          | /apis/apps/v1/namespaces/{namespace}/controllerrevisions/{name} | ControllerRevision
   readAppsV1NamespacedControllerRevision             | /apis/apps/v1/namespaces/{namespace}/controllerrevisions/{name} | ControllerRevision
   patchAppsV1NamespacedControllerRevision            | /apis/apps/v1/namespaces/{namespace}/controllerrevisions/{name} | ControllerRevision
   listAppsV1ControllerRevisionForAllNamespaces       | /apis/apps/v1/controllerrevisions                               | ControllerRevision
   deleteAppsV1NamespacedControllerRevision           | /apis/apps/v1/namespaces/{namespace}/controllerrevisions/{name} | ControllerRevision
   deleteAppsV1CollectionNamespacedControllerRevision | /apis/apps/v1/namespaces/{namespace}/controllerrevisions        | ControllerRevision
   createAppsV1NamespacedControllerRevision           | /apis/apps/v1/namespaces/{namespace}/controllerrevisions        | ControllerRevision
  (7 rows)

```


# API Reference and feature documentation

-   [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/kubernetes-api/)
-   [Kubernetes API > Workload Resources > Controller Revision](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/controller-revision-v1/)
-   [client-go: apps/v1/controllerrevision.go](https://github.com/kubernetes/client-go/blob/master/kubernetes/typed/apps/v1/controllerrevision.go#L42-L54)


# Test outline

```
Feature: Test create, delete, deleteCollection, list(All Namespaces), patch, read and replace ControllerRevision api endpoints
```

-   listAppsV1ControllerRevisionForAllNamespaces

```
Scenario: confirm that the list(All Namespaces) action will find a list of controllerRevisions
  Given the e2e test has as a running daemonset
  When the test lists all controller revisions by a label selector in all namespaces
  Then the requested action is accepted without any error
  And a list of ControllerRevisions must be returned
```

-   readAppsV1NamespacedControllerRevision

```
Scenario: confirm that the read action will find the details of a single controllerRevision
  Given the e2e test has a list of controllerRevisions
  When the test reads a controllerRevision from the list of ControllerRevisions
  Then the requested action is accepted without any error
  And the controllerRevision returned is not nil
```

-   patchAppsV1NamespacedControllerRevision

```
Scenario: confirm that the patch action will apply a change to a controllerRevision
  Given the e2e test has the current controllerRevision for the DaemonSet
  And a payload has been created with a new label
  When the test applies the patch to the controllerRevision
  Then the requested action is accepted without any error
  And the newly applied label is found
```

-   createAppsV1NamespacedControllerRevision

```
Scenario: confirm that the create action will add a new controllerRevision
  Given the e2e test has the patched controllerRevision for the DaemonSet
  When the test creates a new controllerRevision
  Then the requested action is accepted without any error
  And two controllerRevisions are found
```

-   deleteAppsV1NamespacedControllerRevision

```
Scenario: confirm that the delete action will remove a controllerRevision
  Given the e2e test has the two controllerRevisions for the DaemonSet
  When the test deletes the initial controllerRevision
  Then the requested action is accepted without any error
  And only one controllerRevision is found
```

-   replaceAppsV1NamespacedControllerRevision

```
Scenario: confirm that the replace action will apply the changes to a controllerRevision
  Given the e2e test has a single controllerRevision for the DaemonSet
  When the test updates the controllerRevision label
  Then the requested action is accepted without any error
  And change to the label is found in the controllerRevision
```

-   deleteAppsV1CollectionNamespacedControllerRevision

```
Scenario: confirm that deleteCollection action will remove a controllerRevision
  Given the e2e test has the updated controllerRevision for the DaemonSet
  And a new controllerRevision is created after patching the DaemonSet
  When the test applies the deleteCollection action with a labelSelector
  Then the requested action is accepted without any error
  And only one controllerRevision is found
```


# E2E Test

Using a number of existing e2e test practices a new [ginkgo test](https://github.com/ii/kubernetes/blob/create-controller-revision-test/test/e2e/apps/controller_revision.go#L109-L225) has been created for 7 ControllerRevision endpoints. The e2e logs for this test are listed below.

```
[It] should manage the lifecycle of a ControllerRevision
  /home/ii/go/src/k8s.io/kubernetes/test/e2e/apps/controller_revision.go:109
STEP: Creating DaemonSet "e2e-cf8wj-daemon-set"
STEP: Check that daemon pods launch on every node of the cluster.
May 19 10:10:19.766: INFO: Number of nodes with available pods controlled by daemonset e2e-cf8wj-daemon-set: 0
May 19 10:10:19.766: INFO: Node e2e-cr-control-plane-qkhlk is running 0 daemon pod, expected 1
May 19 10:10:20.773: INFO: Number of nodes with available pods controlled by daemonset e2e-cf8wj-daemon-set: 0
May 19 10:10:20.773: INFO: Node e2e-cr-control-plane-qkhlk is running 0 daemon pod, expected 1
May 19 10:10:21.773: INFO: Number of nodes with available pods controlled by daemonset e2e-cf8wj-daemon-set: 0
May 19 10:10:21.773: INFO: Node e2e-cr-control-plane-qkhlk is running 0 daemon pod, expected 1
May 19 10:10:22.773: INFO: Number of nodes with available pods controlled by daemonset e2e-cf8wj-daemon-set: 1
May 19 10:10:22.773: INFO: Number of running nodes: 1, number of available pods: 1 in daemonset e2e-cf8wj-daemon-set
STEP: Confirm DaemonSet "e2e-cf8wj-daemon-set" successfully created with "daemonset-name=e2e-cf8wj-daemon-set" label
STEP: Listing all ControllerRevisions with label "daemonset-name=e2e-cf8wj-daemon-set"
May 19 10:10:22.782: INFO: Located ControllerRevision: "e2e-cf8wj-daemon-set-78d45fff97"
STEP: Patching ControllerRevision "e2e-cf8wj-daemon-set-78d45fff97"
May 19 10:10:22.789: INFO: e2e-cf8wj-daemon-set-78d45fff97 has been patched
STEP: Create a new ControllerRevision
May 19 10:10:22.792: INFO: Created ControllerRevision: e2e-cf8wj-daemon-set-bb6fd6fcbSTEP: Confirm that there are two ControllerRevisions
May 19 10:10:22.792: INFO: Requesting list of ControllerRevisions to confirm quantityMay 19 10:10:22.794: INFO: Found 2 ControllerRevisions
STEP: Deleting ControllerRevision "e2e-cf8wj-daemon-set-78d45fff97"
STEP: Confirm that there is only one ControllerRevision
May 19 10:10:22.796: INFO: Requesting list of ControllerRevisions to confirm quantity
May 19 10:10:22.798: INFO: Found 1 ControllerRevisions
STEP: Updating ControllerRevision "e2e-cf8wj-daemon-set-bb6fd6fcb"
May 19 10:10:22.805: INFO: e2e-cf8wj-daemon-set-bb6fd6fcb has been updated
STEP: Generate another ControllerRevision by patching the Daemonset
STEP: Confirm that there are two ControllerRevisions
May 19 10:10:22.809: INFO: Requesting list of ControllerRevisions to confirm quantity
May 19 10:10:23.811: INFO: Requesting list of ControllerRevisions to confirm quantity
May 19 10:10:23.816: INFO: Found 2 ControllerRevisions
STEP: Removing a ControllerRevision via 'DeleteCollection' with labelSelector: "e2e-cf8wj-daemon-set-bb6fd6fcb=updated"
STEP: Confirm that there is only one ControllerRevision
May 19 10:10:23.821: INFO: Requesting list of ControllerRevisions to confirm quantity
May 19 10:10:23.823: INFO: Found 1 ControllerRevisions
```


# Verifying increase in coverage with APISnoop


## Listing endpoints hit by the new e2e test

This query shows the following endpoints are hit within a short period of running this e2e test

```sql-mode
select distinct  endpoint, right(useragent,51) AS useragent
from testing.audit_event
where endpoint ilike '%ControllerRevision%'
and release_date::BIGINT > round(((EXTRACT(EPOCH FROM NOW()))::numeric)*1000,0) - 60000
and useragent like 'e2e%should%'
order by endpoint
limit 10;
```

```example
                      endpoint                      |                      useragent
----------------------------------------------------+-----------------------------------------------------
 createAppsV1NamespacedControllerRevision           | should manage the lifecycle of a ControllerRevision
 deleteAppsV1CollectionNamespacedControllerRevision | should manage the lifecycle of a ControllerRevision
 deleteAppsV1NamespacedControllerRevision           | should manage the lifecycle of a ControllerRevision
 listAppsV1ControllerRevisionForAllNamespaces       | should manage the lifecycle of a ControllerRevision
 listAppsV1NamespacedControllerRevision             | should manage the lifecycle of a ControllerRevision
 patchAppsV1NamespacedControllerRevision            | should manage the lifecycle of a ControllerRevision
 readAppsV1NamespacedControllerRevision             | should manage the lifecycle of a ControllerRevision
 replaceAppsV1NamespacedControllerRevision          | should manage the lifecycle of a ControllerRevision
(8 rows)

```


# Final notes

If a test with these calls gets merged, **test coverage will go up by 7 points**

This test is also created with the goal of conformance promotion.

---

/sig testing

/sig architecture

/area conformance
