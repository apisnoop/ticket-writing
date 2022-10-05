# Progress <code>[1/6]</code>

-   [X] APISnoop org-flow: [CoreV1NamespaceFinalizeTest.org](https://github.com/apisnoop/ticket-writing/blob/master/CoreV1NamespaceFinalizeTest.org)
-   [ ] Test approval issue: [#](https://issues.k8s.io/)
-   [ ] Test PR: [#](https://pr.k8s.io/)
-   [ ] Two weeks soak start date: [testgrid-link](https://testgrid.k8s.io/)
-   [ ] Two weeks soak end date:
-   [ ] Test promotion PR: [#](https://pr.k8s.io/)


# Identifying an untested feature Using APISnoop

According to this APIsnoop query, there are still one remaining Namespace endpoint which is untested.

```sql-mode
    SELECT
      endpoint,
      path,
      kind
      FROM testing.untested_stable_endpoint
      where eligible is true
      and endpoint ilike '%V1Namespace%'
      and endpoint not ilike '%Namespaced%'
      order by kind, endpoint desc
      limit 10;
```

```example
              endpoint            |                path                |   kind
  --------------------------------+------------------------------------+-----------
   replaceCoreV1NamespaceFinalize | /api/v1/namespaces/{name}/finalize | Namespace
  (1 row)

```


# API Reference and feature documentation

-   [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/kubernetes-api/)
-   [Kubernetes API / Cluster Resources / Namespace](https://kubernetes.io/docs/reference/kubernetes-api/cluster-resources/namespace-v1/)
-   [client-go - Namespace](https://github.com/kubernetes/client-go/blob/master/kubernetes/typed/core/v1/namespace.go)
-   [client-go - Namespace (Finalize)](https://github.com/kubernetes/client-go/blob/master/kubernetes/typed/core/v1/namespace_expansion.go#L32-L37)


# Test outline

```
Feature: Test the Namespace finalize subresource
```

-   replaceCoreV1NamespaceFinalize

```
Scenario: confirm that the finalize action will apply to a Namespace
  Given the e2e test has created a test Namespace
  And the Spec.Finalizer is appended with a fake finalizer
  When the test updates the finalize subresource
  Then the requested action is accepted without any error
  And the Spec.Finalizer count will equal two
```

Note: The test also removes the fake finalize from `Spec.Finalizer` before calling the finalize action on the test namespace a second time. This will allow the test framework to clean up all namespaces when the e2e finishes, else the test namespace will be stuck in the `Terminating` state.


# E2E Test

Using a number of existing e2e test practices a new [ginkgo test](https://github.com/ii/kubernetes/blob/create-namespace-finalizer-test/test/e2e/apimachinery/namespace.go#L386-L425) has been created for one Namespace endpoint. The e2e logs for this test are listed below.

```
[It] should apply a finalizer to a Namespace
  /home/ii/go/src/k8s.io/kubernetes/test/e2e/apimachinery/namespace.go:386
STEP: Creating namespace "e2e-ns-snwdg" 10/06/22 11:45:22.926
Oct  6 11:45:22.937: INFO: Namespace "e2e-ns-snwdg-7128" has []v1.FinalizerName{"kubernetes"}
STEP: Adding e2e finalizer to namespace "e2e-ns-snwdg-7128" 10/06/22 11:45:22.937
Oct  6 11:45:22.945: INFO: Namespace "e2e-ns-snwdg-7128" has []v1.FinalizerName{"kubernetes", "e2e.example.com/fakeFinalizer"}
STEP: Removing e2e finalizer from namespace "e2e-ns-snwdg-7128" 10/06/22 11:45:22.945
Oct  6 11:45:22.951: INFO: Namespace "e2e-ns-snwdg-7128" has []v1.FinalizerName{"kubernetes"}
```


# Verifying increase in coverage with APISnoop

This query shows that the Finalize endpoint is hit within a short period of running this e2e test

```sql-mode
select distinct substring(endpoint from '\w+') AS endpoint,
                right(useragent,39) AS useragent
from testing.audit_event
where endpoint ilike '%Finalize%'
and release_date::BIGINT > round(((EXTRACT(EPOCH FROM NOW()))::numeric)*1000,0) - 60000
and useragent like 'e2e%should%'
order by endpoint
limit 10;
```

```example
            endpoint            |                useragent
--------------------------------+-----------------------------------------
 replaceCoreV1NamespaceFinalize | should apply a finalizer to a Namespace
(1 row)

```


# Final notes

If a test with these calls gets merged, **test coverage will go up by 1 point**

This test is also created with the goal of conformance promotion.

---

/sig testing

/sig architecture

/area conformance
