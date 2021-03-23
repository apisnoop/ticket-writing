# Identifying an untested feature Using APISnoop

According to this APIsnoop query, there are still some remaining APIService endpoints which are untested.

```sql-mode
    SELECT
      endpoint,
      path,
      kind
      FROM testing.untested_stable_endpoint
      where eligible is true
      and endpoint ilike '%ServiceStatus'
      order by kind, endpoint desc
      limit 10;
```

```example
                   endpoint                 |                           path                            |    kind
  ------------------------------------------+-----------------------------------------------------------+------------
   replaceApiregistrationV1APIServiceStatus | /apis/apiregistration.k8s.io/v1/apiservices/{name}/status | APIService
   patchApiregistrationV1APIServiceStatus   | /apis/apiregistration.k8s.io/v1/apiservices/{name}/status | APIService
  (2 rows)

```


# API Reference and feature documentation

-   [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/kubernetes-api/)
-   [Kubernetes API / Cluster Resources / APIService](https://kubernetes.io/docs/reference/kubernetes-api/cluster-resources/api-service-v1/)
-   [client-go](https://github.com/kubernetes/client-go/blob/master/kubernetes/typed)


# The mock test


## Test outline

This test extends the current conformance test by confirming two APIService Status endpoints. After validating that [APIServiceList](https://github.com/kubernetes/kubernetes/blob/master/test/e2e/apimachinery/aggregator.go#L518-L537) endpoint has been tested the following steps are used to test the Status endpoints.

1.  Patch the APIService with a static label so a watch can reference the APIService later in the test.

2.  Create a watch and list the APIServices.

3.  Update the APIService Status with a new set of status conditions. Validate that the conditions are found via the watch.

4.  Patch the APIService Status with a new of status condition. Validate that the condition is found via the watch.

After completing the above steps the current conformance test starts to [delete test resources](https://github.com/kubernetes/kubernetes/blob/f8e55fe974331dcc528c2f2ac863bb72fd06b999/test/e2e/apimachinery/aggregator.go#L539-L541).


## Test the functionality in Go

Using the existing [conformance test](https://github.com/kubernetes/kubernetes/blob/f8e55fe974331dcc528c2f2ac863bb72fd06b999/test/e2e/apimachinery/aggregator.go#L539-L541) as a template to extend further in a new [ginkgo test](https://github.com/ii/kubernetes/blob/apiservice-status-endpoints/test/e2e/apimachinery/aggregator.go#L546-L670) which validates two new endpoints are hit.


# Verifying increase in coverage with APISnoop


## Listing endpoints hit by the new e2e test

This query shows the endpoints hit within a short period of running the e2e test

```sql-mode
select distinct  endpoint, right(useragent,95) AS useragent
from testing.audit_event
where endpoint ilike '%APIServiceStatus%'
and release_date::BIGINT > round(((EXTRACT(EPOCH FROM NOW()))::numeric)*1000,0) - 60000
and useragent like 'e2e%'
order by endpoint
limit 10;
```

```example
                 endpoint                 |                                            useragent
------------------------------------------+-------------------------------------------------------------------------------------------------
 patchApiregistrationV1APIServiceStatus   | Should be able to support the 1.17 Sample API Server using the current Aggregator [Conformance]
 readApiregistrationV1APIServiceStatus    | Should be able to support the 1.17 Sample API Server using the current Aggregator [Conformance]
 replaceApiregistrationV1APIServiceStatus | Should be able to support the 1.17 Sample API Server using the current Aggregator [Conformance]
(3 rows)

```


## Test Flake

When the test tries to delete the APIService resources the test will flake as shown below. Looking for suggestions on whats likely to be happening and how to best resolve the flake would be appreciated Adding a small delay to the test (~600 milliseconds) removes the flake.

    STEP: List APIServices
    Mar 23 14:36:39.181: INFO: Found v1alpha1.wardle.example.com in APIServiceList
    STEP: patch the APIService
    Mar 23 14:36:39.189: INFO: APIService labels: map[apiservice:patched]
    Mar 23 14:36:39.192: INFO: APIService labels: map[apiservice:patched]
    STEP: updating the APIService Status
    Mar 23 14:36:39.205: INFO: updatedStatus.Conditions: []v1.APIServiceCondition{v1.APIServiceCondition{Type:"Available", Status:"True", LastTransitionTime:v1.Time{Time:time.Ti$
    e{wall:0x0, ext:63752060197, loc:(*time.Location)(0x7508880)}}, Reason:"Passed", Message:"all checks passed"}, v1.APIServiceCondition{Type:"StatusUpdate", Status:"True", Las$
    TransitionTime:v1.Time{Time:time.Time{wall:0x0, ext:0, loc:(*time.Location)(nil)}}, Reason:"E2E", Message:"Set from e2e test"}}
    STEP: watching for the APIService to be updated
    Mar 23 14:36:39.206: INFO: Observed APIService v1alpha1.wardle.example.com with Labels: map[apiservice:patched] & Conditions: [{Available True 2021-03-23 14:36:37 +1300 NZDT
    Passed all checks passed} {StatusUpdate True 0001-01-01 00:00:00 +0000 UTC E2E Set from e2e test}]
    Mar 23 14:36:39.206: INFO: Found APIService v1alpha1.wardle.example.com with Labels: map[apiservice:patched] & Conditions: [{Available True 2021-03-23 14:36:37 +1300 NZDT Pa$
    sed all checks passed} {StatusUpdate True 0001-01-01 00:00:00 +0000 UTC E2E Set from e2e test}]Mar 23 14:36:39.206: INFO: APIService Status for v1alpha1.wardle.example.com has been updated
    STEP: Patch APIService Status
    STEP: watching for the APIService to be patched
    Mar 23 14:36:39.219: INFO: Observed APIService v1alpha1.wardle.example.com with Labels: map[apiservice:patched] & Conditions: [{Available True 2021-03-23 14:36:37 +1300 NZDT
    Passed all checks passed} {StatusUpdate True 0001-01-01 00:00:00 +0000 UTC E2E Set from e2e test}]
    Mar 23 14:36:39.219: INFO: Observed APIService v1alpha1.wardle.example.com with Labels: map[apiservice:patched] & Conditions: [{Available True 2021-03-23 14:36:37 +1300 NZDT
    Passed all checks passed} {StatusUpdate True 0001-01-01 00:00:00 +0000 UTC E2E Set from e2e test}]
    Mar 23 14:36:39.219: INFO: Found APIService v1alpha1.wardle.example.com with Labels: map[apiservice:patched] & Conditions: [{StatusPatched True 0001-01-01 00:00:00 +0000 UTC
     }]
    Mar 23 14:36:39.219: INFO: APIService Status for v1alpha1.wardle.example.com has been patched
    Mar 23 14:36:39.317: FAIL: deleting flunders([{map[apiVersion:wardle.example.com/v1alpha1 kind:Flunder metadata:map[creationTimestamp:2021-03-23T01:36:39Z name:dynamic-flund$
    r-798528446 namespace:aggregator-7668 resourceVersion:4 selfLink:/apis/wardle.example.com/v1alpha1/namespaces/aggregator-7668/flunders/dynamic-flunder-798528446 uid:158ebf58$
    3e21-4982-8424-fe0f5ead167f] spec:map[] status:map[]]}]) using dynamic client but received unexpected error:
    the server is currently unable to handle the request


# Final notes

If a test with these calls gets merged, **test coverage will go up by 2 points**

This test is also created with the goal of conformance promotion.

---

/sig testing

/sig architecture

/area conformance
