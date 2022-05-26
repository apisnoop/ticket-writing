# Progress <code>[1/6]</code>

-   [X] APISnoop org-flow: [Corev1APIServiceLifecycleTest.org](https://github.com/apisnoop/ticket-writing/blob/master/Corev1APIServiceLifecycleTest.org)
-   [ ] Test approval issue: [#](https://issues.k8s.io/)
-   [ ] Test PR: [!](https://pr.k8s.io/)
-   [ ] Two weeks soak start date: [testgrid-link](https://testgrid.k8s.io/)
-   [ ] Two weeks soak end date:
-   [ ] Test promotion PR: [!](https://pr.k8s.io/)


# Identifying an untested feature Using APISnoop

According to this APIsnoop query, there are still some remaining APIService endpoints which are untested.

```sql-mode
    SELECT
      endpoint,
      path,
      kind
      FROM testing.untested_stable_endpoint
      where eligible is true
      and endpoint ilike '%APIService%'
      order by kind, endpoint desc
      limit 10;
```

```example
                    endpoint                   |                           path                            |    kind
  ---------------------------------------------+-----------------------------------------------------------+------------
   replaceApiregistrationV1APIServiceStatus    | /apis/apiregistration.k8s.io/v1/apiservices/{name}/status | APIService
   replaceApiregistrationV1APIService          | /apis/apiregistration.k8s.io/v1/apiservices/{name}        | APIService
   patchApiregistrationV1APIServiceStatus      | /apis/apiregistration.k8s.io/v1/apiservices/{name}/status | APIService
   deleteApiregistrationV1CollectionAPIService | /apis/apiregistration.k8s.io/v1/apiservices               | APIService
  (4 rows)

```


# API Reference and feature documentation

-   [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/kubernetes-api/)
-   [Kubernetes API > Cluster Resources > APIService](https://kubernetes.io/docs/reference/kubernetes-api/cluster-resources/api-service-v1/)
-   [client-go: apiregistration/v1/apiservice.go](https://github.com/kubernetes/kube-aggregator/blob/master/pkg/client/clientset_generated/clientset/typed/apiregistration/v1/apiservice.go#L39-L51)


# Test outline

```
Feature: Test deleteCollection, patch(Status), replace, replace(Status) APIService api endpoints
```

-   replaceApiregistrationV1APIServiceStatus

```
Scenario: confirm that the replace action will apply the changes to an APIService status
  Given the e2e test has created an APIService
  And a new status condition has been generated
  When the test updates the APIService status
  Then the requested action is accepted without any error
  And the new APIService status is found
```

-   patchApiregistrationV1APIServiceStatus

```
Scenario: confirm that the patch action will apply the changes to an APIService status
  Given the e2e test has an updated APIService status
  And a new status condition has been generated
  When the test patches the APIService status
  Then the requested action is accepted without any error
  And the new APIService status is found
```

-   replaceApiregistrationV1APIService

```
Scenario: confirm that the update action will apply the changes to an APIService
  Given the e2e test has a patched APIService status
  And a new label has been generated
  When the test updates the APIService
  Then the requested action is accepted without any error
  And the newly applied label is found
```

-   deleteApiregistrationV1CollectionAPIService

```
Scenario: confirm that the deleteCollection action will remove an APIService
  Given the e2e test has the updated APIService
  When the test applies the deleteCollection action with a labelSelector
  Then the requested action is accepted without any error
  And the APIService with the label is not found
```


# E2E Test

Using a number of existing e2e test practices a new [ginkgo test](https://github.com/ii/kubernetes/blob/create-apiservice-lifecycle-test/test/e2e/apimachinery/aggregator.go#L112-L226) has been created for 4 APIService endpoints. The e2e logs for this test are listed below.

```
[It] should manage the lifecycle of an APIService
  /home/ii/go/src/k8s.io/kubernetes/test/e2e/apimachinery/aggregator.go:112
May 26 12:14:56.783: INFO: ns: aggregator-6994
STEP: Create APIService v1alpha1.e2e-tvf79.example.com
STEP: Confirm that the generated APIService has been created
May 26 12:14:57.191: INFO: Requesting list of APIServices to confirm quantity
May 26 12:14:57.197: INFO: Found 1 APIService with label "e2e=e2e-tvf79"
STEP: Update status for APIService v1alpha1.e2e-tvf79.example.com
May 26 12:14:57.209: INFO: updatedStatus.Conditions: []v1.APIServiceCondition{v1.APIServiceCondition{Type:"Available", Status:"False", LastTransitionTime:time.Date(2022, time.May, 26, 12, 14, 57, 0, time.Local), Reason:"ServiceNotFound", Message:"service/e2e-api in \"aggregator-6994\" is not present"}, v1.APIServiceCondition{Type:"StatusUpdate", Status:"True", LastTransitionTime:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), Reason:"E2E", Message:"Set from e2e test"}}
STEP: Confirm that the generated APIService has an updated status
May 26 12:14:57.209: INFO: Get APIService "v1alpha1.e2e-tvf79.example.com" to confirm status
May 26 12:14:57.212: INFO: APIService "v1alpha1.e2e-tvf79.example.com" has the required status conditions
STEP: Patching status for APIService v1alpha1.e2e-tvf79.example.com
May 26 12:14:57.217: INFO: Patched status conditions: []v1.APIServiceCondition{v1.APIServiceCondition{Type:"StatusPatched", Status:"True", LastTransitionTime:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), Reason:"E2E", Message:"Set from e2e test"}}
STEP: Confirm that the generated APIService has been created
May 26 12:14:57.217: INFO: Get APIService "v1alpha1.e2e-tvf79.example.com" to confirm status
May 26 12:14:57.219: INFO: APIService "v1alpha1.e2e-tvf79.example.com" has the required status conditions
STEP: Replace APIService v1alpha1.e2e-tvf79.example.com
May 26 12:14:57.226: INFO: Found updated apiService label for "v1alpha1.e2e-tvf79.example.com"
STEP: DeleteCollection APIService v1alpha1.e2e-tvf79.example.com via labelSelector: e2e=e2e-tvf79
STEP: Confirm that the generated APIService has been deleted
May 26 12:14:57.387: INFO: Requesting list of APIServices to confirm quantity
May 26 12:14:57.586: INFO: Found 0 APIService with label "e2e=e2e-tvf79"
May 26 12:14:57.586: INFO: APIService v1alpha1.e2e-tvf79.example.com has been deleted.
```


# Verifying increase in coverage with APISnoop


## Listing endpoints hit by the new e2e test

This query shows the following endpoints are hit within a short period of running this e2e test

```sql-mode
select distinct  endpoint, right(useragent,44) AS useragent
from testing.audit_event
where endpoint ilike '%APIService%'
and release_date::BIGINT > round(((EXTRACT(EPOCH FROM NOW()))::numeric)*1000,0) - 60000
and useragent like 'e2e%should%'
order by endpoint
limit 10;
```

```example
                  endpoint                   |                  useragent
---------------------------------------------+----------------------------------------------
 createApiregistrationV1APIService           | should manage the lifecycle of an APIService
 deleteApiregistrationV1APIService           | should manage the lifecycle of an APIService
 deleteApiregistrationV1CollectionAPIService | should manage the lifecycle of an APIService
 listApiregistrationV1APIService             | should manage the lifecycle of an APIService
 patchApiregistrationV1APIServiceStatus      | should manage the lifecycle of an APIService
 readApiregistrationV1APIService             | should manage the lifecycle of an APIService
 replaceApiregistrationV1APIService          | should manage the lifecycle of an APIService
 replaceApiregistrationV1APIServiceStatus    | should manage the lifecycle of an APIService
(8 rows)

```


# Final notes

If a test with these calls gets merged, **test coverage will go up by 4 points**

This test is also created with the goal of conformance promotion.

---

/sig testing

/sig architecture

/area conformance
