# Progress <code>[1/6]</code>

- [x] APISnoop org-flow: [APIServiceTest.org](https://github.com/apisnoop/ticket-writing/blob/master/APIServiceTest.org)
- [ ] Test approval issue: [kubernetes/kubernetes#](https://github.com/kubernetes/kubernetes/issues/#)
- [ ] Test PR: kuberenetes/kubernetes#
- [ ] Two weeks soak start date: testgrid-link
- [ ] Two weeks soak end date:
- [ ] Test promotion PR: kubernetes/kubernetes#?

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

This test will deal with the following endpoints;

- [replaceApiregistrationV1APIServiceStatus](https://kubernetes.io/docs/reference/kubernetes-api/cluster-resources/api-service-v1/#update-replace-status-of-the-specified-apiservice)
- [deleteApiregistrationV1CollectionAPIService](https://kubernetes.io/docs/reference/kubernetes-api/cluster-resources/api-service-v1/#deletecollection-delete-collection-of-apiservice)

# API Reference and feature documentation

- [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/kubernetes-api/)
- [Kubernetes API / Cluster Resources / APIService](https://kubernetes.io/docs/reference/kubernetes-api/cluster-resources/api-service-v1/)
- [client-go](https://github.com/kubernetes/client-go/blob/master/kubernetes/typed)

# The mock test

## Test outline

This test uses the current APIService test as a template to create a new APIService, v1beta1.wardle.example.com before testing the endpoints.

1.  Create a watch and list the APIServices with a label selector.

2.  Update the APIService Status with a new set of status conditions. Confirm that the conditions are found via the watch.

3.  Use `DeleteCollection` and a label selector to delete the APIService. Confirm that the deletion was successful.

## Test the functionality in Go

Using the existing [conformance test](https://github.com/kubernetes/kubernetes/blob/2495ec7f1152394dbf096976211f37b21a3e232d/test/e2e/apimachinery/aggregator.go#L99-L102) as a template to create a new [ginkgo test](https://github.com/ii/kubernetes/blob/create-apiservice-test/test/e2e/apimachinery/aggregator.go#L869-L936) which validates that the two endpoints are hit.

## Log sample

    [It] Should be able to replace APIServiceStatus and delete a collection of APIServices
      /home/ii/go/src/k8s.io/kubernetes/test/e2e/apimachinery/aggregator.go:112
    STEP: Registering the sample API server.
    Jun 22 14:03:27.530: INFO: new replicaset for deployment "beta-sample-apiserver-deployment" is yet to be created
    Jun 22 14:03:29.598: INFO: deployment status: v1.DeploymentStatus{ObservedGeneration:1, Replicas:1, UpdatedReplicas:1, ReadyReplicas:0, AvailableReplicas:0, UnavailableReplias:1, Conditions:[]v1.DeploymentCondition{v1.DeploymentCondition{Type:"Available", Status:"False", LastUpdateTime:v1.Time{Time:time.Time{wall:0x0, ext:63759924207, loc:(*time.Location)(0x9510540)}}, LastTransitionTime:v1.Time{Time:time.Time{wall:0x0, ext:63759924207, loc:(*time.Location)(0x9510540)}}, Reason:"MinimumReplicasUnavailable", Message:"Deployment does not have minimum availability."}, v1.DeploymentCondition{Type:"Progressing", Status:"True", LastUpdateTime:v1.Time{Time:time.Time{wall:0x0, ext:63759924207,loc:(*time.Location)(0x9510540)}}, LastTransitionTime:v1.Time{Time:time.Time{wall:0x0, ext:63759924207, loc:(*time.Location)(0x9510540)}}, Reason:"ReplicaSetUpdated", Message:"ReplicaSet \"beta-sample-apiserver-deployment-f8568d796\" is progressing."}}, CollisionCount:(*int32)(nil)}
    Jun 22 14:03:32.746: INFO: Waited 1.12209567s for the sample-apiserver to be ready to handle requests.
    STEP: updating the APIService Status
    Jun 22 14:03:32.761: INFO: updatedStatus.Conditions: []v1.APIServiceCondition{v1.APIServiceCondition{Type:"Available", Status:"True", LastTransitionTime:v1.Time{Time:time.Time{wall:0x0, ext:63759924211, loc:(*time.Location)(0x9510540)}}, Reason:"Passed", Message:"all checks passed"}, v1.APIServiceCondition{Type:"StatusUpdate", Status:"True", LastTransitionTime:v1.Time{Time:time.Time{wall:0x0, ext:0, loc:(*time.Location)(nil)}}, Reason:"E2E", Message:"Set from e2e test"}}
    STEP: watching for the APIService to be updated
    Jun 22 14:03:32.763: INFO: Observed APIService v1beta1.wardle.example.com with Labels: map[apiservice:created] & Conditions: {Available True 2021-06-22 14:03:31 +1200 NZST Passed all checks passed}
    Jun 22 14:03:32.763: INFO: Found APIService v1beta1.wardle.example.com with Labels: map[apiservice:created] & Conditions: {StatusUpdate True 0001-01-01 00:00:00 +0000 UTC E2E Set from e2e test}
    Jun 22 14:03:32.763: INFO: APIService Status for v1beta1.wardle.example.com has been updated
    STEP: Delete a collection of APIServices
    Jun 22 14:03:32.823: INFO: APIService v1beta1.wardle.example.com has been deleted.

# Verifying increase in coverage with APISnoop

This query shows all APIService endpoints hit within a short period of running the e2e test, including the two target endpoints.

```sql-mode
select distinct  endpoint, right(useragent,81) AS useragent
from testing.audit_event
where endpoint ilike '%APIService%'
and release_date::BIGINT > round(((EXTRACT(EPOCH FROM NOW()))::numeric)*1000,0) - 60000
and useragent like 'e2e%'
order by endpoint
limit 10;
```

```example
                  endpoint                   |                                     useragent
---------------------------------------------+-----------------------------------------------------------------------------------
 createApiregistrationV1APIService           | Should be able to replace APIServiceStatus and delete a collection of APIServices
 deleteApiregistrationV1APIService           | Should be able to replace APIServiceStatus and delete a collection of APIServices
 deleteApiregistrationV1CollectionAPIService | Should be able to replace APIServiceStatus and delete a collection of APIServices
 listApiregistrationV1APIService             | Should be able to replace APIServiceStatus and delete a collection of APIServices
 readApiregistrationV1APIService             | Should be able to replace APIServiceStatus and delete a collection of APIServices
 replaceApiregistrationV1APIServiceStatus    | Should be able to replace APIServiceStatus and delete a collection of APIServices
(6 rows)

```

# Final notes

If a test with these calls gets merged, **test coverage will go up by 2 points**

This test is also created with the goal of conformance promotion.

---

/sig testing

/sig architecture

/area conformance
