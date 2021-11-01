# Progress <code>[1/6]</code>

-   [X] APISnoop org-flow: [deleteCoreV1CollectionNamespacedService.org](https://github.com/apisnoop/ticket-writing/blob/master/deleteCoreV1CollectionNamespacedService.org)
-   [ ] Test approval issue: [#](https://issues.k8s.io/)
-   [ ] Test PR: [!](https://pr.k8s.io/)
-   [ ] Two weeks soak start date: [testgrid-link](https://testgrid.k8s.io/)
-   [ ] Two weeks soak end date:
-   [ ] Test promotion PR: [!](https://pr.k8s.io/)


# Identifying an untested feature Using APISnoop

According to this APIsnoop query, there are still a remaining Service endpoint which is untested.

```sql-mode
    SELECT
      endpoint,
      path,
      kind
      FROM testing.untested_stable_endpoint
      where eligible is true
      and kind = 'Service'
      order by kind, endpoint desc
      limit 10;
```

```example
                  endpoint                 |                  path                   |  kind
  -----------------------------------------+-----------------------------------------+---------
   deleteCoreV1CollectionNamespacedService | /api/v1/namespaces/{namespace}/services | Service
  (1 row)

```


# API Reference and feature documentation

-   [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/kubernetes-api/)
-   [Kubernetes API / Service Resources / Service](https://kubernetes.io/docs/reference/kubernetes-api/service-resources/service-v1/)
-   [client-go - Service](https://github.com/kubernetes/client-go/blob/master/kubernetes/typed/core/v1/service.go)
-   [dynamic client interface](https://github.com/kubernetes/client-go/blob/master/dynamic/interface.go)

A service resource didn&rsquo;t support `deleteCoreV1CollectionNamespacedService` endpoint until [PR96684](https://github.com/kubernetes/kubernetes/pull/96684/files) was merged.


# The mock test


## Test outline

1.  Create a watch to track service events

2.  Create a service with a static label.

3.  Confirm via the watch that the service was created.

4.  Delete the service via the service with the dynamic client with `DeleteCollection`.

5.  Confirm via the watch that the service was deleted.


## Test the functionality in Go

The above steps have been implemented in the follwing [ginkgo test](https://github.com/ii/kubernetes/blob/delete-service-collection/test/e2e/network/service.go#L2734-L2823).


# Verifying increase in coverage with APISnoop

This query shows all the endpoints hit within a short period of running the above e2e test

```sql-mode
select distinct  endpoint, right(useragent,47) AS useragent
from testing.audit_event
where endpoint ilike '%'
and release_date::BIGINT > round(((EXTRACT(EPOCH FROM NOW()))::numeric)*1000,0) - 10000
and useragent like '%e2e%'
order by endpoint
limit 10;
```

```example
                endpoint                 |                    useragent
-----------------------------------------+-------------------------------------------------
 createCoreV1Namespace                   | Services should delete a collection of services
 createCoreV1NamespacedService           | Services should delete a collection of services
 deleteCoreV1CollectionNamespacedService | Services should delete a collection of services
 deleteCoreV1Namespace                   | Services should delete a collection of services
 listCoreV1NamespacedService             | Services should delete a collection of services
 listCoreV1NamespacedServiceAccount      | Services should delete a collection of services
 listCoreV1Node                          | Services should delete a collection of services
 listCoreV1ServiceForAllNamespaces       | Services should delete a collection of services
 listPolicyV1beta1PodSecurityPolicy      | Services should delete a collection of services
(9 rows)

```


# Final notes

If a test with these calls gets merged, **test coverage will go up by 1 point**

This test is also created with the goal of conformance promotion.

---

/sig testing

/sig network

/area conformance
