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
  and endpoint ilike '%APIServiceStatus'
  order by kind, endpoint desc
  limit 5;
```

```example
                 endpoint                 |                           path                            |    kind
------------------------------------------|-----------------------------------------------------------|------------
 replaceApiregistrationV1APIServiceStatus | /apis/apiregistration.k8s.io/v1/apiservices/{name}/status | APIService
 readApiregistrationV1APIServiceStatus    | /apis/apiregistration.k8s.io/v1/apiservices/{name}/status | APIService
 patchApiregistrationV1APIServiceStatus   | /apis/apiregistration.k8s.io/v1/apiservices/{name}/status | APIService
(3 rows)

```

# API Reference and feature documentation

-   [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/kubernetes-api/)
-   [client-go - RESOURCENAME](https://github.com/kubernetes/client-go/blob/master/kubernetes/typed/core/v1/RESOURCENAME.go)

# The mock test

## Test outline

1.  Create a REST Client

2.  Get JSON response for the v1.networking.k8s.io APIService 'status' endpoint

3.  Confirm that no error during GET request

4.  TBD: Validate the response?

## Test the functionality in Go

```go
package main

import (
  // "encoding/json"
  "context"
  "flag"
  "fmt"
  "os"
  // v1 "k8s.io/api/core/v1"
  // "k8s.io/client-go/dynamic"
  // "k8s.io/apimachinery/pkg/runtime/schema"
  // metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
  "k8s.io/client-go/kubernetes"
  // "k8s.io/apimachinery/pkg/types"
  "k8s.io/client-go/tools/clientcmd"
)

// helper function that mirrors framework.ExpectNoError
func ExpectNoError(err error, msg string) {
  if err != nil {
    errMsg := msg + fmt.Sprintf(" %v\n", err)
    os.Stderr.WriteString(errMsg)
    os.Exit(1)
  }
}

// helper function that mirrors framework.ExpectEqual
func ExpectEqual(a int, b int, msg string, i interface{}) {
  if a != b {
    errMsg := msg + fmt.Sprintf(" %v\n", i)
    os.Stderr.WriteString(errMsg)
    os.Exit(1)
  }
}

// helper function to inspect various interfaces
func inspect(level int, name string, i interface{}) {
  fmt.Printf("Inspecting: %s\n", name)
  fmt.Printf("Inspect level: %d   Type: %T\n", level, i)
  switch level {
  case 1:
    fmt.Printf("%+v\n\n", i)
  case 2:
    fmt.Printf("%#v\n\n", i)
  default:
    fmt.Printf("%v\n\n", i)
  }
}

func main() {
  // uses the current context in kubeconfig
  kubeconfig := flag.String("kubeconfig", fmt.Sprintf("%v/%v/%v", os.Getenv("HOME"), ".kube", "config"), "(optional) absolute path to the kubeconfig file")
  flag.Parse()
  config, err := clientcmd.BuildConfigFromFlags("", *kubeconfig)
  if err != nil {
    fmt.Println(err, "Could not build config from flags")
    return
  }
  // make our work easier to find in the audit_event queries
  config.UserAgent = "live-test-writing"
  // creates the clientset
  ClientSet, _ := kubernetes.NewForConfig(config)
  // DynamicClientSet, _ := dynamic.NewForConfig(config)
  // podResource := schema.GroupVersionResource{Group: "", Version: "v1", Resource: "pods"}

  // TEST BEGINS HERE

  fmt.Println("[status] starting test...")

  restClient := ClientSet.Discovery().RESTClient()
  _ , err = restClient.Get().AbsPath("/apis/apiregistration.k8s.io/v1/apiservices/v1.networking.k8s.io/status").SetHeader("Accept", "application/json").DoRaw(context.TODO())
  ExpectNoError(err, "Could not get ../apiservices/v1.networking.k8s.io/status.")

  // TEST ENDS HERE

  fmt.Println("[status] complete")

}
```

```go
[status] starting test...
[status] complete
```

# Verifying increase in coverage with APISnoop

## Reset stats

```sql-mode
delete from testing.audit_event;
```

```example
DELETE 75045
```

## Discover useragents:

```sql-mode
select distinct useragent
  from testing.audit_event
  where useragent like 'live%';
```

```example
     useragent
-------------------
 live-test-writing
(1 row)

```

## List endpoints hit by the test:

```sql-mode
select * from testing.endpoint_hit_by_new_test;
```

```example
     useragent     |               endpoint                | hit_by_ete | hit_by_new_test
-------------------|---------------------------------------|------------|-----------------
 live-test-writing | readApiregistrationV1APIServiceStatus | f          |               5
(1 row)

```

## Display endpoint coverage change:

```sql-mode
select * from testing.projected_change_in_coverage;
```

```example
   category    | total_endpoints | old_coverage | new_coverage | change_in_number
---------------|-----------------|--------------|--------------|------------------
 test_coverage |             862 |          343 |          344 |                1
(1 row)

```

# Final notes

If a test with these calls gets merged, **test coverage will go up by 1 points**

This test is also created with the goal of conformance promotion.

---

/sig testing

/sig architecture

/area conformance

# check e2e test run

## endpoints from Aggregator e2e conformance test

```sql-mode
select distinct endpoint, test
  from audit_event
 where test ilike '%%current Aggregator%'
     and endpoint ilike '%Apiservice%'
 order by endpoint;
```

```example
             endpoint              |                                                              test
-----------------------------------|--------------------------------------------------------------------------------------------------------------------------------
 createApiregistrationV1APIService | [sig-api-machinery] Aggregator Should be able to support the 1.17 Sample API Server using the current Aggregator [Conformance]
 deleteApiregistrationV1APIService | [sig-api-machinery] Aggregator Should be able to support the 1.17 Sample API Server using the current Aggregator [Conformance]
 readApiregistrationV1APIService   | [sig-api-machinery] Aggregator Should be able to support the 1.17 Sample API Server using the current Aggregator [Conformance]
(3 rows)

```

## locate APIService and APIServiceStatus endpoints

```sql-mode
select distinct endpoint, test
  from audit_event
 where endpoint ilike '%ApiregistrationV1APIService%'
 order by endpoint;
```

```example
                 endpoint                 |                                                              test
------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------
 createApiregistrationV1APIService        | [sig-api-machinery] Aggregator Should be able to support the 1.17 Sample API Server using the current Aggregator [Conformance]
 createApiregistrationV1APIService        |
 deleteApiregistrationV1APIService        | [sig-api-machinery] Aggregator Should be able to support the 1.17 Sample API Server using the current Aggregator [Conformance]
 deleteApiregistrationV1APIService        |
 listApiregistrationV1APIService          |
 readApiregistrationV1APIService          | [sig-api-machinery] Aggregator Should be able to support the 1.17 Sample API Server using the current Aggregator [Conformance]
 readApiregistrationV1APIService          |
 replaceApiregistrationV1APIServiceStatus |
(8 rows)

```

## details for 'replace status' event

```sql-mode
select *
-- select endpoint, test
  from audit_event
 where endpoint ilike '%ApiregistrationV1APIServiceStatus'
 order by endpoint
  limit 3;
```

```example
 release | release_date |               audit_id               |                 endpoint                 |                        useragent                        | test | test_hit | conf_test_hit |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         data                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |                                                    source                                                     |   id   |        ingested_at
---------|--------------|--------------------------------------|------------------------------------------|---------------------------------------------------------|------|----------|---------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------|--------|----------------------------
 1.20.0  | 1606153271   | 1b4543c8-7f1c-4ab1-af5b-f4105aa128ff | replaceApiregistrationV1APIServiceStatus | kube-apiserver/v1.20.0 (linux/amd64) kubernetes/7335824 |      | f        | f             | {"kind": "Event", "user": {"uid": "4266954b-f31a-4240-8d36-a723ca866d29", "groups": ["system:masters"], "username": "system:apiserver"}, "verb": "update", "level": "RequestResponse", "stage": "ResponseComplete", "auditID": "1b4543c8-7f1c-4ab1-af5b-f4105aa128ff", "objectRef": {"uid": "510f4499-2595-4a39-8019-b709a90ba8d9", "name": "v1alpha1.wardle.example.com", "apiGroup": "apiregistration.k8s.io", "resource": "apiservices", "apiVersion": "v1", "subresource": "status", "resourceVersion": "11786"}, "sourceIPs": ["::1"], "userAgent": "kube-apiserver/v1.20.0 (linux/amd64) kubernetes/7335824", "apiVersion": "audit.k8s.io/v1", "requestURI": "/apis/apiregistration.k8s.io/v1/apiservices/v1alpha1.wardle.example.com/status", "annotations": {"authorization.k8s.io/reason": "", "authorization.k8s.io/decision": "allow"}, "operationId": "replaceApiregistrationV1APIServiceStatus", "requestObject": {"kind": "APIService", "spec": {"group": "wardle.example.com", "service": {"name": "sample-api", "port": 7443, "namespace": "aggregator-5443"}, "version": "v1alpha1", "caBundle": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUM5ekNDQWQrZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBREFkTVJzd0dRWURWUVFERXhKbE1tVXQKYzJWeWRtVnlMV05sY25RdFkyRXdIaGNOTWpBeE1USXpNVFkwTWpBNVdoY05NekF4TVRJeE1UWTBNakE1V2pBZApNUnN3R1FZRFZRUURFeEpsTW1VdGMyVnlkbVZ5TFdObGNuUXRZMkV3Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBCkE0SUJEd0F3Z2dFS0FvSUJBUUM5c2wvV3ZycGVpanIzT0tUMFkyd0VXVVhSWEh3YlhBc3FuVVova0JCNUlDYTYKWldHUWd0S2ljUndMMGhEMmhYT1BkZHhjRitoNGp6MHlKdmZZOWhJcVdTUnhBYTlOekY2dDZuSUtQOFRzNmFHNQpHNVN2c3ZLS21jTDBNWGh5VTRKdUdXTjBpWEZtQ05QQTFIcER4STY3cWh3UG95cDVWcnM2QVA5TlJFbWM4cURHCmFqUUJlZno5NzREcTNzWlJmTDRJVWNDdkNEL2ZUb1Q4MTM2NE5JSUFrdjFrTncxODcvK1ArVzhSOEdWcWhvdjAKWEJ3RnhLNm1VS3ZWaUNQM2MyMmV4YlVjWTUxL0pQa1hpeFBZR1VuMVphU01sOFljbWxtY0VMcWlIL0NoaHo5WApuTFp5SUh5NHh0eXpOcHBQU0Q4cWpOb3Y5K1hEVW5sYkdiem1mNVczQWdNQkFBR2pRakJBTUE0R0ExVWREd0VCCi93UUVBd0lDcERBUEJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJRcUJLQjVOcVk4TE94Yis1ZjcKK0ZaaFZYZ1Q0VEFOQmdrcWhraUc5dzBCQVFzRkFBT0NBUUVBbDU5OVgrWm12b3l1Q3NYZFZwVUFSMEJXWk5kbQpmMHJiUVZuNDJDOEpqVjFoWTZ5aFVqaXRCRW5vYWNsSVFDTUpBQlEwRFlMR1hMVDcwOFRFZEw1YnhHOUJzcHkyCi9haEx6WG5LSXpIc1hKZlZjWVQyUnNQc3l3VVpRUWljNXVDd09RYVlJaTBjN0oxZ21ONmRrMjBjcHZYZVpNc0wKVzlwNXhVVVFEZkk5MUtJZEFPNWFsTXYwQ1hzS1RxTm1MekNWekxIZkhWYjlJMWhKa05EZ3pHdkk1d0VVZUhBVgplWG5VSm0zc284MURVNjgyTHhyR2J4YTVjZFVsZzhuOUFGd2VveE1VcnZxYjI5cFNWczhaL3dSd2hYTERqWmt4Cm5zUmxQbURERXVhWnNPREhUdkNyckh1ZlpxdUVlM0NJTFBNemtOU2M1bUtJZ1Q3MFhWbjN2U01sZ3c9PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==", "versionPriority": 200, "groupPriorityMinimum": 2000}, "status": {"conditions": [{"type": "Available", "reason": "Passed", "status": "True", "message": "all checks passed", "lastTransitionTime": "2020-11-23T16:42:22Z"}]}, "metadata": {"uid": "510f4499-2595-4a39-8019-b709a90ba8d9", "name": "v1alpha1.wardle.example.com", "resourceVersion": "11786", "creationTimestamp": "2020-11-23T16:42:19Z"}, "apiVersion": "apiregistration.k8s.io/v1"}, "responseObject": {"kind": "APIService", "spec": {"group": "wardle.example.com", "service": {"name": "sample-api", "port": 7443, "namespace": "aggregator-5443"}, "version": "v1alpha1", "caBundle": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUM5ekNDQWQrZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBREFkTVJzd0dRWURWUVFERXhKbE1tVXQKYzJWeWRtVnlMV05sY25RdFkyRXdIaGNOTWpBeE1USXpNVFkwTWpBNVdoY05NekF4TVRJeE1UWTBNakE1V2pBZApNUnN3R1FZRFZRUURFeEpsTW1VdGMyVnlkbVZ5TFdObGNuUXRZMkV3Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBCkE0SUJEd0F3Z2dFS0FvSUJBUUM5c2wvV3ZycGVpanIzT0tUMFkyd0VXVVhSWEh3YlhBc3FuVVova0JCNUlDYTYKWldHUWd0S2ljUndMMGhEMmhYT1BkZHhjRitoNGp6MHlKdmZZOWhJcVdTUnhBYTlOekY2dDZuSUtQOFRzNmFHNQpHNVN2c3ZLS21jTDBNWGh5VTRKdUdXTjBpWEZtQ05QQTFIcER4STY3cWh3UG95cDVWcnM2QVA5TlJFbWM4cURHCmFqUUJlZno5NzREcTNzWlJmTDRJVWNDdkNEL2ZUb1Q4MTM2NE5JSUFrdjFrTncxODcvK1ArVzhSOEdWcWhvdjAKWEJ3RnhLNm1VS3ZWaUNQM2MyMmV4YlVjWTUxL0pQa1hpeFBZR1VuMVphU01sOFljbWxtY0VMcWlIL0NoaHo5WApuTFp5SUh5NHh0eXpOcHBQU0Q4cWpOb3Y5K1hEVW5sYkdiem1mNVczQWdNQkFBR2pRakJBTUE0R0ExVWREd0VCCi93UUVBd0lDcERBUEJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJRcUJLQjVOcVk4TE94Yis1ZjcKK0ZaaFZYZ1Q0VEFOQmdrcWhraUc5dzBCQVFzRkFBT0NBUUVBbDU5OVgrWm12b3l1Q3NYZFZwVUFSMEJXWk5kbQpmMHJiUVZuNDJDOEpqVjFoWTZ5aFVqaXRCRW5vYWNsSVFDTUpBQlEwRFlMR1hMVDcwOFRFZEw1YnhHOUJzcHkyCi9haEx6WG5LSXpIc1hKZlZjWVQyUnNQc3l3VVpRUWljNXVDd09RYVlJaTBjN0oxZ21ONmRrMjBjcHZYZVpNc0wKVzlwNXhVVVFEZkk5MUtJZEFPNWFsTXYwQ1hzS1RxTm1MekNWekxIZkhWYjlJMWhKa05EZ3pHdkk1d0VVZUhBVgplWG5VSm0zc284MURVNjgyTHhyR2J4YTVjZFVsZzhuOUFGd2VveE1VcnZxYjI5cFNWczhaL3dSd2hYTERqWmt4Cm5zUmxQbURERXVhWnNPREhUdkNyckh1ZlpxdUVlM0NJTFBNemtOU2M1bUtJZ1Q3MFhWbjN2U01sZ3c9PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==", "versionPriority": 200, "groupPriorityMinimum": 2000}, "status": {"conditions": [{"type": "Available", "reason": "Passed", "status": "True", "message": "all checks passed", "lastTransitionTime": "2020-11-23T16:42:22Z"}]}, "metadata": {"uid": "510f4499-2595-4a39-8019-b709a90ba8d9", "name": "v1alpha1.wardle.example.com", "resourceVersion": "11787", "creationTimestamp": "2020-11-23T16:42:19Z"}, "apiVersion": "apiregistration.k8s.io/v1"}, "responseStatus": {"code": 200, "metadata": {}}, "stageTimestamp": "2020-11-23T16:42:22.176379Z", "requestReceivedTimestamp": "2020-11-23T16:42:22.172790Z"}                                                                                                                                                                                                                                                                                                                                             | https://prow.k8s.io/view/gcs/kubernetes-jenkins/logs/ci-kubernetes-gce-conformance-latest/1330899902422585344 | 314383 | 2020-11-23 19:01:28.966956
 1.20.0  | 1606153271   | a4c4c782-895f-4a8b-94ba-9a5ba3e40326 | replaceApiregistrationV1APIServiceStatus | kube-apiserver/v1.20.0 (linux/amd64) kubernetes/7335824 |      | f        | f             | {"kind": "Event", "user": {"uid": "4266954b-f31a-4240-8d36-a723ca866d29", "groups": ["system:masters"], "username": "system:apiserver"}, "verb": "update", "level": "RequestResponse", "stage": "ResponseComplete", "auditID": "a4c4c782-895f-4a8b-94ba-9a5ba3e40326", "objectRef": {"uid": "fcd474eb-fd75-49bb-80e6-cf2610e7faa9", "name": "v1beta1.metrics.k8s.io", "apiGroup": "apiregistration.k8s.io", "resource": "apiservices", "apiVersion": "v1", "subresource": "status", "resourceVersion": "382"}, "sourceIPs": ["::1"], "userAgent": "kube-apiserver/v1.20.0 (linux/amd64) kubernetes/7335824", "apiVersion": "audit.k8s.io/v1", "requestURI": "/apis/apiregistration.k8s.io/v1/apiservices/v1beta1.metrics.k8s.io/status", "annotations": {"authorization.k8s.io/reason": "", "authorization.k8s.io/decision": "allow"}, "operationId": "replaceApiregistrationV1APIServiceStatus", "requestObject": {"kind": "APIService", "spec": {"group": "metrics.k8s.io", "service": {"name": "metrics-server", "port": 443, "namespace": "kube-system"}, "version": "v1beta1", "versionPriority": 100, "groupPriorityMinimum": 100, "insecureSkipTLSVerify": true}, "status": {"conditions": [{"type": "Available", "reason": "EndpointsNotFound", "status": "False", "message": "cannot find endpoints for service/metrics-server in \"kube-system\"", "lastTransitionTime": "2020-11-23T15:49:31Z"}]}, "metadata": {"uid": "fcd474eb-fd75-49bb-80e6-cf2610e7faa9", "name": "v1beta1.metrics.k8s.io", "labels": {"kubernetes.io/cluster-service": "true", "addonmanager.kubernetes.io/mode": "Reconcile"}, "annotations": {"kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"apiregistration.k8s.io/v1\",\"kind\":\"APIService\",\"metadata\":{\"annotations\":{},\"labels\":{\"addonmanager.kubernetes.io/mode\":\"Reconcile\",\"kubernetes.io/cluster-service\":\"true\"},\"name\":\"v1beta1.metrics.k8s.io\"},\"spec\":{\"group\":\"metrics.k8s.io\",\"groupPriorityMinimum\":100,\"insecureSkipTLSVerify\":true,\"service\":{\"name\":\"metrics-server\",\"namespace\":\"kube-system\"},\"version\":\"v1beta1\",\"versionPriority\":100}}\n"}, "resourceVersion": "382", "creationTimestamp": "2020-11-23T15:49:31Z"}, "apiVersion": "apiregistration.k8s.io/v1"}, "responseObject": {"kind": "APIService", "spec": {"group": "metrics.k8s.io", "service": {"name": "metrics-server", "port": 443, "namespace": "kube-system"}, "version": "v1beta1", "versionPriority": 100, "groupPriorityMinimum": 100, "insecureSkipTLSVerify": true}, "status": {"conditions": [{"type": "Available", "reason": "EndpointsNotFound", "status": "False", "message": "cannot find endpoints for service/metrics-server in \"kube-system\"", "lastTransitionTime": "2020-11-23T15:49:31Z"}]}, "metadata": {"uid": "fcd474eb-fd75-49bb-80e6-cf2610e7faa9", "name": "v1beta1.metrics.k8s.io", "labels": {"kubernetes.io/cluster-service": "true", "addonmanager.kubernetes.io/mode": "Reconcile"}, "annotations": {"kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"apiregistration.k8s.io/v1\",\"kind\":\"APIService\",\"metadata\":{\"annotations\":{},\"labels\":{\"addonmanager.kubernetes.io/mode\":\"Reconcile\",\"kubernetes.io/cluster-service\":\"true\"},\"name\":\"v1beta1.metrics.k8s.io\"},\"spec\":{\"group\":\"metrics.k8s.io\",\"groupPriorityMinimum\":100,\"insecureSkipTLSVerify\":true,\"service\":{\"name\":\"metrics-server\",\"namespace\":\"kube-system\"},\"version\":\"v1beta1\",\"versionPriority\":100}}\n"}, "resourceVersion": "396", "creationTimestamp": "2020-11-23T15:49:31Z"}, "apiVersion": "apiregistration.k8s.io/v1"}, "responseStatus": {"code": 200, "metadata": {}}, "stageTimestamp": "2020-11-23T15:49:32.405645Z", "requestReceivedTimestamp": "2020-11-23T15:49:32.396485Z"}                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       | https://prow.k8s.io/view/gcs/kubernetes-jenkins/logs/ci-kubernetes-gce-conformance-latest/1330899902422585344 | 396238 | 2020-11-23 19:01:28.966956
 1.20.0  | 1606153271   | c95a93f9-39f3-4a25-a236-c05768cbfeeb | replaceApiregistrationV1APIServiceStatus | kube-apiserver/v1.20.0 (linux/amd64) kubernetes/7335824 |      | f        | f             | {"kind": "Event", "user": {"uid": "4266954b-f31a-4240-8d36-a723ca866d29", "groups": ["system:masters"], "username": "system:apiserver"}, "verb": "update", "level": "RequestResponse", "stage": "ResponseComplete", "auditID": "c95a93f9-39f3-4a25-a236-c05768cbfeeb", "objectRef": {"uid": "510f4499-2595-4a39-8019-b709a90ba8d9", "name": "v1alpha1.wardle.example.com", "apiGroup": "apiregistration.k8s.io", "resource": "apiservices", "apiVersion": "v1", "subresource": "status", "resourceVersion": "11782"}, "sourceIPs": ["::1"], "userAgent": "kube-apiserver/v1.20.0 (linux/amd64) kubernetes/7335824", "apiVersion": "audit.k8s.io/v1", "requestURI": "/apis/apiregistration.k8s.io/v1/apiservices/v1alpha1.wardle.example.com/status", "annotations": {"authorization.k8s.io/reason": "", "authorization.k8s.io/decision": "allow"}, "operationId": "replaceApiregistrationV1APIServiceStatus", "requestObject": {"kind": "APIService", "spec": {"group": "wardle.example.com", "service": {"name": "sample-api", "port": 7443, "namespace": "aggregator-5443"}, "version": "v1alpha1", "caBundle": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUM5ekNDQWQrZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBREFkTVJzd0dRWURWUVFERXhKbE1tVXQKYzJWeWRtVnlMV05sY25RdFkyRXdIaGNOTWpBeE1USXpNVFkwTWpBNVdoY05NekF4TVRJeE1UWTBNakE1V2pBZApNUnN3R1FZRFZRUURFeEpsTW1VdGMyVnlkbVZ5TFdObGNuUXRZMkV3Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBCkE0SUJEd0F3Z2dFS0FvSUJBUUM5c2wvV3ZycGVpanIzT0tUMFkyd0VXVVhSWEh3YlhBc3FuVVova0JCNUlDYTYKWldHUWd0S2ljUndMMGhEMmhYT1BkZHhjRitoNGp6MHlKdmZZOWhJcVdTUnhBYTlOekY2dDZuSUtQOFRzNmFHNQpHNVN2c3ZLS21jTDBNWGh5VTRKdUdXTjBpWEZtQ05QQTFIcER4STY3cWh3UG95cDVWcnM2QVA5TlJFbWM4cURHCmFqUUJlZno5NzREcTNzWlJmTDRJVWNDdkNEL2ZUb1Q4MTM2NE5JSUFrdjFrTncxODcvK1ArVzhSOEdWcWhvdjAKWEJ3RnhLNm1VS3ZWaUNQM2MyMmV4YlVjWTUxL0pQa1hpeFBZR1VuMVphU01sOFljbWxtY0VMcWlIL0NoaHo5WApuTFp5SUh5NHh0eXpOcHBQU0Q4cWpOb3Y5K1hEVW5sYkdiem1mNVczQWdNQkFBR2pRakJBTUE0R0ExVWREd0VCCi93UUVBd0lDcERBUEJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJRcUJLQjVOcVk4TE94Yis1ZjcKK0ZaaFZYZ1Q0VEFOQmdrcWhraUc5dzBCQVFzRkFBT0NBUUVBbDU5OVgrWm12b3l1Q3NYZFZwVUFSMEJXWk5kbQpmMHJiUVZuNDJDOEpqVjFoWTZ5aFVqaXRCRW5vYWNsSVFDTUpBQlEwRFlMR1hMVDcwOFRFZEw1YnhHOUJzcHkyCi9haEx6WG5LSXpIc1hKZlZjWVQyUnNQc3l3VVpRUWljNXVDd09RYVlJaTBjN0oxZ21ONmRrMjBjcHZYZVpNc0wKVzlwNXhVVVFEZkk5MUtJZEFPNWFsTXYwQ1hzS1RxTm1MekNWekxIZkhWYjlJMWhKa05EZ3pHdkk1d0VVZUhBVgplWG5VSm0zc284MURVNjgyTHhyR2J4YTVjZFVsZzhuOUFGd2VveE1VcnZxYjI5cFNWczhaL3dSd2hYTERqWmt4Cm5zUmxQbURERXVhWnNPREhUdkNyckh1ZlpxdUVlM0NJTFBNemtOU2M1bUtJZ1Q3MFhWbjN2U01sZ3c9PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==", "versionPriority": 200, "groupPriorityMinimum": 2000}, "status": {"conditions": [{"type": "Available", "reason": "FailedDiscoveryCheck", "status": "False", "message": "failing or missing response from https://10.64.3.118:443/apis/wardle.example.com/v1alpha1: bad status from https://10.64.3.118:443/apis/wardle.example.com/v1alpha1: 403", "lastTransitionTime": "2020-11-23T16:42:19Z"}]}, "metadata": {"uid": "510f4499-2595-4a39-8019-b709a90ba8d9", "name": "v1alpha1.wardle.example.com", "resourceVersion": "11782", "creationTimestamp": "2020-11-23T16:42:19Z"}, "apiVersion": "apiregistration.k8s.io/v1"}, "responseObject": {"kind": "APIService", "spec": {"group": "wardle.example.com", "service": {"name": "sample-api", "port": 7443, "namespace": "aggregator-5443"}, "version": "v1alpha1", "caBundle": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUM5ekNDQWQrZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBREFkTVJzd0dRWURWUVFERXhKbE1tVXQKYzJWeWRtVnlMV05sY25RdFkyRXdIaGNOTWpBeE1USXpNVFkwTWpBNVdoY05NekF4TVRJeE1UWTBNakE1V2pBZApNUnN3R1FZRFZRUURFeEpsTW1VdGMyVnlkbVZ5TFdObGNuUXRZMkV3Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBCkE0SUJEd0F3Z2dFS0FvSUJBUUM5c2wvV3ZycGVpanIzT0tUMFkyd0VXVVhSWEh3YlhBc3FuVVova0JCNUlDYTYKWldHUWd0S2ljUndMMGhEMmhYT1BkZHhjRitoNGp6MHlKdmZZOWhJcVdTUnhBYTlOekY2dDZuSUtQOFRzNmFHNQpHNVN2c3ZLS21jTDBNWGh5VTRKdUdXTjBpWEZtQ05QQTFIcER4STY3cWh3UG95cDVWcnM2QVA5TlJFbWM4cURHCmFqUUJlZno5NzREcTNzWlJmTDRJVWNDdkNEL2ZUb1Q4MTM2NE5JSUFrdjFrTncxODcvK1ArVzhSOEdWcWhvdjAKWEJ3RnhLNm1VS3ZWaUNQM2MyMmV4YlVjWTUxL0pQa1hpeFBZR1VuMVphU01sOFljbWxtY0VMcWlIL0NoaHo5WApuTFp5SUh5NHh0eXpOcHBQU0Q4cWpOb3Y5K1hEVW5sYkdiem1mNVczQWdNQkFBR2pRakJBTUE0R0ExVWREd0VCCi93UUVBd0lDcERBUEJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJRcUJLQjVOcVk4TE94Yis1ZjcKK0ZaaFZYZ1Q0VEFOQmdrcWhraUc5dzBCQVFzRkFBT0NBUUVBbDU5OVgrWm12b3l1Q3NYZFZwVUFSMEJXWk5kbQpmMHJiUVZuNDJDOEpqVjFoWTZ5aFVqaXRCRW5vYWNsSVFDTUpBQlEwRFlMR1hMVDcwOFRFZEw1YnhHOUJzcHkyCi9haEx6WG5LSXpIc1hKZlZjWVQyUnNQc3l3VVpRUWljNXVDd09RYVlJaTBjN0oxZ21ONmRrMjBjcHZYZVpNc0wKVzlwNXhVVVFEZkk5MUtJZEFPNWFsTXYwQ1hzS1RxTm1MekNWekxIZkhWYjlJMWhKa05EZ3pHdkk1d0VVZUhBVgplWG5VSm0zc284MURVNjgyTHhyR2J4YTVjZFVsZzhuOUFGd2VveE1VcnZxYjI5cFNWczhaL3dSd2hYTERqWmt4Cm5zUmxQbURERXVhWnNPREhUdkNyckh1ZlpxdUVlM0NJTFBNemtOU2M1bUtJZ1Q3MFhWbjN2U01sZ3c9PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==", "versionPriority": 200, "groupPriorityMinimum": 2000}, "status": {"conditions": [{"type": "Available", "reason": "FailedDiscoveryCheck", "status": "False", "message": "failing or missing response from https://10.64.3.118:443/apis/wardle.example.com/v1alpha1: bad status from https://10.64.3.118:443/apis/wardle.example.com/v1alpha1: 403", "lastTransitionTime": "2020-11-23T16:42:19Z"}]}, "metadata": {"uid": "510f4499-2595-4a39-8019-b709a90ba8d9", "name": "v1alpha1.wardle.example.com", "resourceVersion": "11786", "creationTimestamp": "2020-11-23T16:42:19Z"}, "apiVersion": "apiregistration.k8s.io/v1"}, "responseStatus": {"code": 200, "metadata": {}}, "stageTimestamp": "2020-11-23T16:42:22.099994Z", "requestReceivedTimestamp": "2020-11-23T16:42:22.097183Z"} | https://prow.k8s.io/view/gcs/kubernetes-jenkins/logs/ci-kubernetes-gce-conformance-latest/1330899902422585344 | 314382 | 2020-11-23 19:01:28.966956
(3 rows)

```

## x26.1

```sql-mode
select data
  from audit_event
 where endpoint ilike '%ApiregistrationV1APIServiceStatus'
 order by endpoint
  limit 3;
```

```example
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   data
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 {"kind": "Event", "user": {"uid": "b9a80a70-e0c5-4b0c-990a-980362af9745", "groups": ["system:masters"], "username": "system:apiserver"}, "verb": "update", "level": "RequestResponse", "stage": "ResponseComplete", "auditID": "9ea4cfc5-25e4-4174-9330-a431625a5751", "objectRef": {"uid": "d94a2e80-6413-494c-8c5f-fa53c56adf96", "name": "v1beta1.metrics.k8s.io", "apiGroup": "apiregistration.k8s.io", "resource": "apiservices", "apiVersion": "v1", "subresource": "status", "resourceVersion": "381"}, "sourceIPs": ["::1"], "userAgent": "kube-apiserver/v1.20.0 (linux/amd64) kubernetes/c1f36fa", "apiVersion": "audit.k8s.io/v1", "requestURI": "/apis/apiregistration.k8s.io/v1/apiservices/v1beta1.metrics.k8s.io/status", "annotations": {"authorization.k8s.io/reason": "", "authorization.k8s.io/decision": "allow"}, "operationId": "replaceApiregistrationV1APIServiceStatus", "requestObject": {"kind": "APIService", "spec": {"group": "metrics.k8s.io", "service": {"name": "metrics-server", "port": 443, "namespace": "kube-system"}, "version": "v1beta1", "versionPriority": 100, "groupPriorityMinimum": 100, "insecureSkipTLSVerify": true}, "status": {"conditions": [{"type": "Available", "reason": "EndpointsNotFound", "status": "False", "message": "cannot find endpoints for service/metrics-server in \"kube-system\"", "lastTransitionTime": "2020-11-25T18:21:58Z"}]}, "metadata": {"uid": "d94a2e80-6413-494c-8c5f-fa53c56adf96", "name": "v1beta1.metrics.k8s.io", "labels": {"kubernetes.io/cluster-service": "true", "addonmanager.kubernetes.io/mode": "Reconcile"}, "annotations": {"kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"apiregistration.k8s.io/v1\",\"kind\":\"APIService\",\"metadata\":{\"annotations\":{},\"labels\":{\"addonmanager.kubernetes.io/mode\":\"Reconcile\",\"kubernetes.io/cluster-service\":\"true\"},\"name\":\"v1beta1.metrics.k8s.io\"},\"spec\":{\"group\":\"metrics.k8s.io\",\"groupPriorityMinimum\":100,\"insecureSkipTLSVerify\":true,\"service\":{\"name\":\"metrics-server\",\"namespace\":\"kube-system\"},\"version\":\"v1beta1\",\"versionPriority\":100}}\n"}, "resourceVersion": "381", "creationTimestamp": "2020-11-25T18:21:58Z"}, "apiVersion": "apiregistration.k8s.io/v1"}, "responseObject": {"kind": "APIService", "spec": {"group": "metrics.k8s.io", "service": {"name": "metrics-server", "port": 443, "namespace": "kube-system"}, "version": "v1beta1", "versionPriority": 100, "groupPriorityMinimum": 100, "insecureSkipTLSVerify": true}, "status": {"conditions": [{"type": "Available", "reason": "EndpointsNotFound", "status": "False", "message": "cannot find endpoints for service/metrics-server in \"kube-system\"", "lastTransitionTime": "2020-11-25T18:21:58Z"}]}, "metadata": {"uid": "d94a2e80-6413-494c-8c5f-fa53c56adf96", "name": "v1beta1.metrics.k8s.io", "labels": {"kubernetes.io/cluster-service": "true", "addonmanager.kubernetes.io/mode": "Reconcile"}, "annotations": {"kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"apiregistration.k8s.io/v1\",\"kind\":\"APIService\",\"metadata\":{\"annotations\":{},\"labels\":{\"addonmanager.kubernetes.io/mode\":\"Reconcile\",\"kubernetes.io/cluster-service\":\"true\"},\"name\":\"v1beta1.metrics.k8s.io\"},\"spec\":{\"group\":\"metrics.k8s.io\",\"groupPriorityMinimum\":100,\"insecureSkipTLSVerify\":true,\"service\":{\"name\":\"metrics-server\",\"namespace\":\"kube-system\"},\"version\":\"v1beta1\",\"versionPriority\":100}}\n"}, "resourceVersion": "395", "creationTimestamp": "2020-11-25T18:21:58Z"}, "apiVersion": "apiregistration.k8s.io/v1"}, "responseStatus": {"code": 200, "metadata": {}}, "stageTimestamp": "2020-11-25T18:21:59.891810Z", "requestReceivedTimestamp": "2020-11-25T18:21:59.888838Z"}
 {"kind": "Event", "user": {"uid": "b9a80a70-e0c5-4b0c-990a-980362af9745", "groups": ["system:masters"], "username": "system:apiserver"}, "verb": "update", "level": "RequestResponse", "stage": "ResponseComplete", "auditID": "66dfeb43-67c8-484b-baf9-2d765fb0f9bb", "objectRef": {"uid": "d94a2e80-6413-494c-8c5f-fa53c56adf96", "name": "v1beta1.metrics.k8s.io", "apiGroup": "apiregistration.k8s.io", "resource": "apiservices", "apiVersion": "v1", "subresource": "status", "resourceVersion": "1026"}, "sourceIPs": ["::1"], "userAgent": "kube-apiserver/v1.20.0 (linux/amd64) kubernetes/c1f36fa", "apiVersion": "audit.k8s.io/v1", "requestURI": "/apis/apiregistration.k8s.io/v1/apiservices/v1beta1.metrics.k8s.io/status", "annotations": {"authorization.k8s.io/reason": "", "authorization.k8s.io/decision": "allow"}, "operationId": "replaceApiregistrationV1APIServiceStatus", "requestObject": {"kind": "APIService", "spec": {"group": "metrics.k8s.io", "service": {"name": "metrics-server", "port": 443, "namespace": "kube-system"}, "version": "v1beta1", "versionPriority": 100, "groupPriorityMinimum": 100, "insecureSkipTLSVerify": true}, "status": {"conditions": [{"type": "Available", "reason": "FailedDiscoveryCheck", "status": "False", "message": "failing or missing response from https://10.64.3.2:443/apis/metrics.k8s.io/v1beta1: Get \"https://10.64.3.2:443/apis/metrics.k8s.io/v1beta1\": net/http: request canceled while waiting for connection (Client.Timeout exceeded while awaiting headers)", "lastTransitionTime": "2020-11-25T18:22:49Z"}]}, "metadata": {"uid": "d94a2e80-6413-494c-8c5f-fa53c56adf96", "name": "v1beta1.metrics.k8s.io", "labels": {"kubernetes.io/cluster-service": "true", "addonmanager.kubernetes.io/mode": "Reconcile"}, "annotations": {"kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"apiregistration.k8s.io/v1\",\"kind\":\"APIService\",\"metadata\":{\"annotations\":{},\"labels\":{\"addonmanager.kubernetes.io/mode\":\"Reconcile\",\"kubernetes.io/cluster-service\":\"true\"},\"name\":\"v1beta1.metrics.k8s.io\"},\"spec\":{\"group\":\"metrics.k8s.io\",\"groupPriorityMinimum\":100,\"insecureSkipTLSVerify\":true,\"service\":{\"name\":\"metrics-server\",\"namespace\":\"kube-system\"},\"version\":\"v1beta1\",\"versionPriority\":100}}\n"}, "resourceVersion": "1026", "creationTimestamp": "2020-11-25T18:21:58Z"}, "apiVersion": "apiregistration.k8s.io/v1"}, "responseObject": {"kind": "APIService", "spec": {"group": "metrics.k8s.io", "service": {"name": "metrics-server", "port": 443, "namespace": "kube-system"}, "version": "v1beta1", "versionPriority": 100, "groupPriorityMinimum": 100, "insecureSkipTLSVerify": true}, "status": {"conditions": [{"type": "Available", "reason": "FailedDiscoveryCheck", "status": "False", "message": "failing or missing response from https://10.64.3.2:443/apis/metrics.k8s.io/v1beta1: Get \"https://10.64.3.2:443/apis/metrics.k8s.io/v1beta1\": net/http: request canceled while waiting for connection (Client.Timeout exceeded while awaiting headers)", "lastTransitionTime": "2020-11-25T18:22:49Z"}]}, "metadata": {"uid": "d94a2e80-6413-494c-8c5f-fa53c56adf96", "name": "v1beta1.metrics.k8s.io", "labels": {"kubernetes.io/cluster-service": "true", "addonmanager.kubernetes.io/mode": "Reconcile"}, "annotations": {"kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"apiregistration.k8s.io/v1\",\"kind\":\"APIService\",\"metadata\":{\"annotations\":{},\"labels\":{\"addonmanager.kubernetes.io/mode\":\"Reconcile\",\"kubernetes.io/cluster-service\":\"true\"},\"name\":\"v1beta1.metrics.k8s.io\"},\"spec\":{\"group\":\"metrics.k8s.io\",\"groupPriorityMinimum\":100,\"insecureSkipTLSVerify\":true,\"service\":{\"name\":\"metrics-server\",\"namespace\":\"kube-system\"},\"version\":\"v1beta1\",\"versionPriority\":100}}\n"}, "resourceVersion": "1037", "creationTimestamp": "2020-11-25T18:21:58Z"}, "apiVersion": "apiregistration.k8s.io/v1"}, "responseStatus": {"code": 200, "metadata": {}}, "stageTimestamp": "2020-11-25T18:23:56.414193Z", "requestReceivedTimestamp": "2020-11-25T18:23:56.411003Z"}
 {"kind": "Event", "user": {"uid": "b9a80a70-e0c5-4b0c-990a-980362af9745", "groups": ["system:masters"], "username": "system:apiserver"}, "verb": "update", "level": "RequestResponse", "stage": "ResponseComplete", "auditID": "59b2505a-32d3-48fc-aa1c-8ceb24fdf59c", "objectRef": {"uid": "6d211f52-e489-4064-8e0a-8b66e5f692d1", "name": "v1alpha1.wardle.example.com", "apiGroup": "apiregistration.k8s.io", "resource": "apiservices", "apiVersion": "v1", "subresource": "status", "resourceVersion": "22129"}, "sourceIPs": ["::1"], "userAgent": "kube-apiserver/v1.20.0 (linux/amd64) kubernetes/c1f36fa", "apiVersion": "audit.k8s.io/v1", "requestURI": "/apis/apiregistration.k8s.io/v1/apiservices/v1alpha1.wardle.example.com/status", "annotations": {"authorization.k8s.io/reason": "", "authorization.k8s.io/decision": "allow"}, "operationId": "replaceApiregistrationV1APIServiceStatus", "requestObject": {"kind": "APIService", "spec": {"group": "wardle.example.com", "service": {"name": "sample-api", "port": 7443, "namespace": "aggregator-1453"}, "version": "v1alpha1", "caBundle": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUM5ekNDQWQrZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBREFkTVJzd0dRWURWUVFERXhKbE1tVXQKYzJWeWRtVnlMV05sY25RdFkyRXdIaGNOTWpBeE1USTFNVGd6TURRNVdoY05NekF4TVRJek1UZ3pNRFE1V2pBZApNUnN3R1FZRFZRUURFeEpsTW1VdGMyVnlkbVZ5TFdObGNuUXRZMkV3Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBCkE0SUJEd0F3Z2dFS0FvSUJBUURZWWpLQU5LdVRkQmdlTzFoZXpXM00yS2Rabk10bzkweW42RWl5TmhheEJ2d1UKemtvQWpReUNhWXd0MHd1U2RQWW1tbXZycEhWZmdDYnE5a3ZTbndJMzdWaGYvMWNCOGs2Z2dJQVlUT2psajJnaQpMVVZOMTFLNVBCNkxnQjlBTzY3aC83UmxRZStPQ3ZDYzRCcmZUeGxRTS9TRC82aGIrcHJYMDUrSmJ4NVRab01tCjNqK2RRa2lMbjV3WWh1TUFJQWx1WlVXM0oydFpON29IUDhsOG4waDJyMWR4MmZRTzFXektYTXd2VGxEWk5OUTcKc3l6cFN4VW1BS3ZhYVVnNlJzK2h0OHpaS3FkNDVKK3ZDamE1VHVMV3B6eGFRWU04NTdNYjRaMzUwYzh1ek9nQQpVTkNnU00zU1lPM1REQmQrNVZoNktqenN1VDJJMGNGcG80dXVPZEx4QWdNQkFBR2pRakJBTUE0R0ExVWREd0VCCi93UUVBd0lDcERBUEJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJUamNaalpuSFY3MkdZOHFBejAKZmxwUENPS3JQakFOQmdrcWhraUc5dzBCQVFzRkFBT0NBUUVBUFIreG40U1pEd2NPbjlndVExZGE4d3BaeTRrSApzN2NxaHBWakFEZ3ZNRUdVMmEweGFIQ2RsaVdpL1hHYWkxNUVqZzBhOWRSMTFlYnNTVjRTRnlrVU8wekJMWFYrCjF5dVd5Ti9SMGMyck4xZWI0SStvZXoybFB1TlJLQjU3cU1TbEoxOGlJWkR6bjFtdVJNeTN4cHZXckJGS1VoZjcKZDlEdDh1YzB0UDJZTTBYTlVveDl0ZytNZldwK3pJOW5kdGU4T0hqWStMbXlSdFI0QUhBMFF5UkY2byswZVZtQwpIcHEwSHlYOVpxMzhoY0NMRHRqM1FUWmx3dmx4bVg3V1pRbW94QitkS29HNUlHbDJwbGlraVFhRzFidDA5eHdwCmJpNFhOeG1QdWNMWFcyVjJZMEEraGlFbW1DTG5JUk9YbHdEd3pqK3c5U3hjcFVFYU9oc3F4eDNSUnc9PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==", "versionPriority": 200, "groupPriorityMinimum": 2000}, "status": {"conditions": [{"type": "Available", "reason": "Passed", "status": "True", "message": "all checks passed", "lastTransitionTime": "2020-11-25T18:31:06Z"}]}, "metadata": {"uid": "6d211f52-e489-4064-8e0a-8b66e5f692d1", "name": "v1alpha1.wardle.example.com", "resourceVersion": "22129", "creationTimestamp": "2020-11-25T18:31:05Z"}, "apiVersion": "apiregistration.k8s.io/v1"}, "responseObject": {"kind": "APIService", "spec": {"group": "wardle.example.com", "service": {"name": "sample-api", "port": 7443, "namespace": "aggregator-1453"}, "version": "v1alpha1", "caBundle": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUM5ekNDQWQrZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBREFkTVJzd0dRWURWUVFERXhKbE1tVXQKYzJWeWRtVnlMV05sY25RdFkyRXdIaGNOTWpBeE1USTFNVGd6TURRNVdoY05NekF4TVRJek1UZ3pNRFE1V2pBZApNUnN3R1FZRFZRUURFeEpsTW1VdGMyVnlkbVZ5TFdObGNuUXRZMkV3Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBCkE0SUJEd0F3Z2dFS0FvSUJBUURZWWpLQU5LdVRkQmdlTzFoZXpXM00yS2Rabk10bzkweW42RWl5TmhheEJ2d1UKemtvQWpReUNhWXd0MHd1U2RQWW1tbXZycEhWZmdDYnE5a3ZTbndJMzdWaGYvMWNCOGs2Z2dJQVlUT2psajJnaQpMVVZOMTFLNVBCNkxnQjlBTzY3aC83UmxRZStPQ3ZDYzRCcmZUeGxRTS9TRC82aGIrcHJYMDUrSmJ4NVRab01tCjNqK2RRa2lMbjV3WWh1TUFJQWx1WlVXM0oydFpON29IUDhsOG4waDJyMWR4MmZRTzFXektYTXd2VGxEWk5OUTcKc3l6cFN4VW1BS3ZhYVVnNlJzK2h0OHpaS3FkNDVKK3ZDamE1VHVMV3B6eGFRWU04NTdNYjRaMzUwYzh1ek9nQQpVTkNnU00zU1lPM1REQmQrNVZoNktqenN1VDJJMGNGcG80dXVPZEx4QWdNQkFBR2pRakJBTUE0R0ExVWREd0VCCi93UUVBd0lDcERBUEJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJUamNaalpuSFY3MkdZOHFBejAKZmxwUENPS3JQakFOQmdrcWhraUc5dzBCQVFzRkFBT0NBUUVBUFIreG40U1pEd2NPbjlndVExZGE4d3BaeTRrSApzN2NxaHBWakFEZ3ZNRUdVMmEweGFIQ2RsaVdpL1hHYWkxNUVqZzBhOWRSMTFlYnNTVjRTRnlrVU8wekJMWFYrCjF5dVd5Ti9SMGMyck4xZWI0SStvZXoybFB1TlJLQjU3cU1TbEoxOGlJWkR6bjFtdVJNeTN4cHZXckJGS1VoZjcKZDlEdDh1YzB0UDJZTTBYTlVveDl0ZytNZldwK3pJOW5kdGU4T0hqWStMbXlSdFI0QUhBMFF5UkY2byswZVZtQwpIcHEwSHlYOVpxMzhoY0NMRHRqM1FUWmx3dmx4bVg3V1pRbW94QitkS29HNUlHbDJwbGlraVFhRzFidDA5eHdwCmJpNFhOeG1QdWNMWFcyVjJZMEEraGlFbW1DTG5JUk9YbHdEd3pqK3c5U3hjcFVFYU9oc3F4eDNSUnc9PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==", "versionPriority": 200, "groupPriorityMinimum": 2000}, "status": {"conditions": [{"type": "Available", "reason": "Passed", "status": "True", "message": "all checks passed", "lastTransitionTime": "2020-11-25T18:31:06Z"}]}, "metadata": {"uid": "6d211f52-e489-4064-8e0a-8b66e5f692d1", "name": "v1alpha1.wardle.example.com", "resourceVersion": "22130", "creationTimestamp": "2020-11-25T18:31:05Z"}, "apiVersion": "apiregistration.k8s.io/v1"}, "responseStatus": {"code": 200, "metadata": {}}, "stageTimestamp": "2020-11-25T18:31:06.235737Z", "requestReceivedTimestamp": "2020-11-25T18:31:06.170440Z"}
(3 rows)

```

## x26.2

```sql-mode
select data->>'verb' as verb, data->'objectRef'->'name' as name, data->>'requestURI' as "requestURI", test
  from audit_event
 where data->'objectRef'->>'name' like 'v1alpha1.wardle.example.com%'
 order by endpoint
  limit 20;
```

```example
  verb  |             name              |                                   requestURI                                   |                                                              test
--------|-------------------------------|--------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------
 create | "v1alpha1.wardle.example.com" | /apis/apiregistration.k8s.io/v1/apiservices                                    | [sig-api-machinery] Aggregator Should be able to support the 1.17 Sample API Server using the current Aggregator [Conformance]
 create | "v1alpha1.wardle.example.com" | /apis/apiregistration.k8s.io/v1/apiservices                                    | [sig-api-machinery] Aggregator Should be able to support the 1.17 Sample API Server using the current Aggregator [Conformance]
 delete | "v1alpha1.wardle.example.com" | /apis/apiregistration.k8s.io/v1/apiservices/v1alpha1.wardle.example.com        | [sig-api-machinery] Aggregator Should be able to support the 1.17 Sample API Server using the current Aggregator [Conformance]
 delete | "v1alpha1.wardle.example.com" | /apis/apiregistration.k8s.io/v1/apiservices/v1alpha1.wardle.example.com        | [sig-api-machinery] Aggregator Should be able to support the 1.17 Sample API Server using the current Aggregator [Conformance]
 delete | "v1alpha1.wardle.example.com" | /apis/apiregistration.k8s.io/v1/apiservices/v1alpha1.wardle.example.com        | [sig-api-machinery] Aggregator Should be able to support the 1.17 Sample API Server using the current Aggregator [Conformance]
 delete | "v1alpha1.wardle.example.com" | /apis/apiregistration.k8s.io/v1/apiservices/v1alpha1.wardle.example.com        | [sig-api-machinery] Aggregator Should be able to support the 1.17 Sample API Server using the current Aggregator [Conformance]
 get    | "v1alpha1.wardle.example.com" | /apis/apiregistration.k8s.io/v1/apiservices/v1alpha1.wardle.example.com        | [sig-api-machinery] Aggregator Should be able to support the 1.17 Sample API Server using the current Aggregator [Conformance]
 get    | "v1alpha1.wardle.example.com" | /apis/apiregistration.k8s.io/v1/apiservices/v1alpha1.wardle.example.com        | [sig-api-machinery] Aggregator Should be able to support the 1.17 Sample API Server using the current Aggregator [Conformance]
 get    | "v1alpha1.wardle.example.com" | /apis/apiregistration.k8s.io/v1/apiservices/v1alpha1.wardle.example.com        | [sig-api-machinery] Aggregator Should be able to support the 1.17 Sample API Server using the current Aggregator [Conformance]
 get    | "v1alpha1.wardle.example.com" | /apis/apiregistration.k8s.io/v1/apiservices/v1alpha1.wardle.example.com        | [sig-api-machinery] Aggregator Should be able to support the 1.17 Sample API Server using the current Aggregator [Conformance]
 get    | "v1alpha1.wardle.example.com" | /apis/apiregistration.k8s.io/v1/apiservices/v1alpha1.wardle.example.com        | [sig-api-machinery] Aggregator Should be able to support the 1.17 Sample API Server using the current Aggregator [Conformance]
 get    | "v1alpha1.wardle.example.com" | /apis/apiregistration.k8s.io/v1/apiservices/v1alpha1.wardle.example.com        | [sig-api-machinery] Aggregator Should be able to support the 1.17 Sample API Server using the current Aggregator [Conformance]
 get    | "v1alpha1.wardle.example.com" | /apis/apiregistration.k8s.io/v1/apiservices/v1alpha1.wardle.example.com        | [sig-api-machinery] Aggregator Should be able to support the 1.17 Sample API Server using the current Aggregator [Conformance]
 update | "v1alpha1.wardle.example.com" | /apis/apiregistration.k8s.io/v1/apiservices/v1alpha1.wardle.example.com/status |
 update | "v1alpha1.wardle.example.com" | /apis/apiregistration.k8s.io/v1/apiservices/v1alpha1.wardle.example.com/status |
 update | "v1alpha1.wardle.example.com" | /apis/apiregistration.k8s.io/v1/apiservices/v1alpha1.wardle.example.com/status |
(16 rows)

```
