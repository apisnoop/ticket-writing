# Progress <code>[1/6]</code>

-   [X] APISnoop org-flow : [Read-Patch-Status-for-APIService-Test.org](https://github.com/apisnoop/ticket-writing/blob/master/Read-Patch-Status-for-APIService-Test.org)
-   [ ] test approval issue : [kubernetes/kubernetes#](https://github.com/kubernetes/kubernetes/issues/)
-   [ ] test pr : kuberenetes/kubernetes#
-   [ ] two weeks soak start date : testgrid-link
-   [ ] two weeks soak end date :
-   [ ] test promotion pr : kubernetes/kubernetes#?

# Identifying an untested feature Using APISnoop

According to this APIsnoop query, there are still some remaining APIService endpoints which are untested.

With this query you can filter untested endpoints by their category and eligiblity for conformance. e.g below shows a query to find all conformance eligible untested,stable,core endpoints

```sql-mode
SELECT
  endpoint,
  -- k8s_action,
  path,
  -- description,
  kind
  FROM testing.untested_stable_endpoint
  where eligible is true
  -- and category = 'core'
  and endpoint ilike '%APIService%'
  order by kind, endpoint desc
  limit 10;
```

```example
                  endpoint                   |                           path                            |    kind
---------------------------------------------|-----------------------------------------------------------|------------
 replaceApiregistrationV1APIServiceStatus    | /apis/apiregistration.k8s.io/v1/apiservices/{name}/status | APIService
 replaceApiregistrationV1APIService          | /apis/apiregistration.k8s.io/v1/apiservices/{name}        | APIService
 readApiregistrationV1APIServiceStatus       | /apis/apiregistration.k8s.io/v1/apiservices/{name}/status | APIService
 patchApiregistrationV1APIServiceStatus      | /apis/apiregistration.k8s.io/v1/apiservices/{name}/status | APIService
 patchApiregistrationV1APIService            | /apis/apiregistration.k8s.io/v1/apiservices/{name}        | APIService
 listApiregistrationV1APIService             | /apis/apiregistration.k8s.io/v1/apiservices               | APIService
 deleteApiregistrationV1CollectionAPIService | /apis/apiregistration.k8s.io/v1/apiservices               | APIService
(7 rows)

```

Addressing the following endpoints in this document;

-   [readApiregistrationV1APIServiceStatus](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.20/#read-status-apiservice-v1-apiregistration-k8s-io)
-   [patchApiregistrationV1APIService](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.20/#patch-apiservice-v1-apiregistration-k8s-io)
-   [listApiregistrationV1APIService](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.20/#list-apiservice-v1-apiregistration-k8s-io)

# API Reference and feature documentation

-   [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/kubernetes-api/)
-   [client-go](https://github.com/kubernetes/client-go/blob/master/kubernetes/typed/core/v1)

# The test

## Test outline

1.  Using the current e2e test as a template, create an APIService for `v1beta1.wardle.example.com`

2.  Using the REST client, read the APIService status (readApiregistrationV1APIServiceStatus) and confirm the value of `Status.Conditions.Message`.

3.  Using the REST client, patch the APIService `versionPriority` (patchApiregistrationV1APIService) before confirming that it has been updated.

4.  Using the REST client, list all APIServices in the cluster (listApiregistrationV1APIService) before confirming that `v1beta1.wardle.example.com` can be found.

5.  Clean up APIService resources used by the test.

## Test the functionality in Go

Due to the complexity of setting up the resources for APIService we have used the current e2e test as template. It has been extended in a [new ginkgo test](https://github.com/ii/kubernetes/blob/f42c272cfc207a419f99ad5fd40d08aa2559f730/test/e2e/apimachinery/aggregator.go#L905-L938) for review.

# Verifying increase in coverage with APISnoop

## Listing endpoints hit by the new e2e test

This query shows the endpoints hit within a short period of running the e2e test

```sql-mode
select distinct  endpoint, right(useragent,82) AS useragent
from testing.audit_event
where endpoint ilike '%ApiregistrationV1APIService%'
and release_date::BIGINT > round(((EXTRACT(EPOCH FROM NOW()))::numeric)*1000,0) - 60000
and useragent like 'e2e%'
order by endpoint
limit 10;
```

```example
               endpoint                |                                     useragent
---------------------------------------|------------------------------------------------------------------------------------
 createApiregistrationV1APIService     | Should be able to support the 1.17 Sample API Server using the current Aggregator2
 deleteApiregistrationV1APIService     | Should be able to support the 1.17 Sample API Server using the current Aggregator2
 listApiregistrationV1APIService       | Should be able to support the 1.17 Sample API Server using the current Aggregator2
 patchApiregistrationV1APIService      | Should be able to support the 1.17 Sample API Server using the current Aggregator2
 readApiregistrationV1APIService       | Should be able to support the 1.17 Sample API Server using the current Aggregator2
 readApiregistrationV1APIServiceStatus | Should be able to support the 1.17 Sample API Server using the current Aggregator2
(6 rows)

```

## Endpoint coverage change:

Based on the initial APIsnoop query and the results listed above there are three new endpoints hit.

# Final notes

If a test with these calls gets merged, **test coverage will go up by 3 points**

This test is also created with the goal of conformance promotion.

---

/sig testing

/sig architecture

/area conformance
