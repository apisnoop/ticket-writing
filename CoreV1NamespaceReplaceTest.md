# Progress <code>[3/6]</code>

-   [X] APISnoop org-flow: [CoreV1NamespaceReplaceTest.org](https://github.com/apisnoop/ticket-writing/blob/master/CoreV1NamespaceReplaceTest.org)
-   [X] Test approval issue: [#111847](https://issues.k8s.io/111847)
-   [X] Test PR: [#111848](https://pr.k8s.io/111848)
-   [ ] Two weeks soak start date: [testgrid-link](https://testgrid.k8s.io/)
-   [ ] Two weeks soak end date:
-   [ ] Test promotion PR: [!](https://pr.k8s.io/)


# Identifying an untested feature Using APISnoop

According to this APIsnoop query, there are still a remaining Namespace endpoint which is untested.

```sql-mode
    SELECT
      endpoint,
      path,
      kind
      FROM testing.untested_stable_endpoint
      where eligible is true
      and endpoint ilike '%Namespace'
      order by kind, endpoint desc
      limit 10;
```

```example
          endpoint        |           path            |   kind
  ------------------------+---------------------------+-----------
   replaceCoreV1Namespace | /api/v1/namespaces/{name} | Namespace
  (1 row)

```


# API Reference and feature documentation

-   [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/kubernetes-api/)
-   [Kubernetes API / Cluster Resources / Namespace](https://kubernetes.io/docs/reference/kubernetes-api/cluster-resources/namespace-v1/)
-   [client-go - Namespace](https://github.com/kubernetes/client-go/blob/master/kubernetes/typed/core/v1/namespace.go)


# Test outline

```
Feature: Test replace Namespace api endpoint
```

-   replaceCoreV1Namespace

```
Scenario: confirm that the replace action will apply the changes to a Namespace
  Given the e2e test has created a Namespace
  And a new label has been generated
  When the test updates the Namespace
  Then the requested action is accepted without any error
  And the newly applied label is found
```


# E2E Test

Using a number of existing e2e test practices a new [ginkgo test](https://github.com/ii/kubernetes/blob/create-namespace-replace-test/test/e2e/apimachinery/namespace.go#L359-L377) has been created for 1 Namespace endpoint. The e2e logs for this test are listed below.

```
[It] should apply an update to a Namespace
  /home/heyste/go/src/k8s.io/kubernetes/test/e2e/apimachinery/namespace.go:286
STEP: Updating Namespace "namespaces-3021"
Jun  8 11:58:02.718: INFO: Namespace "namespaces-3021" now has labels, map[string]string{"e2e-framework":"namespaces", "e2e-run":"4d96a478-b803-4cb6-abc6-eb6019b556f7", "kubernetes.io/metadata.name":"namespaces-3021", "namespaces-3021":"updated", "pod-security.kubernetes.io/enforce":"baseline"}
```


# Verifying increase in coverage with APISnoop


## Listing endpoints hit by the new e2e test

This query shows the following endpoints are hit within a short period of running this e2e test

```sql-mode
select distinct  endpoint, right(useragent,37) AS useragent
from testing.audit_event
where endpoint ilike '%Namespace'
and release_date::BIGINT > round(((EXTRACT(EPOCH FROM NOW()))::numeric)*1000,0) - 60000
and useragent like 'e2e%should%'
order by endpoint
limit 10;
```

```example
        endpoint        |               useragent
------------------------+---------------------------------------
 createCoreV1Namespace  | should apply an update to a Namespace
 deleteCoreV1Namespace  | should apply an update to a Namespace
 readCoreV1Namespace    | should apply an update to a Namespace
 replaceCoreV1Namespace | should apply an update to a Namespace
(4 rows)

```


# Final notes

If a test with these calls gets merged, **test coverage will go up by 1 point**

This test is also created with the goal of conformance promotion.

---

/sig testing

/sig architecture

/area conformance
