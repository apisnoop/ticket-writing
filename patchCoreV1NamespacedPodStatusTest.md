# Progress <code>[1/6]</code>

-   [X] APISnoop org-flow : [patchCoreV1NamespacedPodStatusTest.org](https://github.com/apisnoop/ticket-writing/blob/master/patchCoreV1NamespacedPodStatusTest.org)
-   [ ] test approval issue : [#](https://issues.k8s.io/)
-   [ ] test pr : [!](https://pr.k8s.io/)
-   [ ] two weeks soak start date : [testgrid-link](https://testgrid.k8s.io/)
-   [ ] two weeks soak end date : xxxx-xx-xx
-   [ ] test promotion pr : [!](https://pr.k8s.io/)


# Identifying an untested feature Using APISnoop

The `patchCoreV1NamespacedPodStatus` endpoint as seen on the [apisnoop.cncf.io](https://apisnoop.cncf.io/1.24.0/stable/core/patchCoreV1NamespacedPodStatus?conformance-only=true) website is tested but not part of conformance. The APIsnoop query below shows that there is no conformance test for this endpoint.

```sql-mode
  select distinct
    endpoint,
    test_hit AS "e2e Test",
    conf_test_hit AS "Conformance Test"
  from public.audit_event
  where endpoint ilike 'patch%PodStatus'
  and useragent like '%e2e%'
  order by endpoint
  limit 1;
```

```example
              endpoint            | e2e Test | Conformance Test
  --------------------------------+----------+------------------
   patchCoreV1NamespacedPodStatus | t        | f
  (1 row)

```


# API Reference and feature documentation

-   [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/kubernetes-api/)
-   [Kubernetes API > Workload Resources > Pod](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/)
-   [client-go: core/v1/pod.go](https://github.com/kubernetes/client-go/blob/master/kubernetes/typed/core/v1/pod.go#L42-L58)


# Test outline

```
Feature: Test patch PodStatus api endpoint
```

-   patchCoreV1NamespacedPodStatus

```
Scenario: the test patches a pod status subresource
  Given the e2e test has a running pod
  And a valid payload has been created
  When the test patches the pod status subresource
  Then the requested action is accepted without any error
  And the applied status subresource is accepted
  And the newly applied changes are found
```


# E2E Test

Using a number of existing e2e test practices a new [ginkgo test](https://github.com/ii/kubernetes/blob/patch-pod-status-test/test/e2e/common/node/pods.go#L1074-L1115) has been created for this pod status endpoint. The e2e logs for this test are listed below.

```
[It] should patch a pod status
  /home/ii/go/src/k8s.io/kubernetes/test/e2e/common/node/pods.go:1059
STEP: Create a pod
Jun 22 10:51:22.936: INFO: Waiting up to 5m0s for pod "pod-28pmv" in namespace "pods-5830" to be "running"
Jun 22 10:51:22.957: INFO: Pod "pod-28pmv": Phase="Pending", Reason="", readiness=false. Elapsed: 21.06407ms
Jun 22 10:51:24.964: INFO: Pod "pod-28pmv": Phase="Running", Reason="", readiness=true. Elapsed: 2.027491772s
Jun 22 10:51:24.964: INFO: Pod "pod-28pmv" satisfied condition "running"
STEP: patching /status
Jun 22 10:51:24.999: INFO: Status Message: "Patched by e2e test" and Reason: "E2E"
```


# Verifying increase in coverage with APISnoop


## Listing endpoints hit by the updated e2e test

This query shows the pod status endpoints hit within a short period of running the e2e test.

```sql-mode
select distinct  endpoint, right(useragent,25) AS useragent
from testing.audit_event
where endpoint ilike '%PodStatus'
and release_date::BIGINT > round(((EXTRACT(EPOCH FROM NOW()))::numeric)*1000,0) - 60000
and useragent like 'e2e%should%'
order by endpoint
limit 5;
```

```example
            endpoint            |         useragent
--------------------------------+---------------------------
 patchCoreV1NamespacedPodStatus | should patch a pod status
(1 row)

```


# Final notes

If a test with these calls gets merged, test coverage will go up by 1 point.

This test is also created with the goal of conformance promotion.

---

/sig testing

/sig architecture

/area conformance
