# Progress <code>[1/6]</code>

-   [X] APISnoop org-flow: [Corev1APIServiceLifecycleTest-v4.org](https://github.com/apisnoop/ticket-writing/blob/master/Corev1APIServiceLifecycleTest-v4.org)
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


# E2E Test

Using a number of existing e2e test practices the [current conformance test](https://github.com/ii/kubernetes/blob/create-apiservice-test-v4/test/e2e/apimachinery/aggregator.go#L92) has [been extended](https://github.com/ii/kubernetes/blob/create-apiservice-test-v4/test/e2e/apimachinery/aggregator.go#L528-L701) to cover the outstanding APIService endpoints. There has been some [helpful feedback from Jordan](https://github.com/kubernetes/kubernetes/pull/103092/#discussion_r799563377) around how the current Conformance test is using RBAC, which is optional and not part of Conformance. Those calls will now only happen if [e2eauth.IsRBACEnabled](https://github.com/ii/kubernetes/blob/create-apiservice-test-v4/test/e2e/apimachinery/aggregator.go#L140) is true. The e2e logs for this test are listed below.

```
[sig-api-machinery] Aggregator Should be able to support the 1.17 Sample API Server using the current Aggregator [Conformance]
/home/heyste/go/src/k8s.io/kubernetes/test/e2e/apimachinery/aggregator.go:92
  STEP: Creating a kubernetes client @ 01/20/23 07:38:47.458
  Jan 20 07:38:47.458: INFO: >>> kubeConfig: /home/heyste/.kube/config
  STEP: Building a namespace api object, basename aggregator @ 01/20/23 07:38:47.458
  STEP: Waiting for a default service account to be provisioned in namespace @ 01/20/23 07:38:47.481
  STEP: Waiting for kube-root-ca.crt to be provisioned in namespace @ 01/20/23 07:38:47.484
  Jan 20 07:38:47.499: INFO: >>> kubeConfig: /home/heyste/.kube/config
  STEP: Registering the sample API server. @ 01/20/23 07:38:47.5
  Jan 20 07:38:47.866: INFO: Found ClusterRoles; assuming RBAC is enabled.
  Jan 20 07:38:47.941: INFO: deployment "sample-apiserver-deployment" doesn't have the required revision set
  Jan 20 07:38:51.432: INFO: deployment status: v1.DeploymentStatus{ObservedGeneration:1, Replicas:1, UpdatedReplicas:1, ReadyReplicas:0, AvailableReplicas:0, UnavailableReplicas:1, Conditions:[]v1.DeploymentCondition{v1.DeploymentCondition{Type:"Available", Status:"False", LastUpdateTime:time.Date(2023, time.January, 20, 7, 38, 47, 0, time.Local), LastTransitionTime:time.Date(2023, time.January, 20, 7, 38, 47, 0, time.Local), Reason:"MinimumReplicasUnavailable", Message:"Deployment does not have minimum availability."}, v1.DeploymentCondition{Type:"Progressing", Status:"True", LastUpdateTime:time.Date(2023, time.January, 20, 7, 38, 48, 0, time.Local), LastTransitionTime:time.Date(2023, time.January, 20, 7, 38, 47, 0, time.Local), Reason:"ReplicaSetUpdated", Message:"ReplicaSet \"sample-apiserver-deployment-55bd96fd47\" is progressing."}}, CollisionCount:(*int32)(nil)}
...
  Jan 20 07:39:11.437: INFO: deployment status: v1.DeploymentStatus{ObservedGeneration:1, Replicas:1, UpdatedReplicas:1, ReadyReplicas:0, AvailableReplicas:0, UnavailableReplicas:1, Conditions:[]v1.DeploymentCondition{v1.DeploymentCondition{Type:"Available", Status:"False", LastUpdateTime:time.Date(2023, time.January, 20, 7, 38, 47, 0, time.Local), LastTransitionTime:time.Date(2023, time.January, 20, 7, 38, 47, 0, time.Local), Reason:"MinimumReplicasUnavailable", Message:"Deployment does not have minimum availability."}, v1.DeploymentCondition{Type:"Progressing", Status:"True", LastUpdateTime:time.Date(2023, time.January, 20, 7, 38, 48, 0, time.Local), LastTransitionTime:time.Date(2023, time.January, 20, 7, 38, 47, 0, time.Local), Reason:"ReplicaSetUpdated", Message:"ReplicaSet \"sample-apiserver-deployment-55bd96fd47\" is progressing."}}, CollisionCount:(*int32)(nil)}
  Jan 20 07:39:13.588: INFO: Waited 129.184707ms for the sample-apiserver to be ready to handle requests.
  STEP: Read Status for v1alpha1.wardle.example.com @ 01/20/23 07:39:13.662
  STEP: kubectl patch apiservice v1alpha1.wardle.example.com -p '{"spec":{"versionPriority": 400}}' @ 01/20/23 07:39:13.666
  STEP: List APIServices @ 01/20/23 07:39:13.683
  Jan 20 07:39:13.691: INFO: Found v1alpha1.wardle.example.com in APIServiceList
  STEP: Adding a label to the APIService @ 01/20/23 07:39:13.691
  Jan 20 07:39:13.712: INFO: APIService labels: map[e2e-apiservice:patched]
  STEP: Updating APIService Status @ 01/20/23 07:39:13.712
  Jan 20 07:39:13.733: INFO: updatedStatus.Conditions: []v1.APIServiceCondition{v1.APIServiceCondition{Type:"Available", Status:"True", LastTransitionTime:time.Date(2023, time.January, 20, 7, 39, 13, 0, time.Local), Reason:"Passed", Message:"all checks passed"}, v1.APIServiceCondition{Type:"StatusUpdated", Status:"True", LastTransitionTime:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), Reason:"E2E", Message:"Set from e2e test"}}
  STEP: Confirm that v1alpha1.wardle.example.com /status was updated @ 01/20/23 07:39:13.733
  Jan 20 07:39:13.737: INFO: Observed APIService v1alpha1.wardle.example.com with Labels: map[e2e-apiservice:patched] & Condition: {Available True 2023-01-20 07:39:13 +1300 NZDT Passed all checks passed}
  Jan 20 07:39:13.737: INFO: Found APIService v1alpha1.wardle.example.com with Labels: map[e2e-apiservice:patched] & Condition: {StatusUpdated True 0001-01-01 00:00:00 +0000 UTC E2E Set from e2e test}
  Jan 20 07:39:13.737: INFO: Found updated status condition for v1alpha1.wardle.example.com
  STEP: Replace APIService v1alpha1.wardle.example.com @ 01/20/23 07:39:13.737
  Jan 20 07:39:13.766: INFO: Found updated apiService label for "v1alpha1.wardle.example.com"
  STEP: Delete APIService "dynamic-flunder-2077748942" @ 01/20/23 07:39:13.766
  STEP: Recreating test-flunder before removing endpoint via deleteCollection @ 01/20/23 07:39:13.785
  STEP: Read v1alpha1.wardle.example.com /status before patching it @ 01/20/23 07:39:13.793
  STEP: Patch APIService Status @ 01/20/23 07:39:13.795
  STEP: Confirm that v1alpha1.wardle.example.com /status was patched @ 01/20/23 07:39:13.808
  Jan 20 07:39:13.812: INFO: Observed APIService v1alpha1.wardle.example.com with Labels: map[e2e-apiservice:patched v1alpha1.wardle.example.com:updated] & Conditions: {Available True 2023-01-20 07:39:13 +1300 NZDT Passed all checks passed}
  Jan 20 07:39:13.812: INFO: Observed APIService v1alpha1.wardle.example.com with Labels: map[e2e-apiservice:patched v1alpha1.wardle.example.com:updated] & Conditions: {StatusUpdated True 0001-01-01 00:00:00 +0000 UTC E2E Set from e2e test}
  Jan 20 07:39:13.812: INFO: Found APIService v1alpha1.wardle.example.com with Labels: map[e2e-apiservice:patched v1alpha1.wardle.example.com:updated] & Conditions: {StatusPatched True 0001-01-01 00:00:00 +0000 UTC E2E Set by e2e test}
  Jan 20 07:39:13.813: INFO: Found patched status condition for v1alpha1.wardle.example.com
  STEP: APIService deleteCollection with labelSelector: "e2e-apiservice=patched" @ 01/20/23 07:39:13.813
  STEP: Confirm that the generated APIService has been deleted @ 01/20/23 07:39:13.823
  Jan 20 07:39:13.823: INFO: Requesting list of APIServices to confirm quantity
  Jan 20 07:39:13.830: INFO: Found 0 APIService with label "e2e-apiservice=patched"
  Jan 20 07:39:13.830: INFO: APIService v1alpha1.wardle.example.com has been deleted.
  Jan 20 07:39:14.057: INFO: Waiting up to 3m0s for all (but 0) nodes to be ready
  STEP: Destroying namespace "aggregator-2455" for this suite. @ 01/20/23 07:39:14.093
• [26.684 seconds]
```


# Verifying increase in coverage with APISnoop


## Listing endpoints hit by the new e2e test

This query shows the following APIService endpoints are hit within a short period of running this e2e test

```sql-mode
select distinct  substring(endpoint from '\w+') AS endpoint, right(useragent,95) AS useragent
from testing.audit_event
where endpoint ilike '%APIService%'
and release_date::BIGINT > round(((EXTRACT(EPOCH FROM NOW()))::numeric)*1000,0) - 60000
and useragent ilike 'e2e%should%'
order by endpoint
limit 10;
```

```example
                  endpoint                   |                                            useragent
---------------------------------------------+-------------------------------------------------------------------------------------------------
 createApiregistrationV1APIService           | Should be able to support the 1.17 Sample API Server using the current Aggregator [Conformance]
 deleteApiregistrationV1APIService           | Should be able to support the 1.17 Sample API Server using the current Aggregator [Conformance]
 deleteApiregistrationV1CollectionAPIService | Should be able to support the 1.17 Sample API Server using the current Aggregator [Conformance]
 listApiregistrationV1APIService             | Should be able to support the 1.17 Sample API Server using the current Aggregator [Conformance]
 patchApiregistrationV1APIService            | Should be able to support the 1.17 Sample API Server using the current Aggregator [Conformance]
 patchApiregistrationV1APIServiceStatus      | Should be able to support the 1.17 Sample API Server using the current Aggregator [Conformance]
 readApiregistrationV1APIService             | Should be able to support the 1.17 Sample API Server using the current Aggregator [Conformance]
 readApiregistrationV1APIServiceStatus       | Should be able to support the 1.17 Sample API Server using the current Aggregator [Conformance]
 replaceApiregistrationV1APIService          | Should be able to support the 1.17 Sample API Server using the current Aggregator [Conformance]
 replaceApiregistrationV1APIServiceStatus    | Should be able to support the 1.17 Sample API Server using the current Aggregator [Conformance]
(10 rows)

```


# Final notes

If a test with these calls gets merged, **test coverage will go up by 4 points**

This test is also created with the goal of conformance promotion.

---

/sig testing

/sig architecture

/area conformance
