# Progress <code>[1/6]</code>

- [x] APISnoop org-flow : [patchCoreV1NamespacedPodStatus.org](https://github.com/apisnoop/ticket-writing/blob/master/patchCoreV1NamespacedPodStatus.org)
- [ ] test approval issue : [#](https://issues.k8s.io/)
- [ ] test pr : [!](https://pr.k8s.io/)
- [ ] two weeks soak start date : [testgrid-link](https://testgrid.k8s.io/)
- [ ] two weeks soak end date : xxxx-xx-xx
- [ ] test promotion pr : [!](https://pr.k8s.io/)

# Identifying an untested feature Using APISnoop

The `patchCoreV1NamespacedPodStatus` endpoint as seen on the [apisnoop.cncf.io](https://apisnoop.cncf.io/1.24.0/stable/core/patchCoreV1NamespacedPodStatus?conformance-only=true) website is tested but not part of conformance. The APIsnoop query below shows the current e2e tests that hit this endpoint.

```sql-mode
  select distinct  endpoint, right(useragent,68) AS useragent
  from public.audit_event
  where endpoint ilike 'patch%PodStatus'
  and useragent like '%e2e%'
  order by endpoint
  limit 10;
```

```example
              endpoint            |                              useragent
  --------------------------------+----------------------------------------------------------------------
   patchCoreV1NamespacedPodStatus |  -- [sig-api-machinery] ServerSideApply should work for subresources
   patchCoreV1NamespacedPodStatus | [sig-node] Pods should support pod readiness gates [NodeConformance]
  (2 rows)

```

The [sig-api-machinery test](https://github.com/kubernetes/kubernetes/blob/d5263feb038825197ab426237b111086822366be/test/e2e/apimachinery/apply.go#L162-L263) will be reviewed and checked to see that it meets the [requirements for promotion to conformance](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-architecture/conformance-tests.md#conformance-test-requirements).

# API Reference and feature documentation

- [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/kubernetes-api/)
- [client-go](https://github.com/kubernetes/client-go/blob/master/kubernetes/typed/core/v1/)

# Review current e2e test

The general structure and methods of testing the Pod `/status` subresource looks to be okay. One minor issue that has been noticed is the image used for this test is the standard `nginx` image. The current image can be swapped for a standard e2e image with only a [small change](https://github.com/ii/kubernetes/commit/994191044262b15c75f37d0ff91e90f414f223e1).

# Verifying increase in coverage with APISnoop

## Listing endpoints hit by the updated e2e test

This query shows the endpoints hit within a short period of running the e2e test.

```sql-mode
select distinct  endpoint, right(useragent,44) AS useragent
from testing.audit_event
where endpoint ilike '%'
and release_date::BIGINT > round(((EXTRACT(EPOCH FROM NOW()))::numeric)*1000,0) - 60000
and useragent like 'e2e%should%'
order by endpoint
limit 15;
```

```example
              endpoint              |                  useragent
------------------------------------+----------------------------------------------
 createCoreV1Namespace              | ServerSideApply should work for subresources
 createCoreV1NamespacedPod          | ServerSideApply should work for subresources
 deleteAppsV1NamespacedDeployment   | ServerSideApply should work for subresources
 deleteCoreV1Namespace              | ServerSideApply should work for subresources
 deleteCoreV1NamespacedPod          | ServerSideApply should work for subresources
 listCoreV1NamespacedConfigMap      | ServerSideApply should work for subresources
 listCoreV1NamespacedServiceAccount | ServerSideApply should work for subresources
 listCoreV1Node                     | ServerSideApply should work for subresources
 listPolicyV1beta1PodSecurityPolicy | ServerSideApply should work for subresources
 patchCoreV1NamespacedPod           | ServerSideApply should work for subresources
 patchCoreV1NamespacedPodStatus     | ServerSideApply should work for subresources
 readCoreV1NamespacedPod            | ServerSideApply should work for subresources
(12 rows)

```

# Final notes

These changes to the test are made with the goal of conformance promotion. After promotion to conformance the current **test coverage will go up by 1 points**.

---

/sig testing

/sig architecture

/area conformance
