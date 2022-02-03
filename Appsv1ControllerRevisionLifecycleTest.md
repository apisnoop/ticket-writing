# Progress <code>[1/6]</code>

- [x] APISnoop org-flow: [Appsv1ControllerRevisionLifecycleTest.org](https://github.com/apisnoop/ticket-writing/blob/master/Appsv1ControllerRevisionLifecycleTest.org)
- [ ] Test approval issue: [#](https://issues.k8s.io/)
- [ ] Test PR: [!](https://pr.k8s.io/)
- [ ] Two weeks soak start date: [testgrid-link](https://testgrid.k8s.io/)
- [ ] Two weeks soak end date:
- [ ] Test promotion PR: [!](https://pr.k8s.io/)

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

- [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/kubernetes-api/)
- [Kubernetes API > Workload Resources > Controller Revision](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/controller-revision-v1/)
- [client-go: apps/v1/controllerrevision.go](https://github.com/kubernetes/client-go/blob/master/kubernetes/typed/apps/v1/controllerrevision.go#L42-L54)

# Research

Diary notes: [Conformance testing Controller Revision endpoints](https://github.com/apisnoop/ticket-writing/blob/diary/diary/controllerrevision.org)

# The mock test

## Test outline (WIP)

Note: The outline covers the following endpoints only; `listAppsV1ControllerRevisionForAllNamespaces`, `readAppsV1NamespacedControllerRevision`

```
Feature: Test all current untested Controller Revision endpoints

Scenario: the test lists controller revisions in all namespaces
  Given the e2e test has as a running daemonset
  When the test requests all controller revisions by a label selector in all namespaces
  Then the test must receive a list controller revisions that is not nil

Scenario: the test reads a controller revision
  Given the e2e test has a list of controller revisions
  When the test reads a controller revision
  Then the test must return a controller revision that matches the controller revision for the running daemonset which is not nil
```

## Test the functionality in Go

Exploratory e2e test code: [ii/kubernetes&#x2026;/apps/controller<sub>revision.go</sub>](https://github.com/ii/kubernetes/blob/controller-revisions/test/e2e/apps/controller_revision.go)

# Verifying increase in coverage with APISnoop

## Listing endpoints hit by the new e2e test

This query shows the following endpoints are hit within a short period of running this e2e test

```sql-mode
select distinct  endpoint, right(useragent,58) AS useragent
from testing.audit_event
where endpoint ilike '%ControllerRevision%'
and release_date::BIGINT > round(((EXTRACT(EPOCH FROM NOW()))::numeric)*1000,0) - 60000
and useragent like 'e2e%should%'
order by endpoint
limit 10;
```

```example
                   endpoint                   |                         useragent
----------------------------------------------+------------------------------------------------------------
 listAppsV1ControllerRevisionForAllNamespaces | [Serial] should test the lifecycle of a ControllerRevision
 readAppsV1NamespacedControllerRevision       | [Serial] should test the lifecycle of a ControllerRevision
(2 rows)

```

# Final notes

If a test with these calls gets merged, **test coverage will go up by x points**

This test is also created with the goal of conformance promotion.

---

/sig testing

/sig architecture

/area conformance
