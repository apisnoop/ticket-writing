# Progress <code>[3/6]</code>

-   [X] APISnoop org-flow : [ServiceStatusLifeCycleTest.org](https://github.com/apisnoop/ticket-writing/blob/master/ServiceStatusLiveCycleTest.org)
-   [X] test approval issue : [kubernetes/kubernetes#94867](https://github.com/kubernetes/kubernetes/issues/94867)
-   [X] test pr : [kubernetes/kubernetes/pull/98018](https://github.com/kubernetes/kubernetes/pull/98018)
-   [ ] two weeks soak start date : testgrid-link
-   [ ] two weeks soak end date :
-   [ ] test promotion pr : kubernetes/kubernetes#


# Identifying an untested feature Using APISnoop

According to this APIsnoop query, there are still some remaining RESOURCENAME endpoints which are untested.

with this query you can filter untested endpoints by their category and eligiblity for conformance. e.g below shows a query to find all conformance eligible untested,stable,core endpoints

```sql-mode
    SELECT
      endpoint,
      path,
      kind
      FROM testing.untested_stable_endpoint
      where eligible is true
      and category = 'core'
        and kind ilike '%Service'
      order by kind, endpoint desc
      limit 10;
```

```example
                 endpoint               |                         path                          |  kind
  --------------------------------------+-------------------------------------------------------+---------
   replaceCoreV1NamespacedServiceStatus | /api/v1/namespaces/{namespace}/services/{name}/status | Service
   readCoreV1NamespacedServiceStatus    | /api/v1/namespaces/{namespace}/services/{name}/status | Service
   patchCoreV1NamespacedServiceStatus   | /api/v1/namespaces/{namespace}/services/{name}/status | Service
   patchCoreV1NamespacedService         | /api/v1/namespaces/{namespace}/services/{name}        | Service
  (4 rows)

```

**Note:** Community feedback for the e2e test has lead to a number of improvements including extending the test coverage to all outstanding endpoints listed above. As each endpoint is tested a &rsquo;watch&rsquo; confirms that the result is valid before testing the next endpoint.

-   readCoreV1NamespacedServiceStatus (get /status)
-   patchCoreV1NamespacedServiceStatus (patch /status)
-   replaceCoreV1NamespacedServiceStatus (update /status)
-   patchCoreV1NamespacedService


# API Reference and feature documentation

-   [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/kubernetes-api/)
-   [client-go - RESOURCENAME](https://github.com/kubernetes/client-go/blob/master/kubernetes/typed/core/v1/RESOURCENAME.go)


# The mock test


## Test outline

1.  Create a Service with a static label

2.  Patch the Service with a new label and updated data

3.  Get the Service to ensure it&rsquo;s patched

4.  Upate the Service with a new label and updated data

5.  Get the Service to ensure it&rsquo;s updated

6.  Delete Namespaced Service via a Collection with a LabelSelector


## Test the functionality in Go

```go
     package main

     import (
       "context"
       "encoding/json"
       "flag"
       "fmt"
       v1 "k8s.io/api/core/v1"
       metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
       "k8s.io/apimachinery/pkg/runtime/schema"
       "k8s.io/apimachinery/pkg/types"
       "k8s.io/apimachinery/pkg/util/intstr"
       watch "k8s.io/apimachinery/pkg/watch"
       "k8s.io/client-go/dynamic"
       "k8s.io/client-go/kubernetes"
       "k8s.io/client-go/tools/clientcmd"
       "os"
     )

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
       DynamicClientSet, _ := dynamic.NewForConfig(config)
       svcResource := schema.GroupVersionResource{Group: "", Version: "v1", Resource: "services"}

       // TEST BEGINS HERE

       testServiceName := "test-service"
       testNamespaceName := "default"

       fmt.Println("creating a Service")
       testService := v1.Service{
         ObjectMeta: metav1.ObjectMeta{
           Name:   testServiceName,
           Labels: map[string]string{"test-service-static": "true"},
         },
         Spec: v1.ServiceSpec{
           Type: "ClusterIP",
           Ports: []v1.ServicePort{{
             Name:       "http",
             Protocol:   v1.ProtocolTCP,
             Port:       int32(80),
             TargetPort: intstr.FromInt(80),
           }},
         },
       }
       _, err = ClientSet.CoreV1().Services(testNamespaceName).Create(context.TODO(), &testService, metav1.CreateOptions{})
       if err != nil {
         fmt.Println(err, "failed to create Service")
         return
       }

       fmt.Println("watching for the Service to be added")
       svcWatchTimeoutSeconds := int64(180)
       svcWatch, err := ClientSet.CoreV1().Services(testNamespaceName).Watch(context.TODO(), metav1.ListOptions{LabelSelector: "test-service-static=true", TimeoutSeconds: &svcWatchTimeoutSeconds})
       if err != nil {
         fmt.Println(err, "failed to create service")
         return
       }

       svcWatchChan := svcWatch.ResultChan()

       for event := range svcWatchChan {
         if event.Type == watch.Added {
           break
         }
       }

       // fmt.Println(testService)
       fmt.Println("patching the ServiceStatus")
       serviceStatusPatch, err := json.Marshal(map[string]interface{}{
         "metadata": map[string]interface{}{
           "labels": map[string]string{"test-service": "patched"},
         },
         "spec": map[string]interface{}{
           "ports": []map[string]interface{}{{
             "name":       "http8080",
             "port":       int32(8080),
             "targetPort": int(8080),
             "selector": []map[string]interface{}{{
               "type": "LoadBalancer",
             }},
           }},
         },
       })
       if err != nil {
         fmt.Println(err)
         return
       }
       svcStatus, err := DynamicClientSet.Resource(svcResource).Namespace(testNamespaceName).Patch(context.TODO(), testServiceName, types.StrategicMergePatchType, []byte(serviceStatusPatch), metav1.PatchOptions{}, "status")
       if err != nil {
         fmt.Println(err)
         return
       }

       for event := range svcWatchChan {
         if event.Type == watch.Modified {
           break
         }
       }

       svcStatus, err = DynamicClientSet.Resource(svcResource).Namespace(testNamespaceName).Get(context.TODO(), testServiceName, metav1.GetOptions{}, "status")
       if err != nil {
         fmt.Println(err)
         return
       }

       var svcStatusGet v1.Service
       svcStatusUjson, err := json.Marshal(svcStatus)
       if err != nil {
         fmt.Println(err, "Failed to marshal json of replicationcontroller label patch")
         return
       }

       json.Unmarshal(svcStatusUjson, &svcStatusGet)
       //   fmt.Println(svcStatusGet)
       if !(svcStatusGet.ObjectMeta.Labels["test-service"] == "patched") {
         fmt.Println("failed to patch the Service")
       }

       fmt.Println("updating the ServiceStatus")
       svcStatusGet.Spec.Ports[0].Name = "http8081"
       svcStatusGet.Spec.Ports[0].Port = int32(8081)
       svcStatusGet.ObjectMeta.Labels["test-service"] = "updated"
       _, err = ClientSet.CoreV1().Services(testNamespaceName).Update(context.TODO(), &svcStatusGet, metav1.UpdateOptions{})
       if err != nil {
         fmt.Println(err)
         return
       }

       for event := range svcWatchChan {
         if event.Type == watch.Modified {
           break
         }
       }

       fmt.Println("finding Service in list")
       svcs, err := ClientSet.CoreV1().Services("").List(context.TODO(), metav1.ListOptions{LabelSelector: "test-service-static=true"})
       if err != nil {
         fmt.Println(err)
         return
       }
       // fmt.Println(svcs)
       foundSvc := false
       for _, svcItem := range svcs.Items {
         if svcItem.ObjectMeta.Name == testServiceName &&
           svcItem.ObjectMeta.Namespace == testNamespaceName &&
           svcItem.ObjectMeta.Labels["test-service"] == "updated" &&
           svcItem.Spec.Ports[0].Name == "http8081" &&
           svcItem.Spec.Ports[0].Port == int32(8081) {
           foundSvc = true
           break
         }
       }
       if foundSvc != true {
         fmt.Println("unable to find Service in list of Services")
         return
       }

       fmt.Println("deleting the service")
       err = ClientSet.CoreV1().Services(testNamespaceName).Delete(context.TODO(), testServiceName, metav1.DeleteOptions{})
       if err != nil {
         fmt.Println(err, "failed to delete the Service")
         return
       }

       // TEST ENDS HERE

       fmt.Println("[status] complete")

     }
```

```go
   creating a Service
   watching for the Service to be added
   patching the ServiceStatus
   updating the ServiceStatus
   finding Service in list
   deleting the service
   [status] complete
```


# Verifying increase in coverage with APISnoop


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
     useragent     |              endpoint              | hit_by_ete | hit_by_new_test
-------------------+------------------------------------+------------+-----------------
 live-test-writing | createCoreV1NamespacedService      | t          |              30
 live-test-writing | deleteCoreV1NamespacedService      | t          |              30
 live-test-writing | listCoreV1NamespacedService        | t          |              45
 live-test-writing | listCoreV1ServiceForAllNamespaces  | t          |              30
 live-test-writing | patchCoreV1NamespacedServiceStatus | f          |              30
 live-test-writing | readCoreV1NamespacedServiceStatus  | f          |              30
 live-test-writing | replaceCoreV1NamespacedService     | t          |              30
(7 rows)

```


## Display endpoint coverage change:

```sql-mode
    select * from testing.projected_change_in_coverage;
```

```example
     category    | total_endpoints | old_coverage | new_coverage | change_in_number
  ---------------+-----------------+--------------+--------------+------------------
   test_coverage |             831 |          305 |          307 |                2
  (1 row)

```


## Service endpoints hit after e2e test run

This query by apisnoop shows that all outstanding endpoints as list at the start of this document have been hit by the e2e test. Note that the results do include other service endpoints that have been addressed in other conformance tests.

```sql-mode
select distinct  endpoint, right(useragent,65) AS useragent
from   testing.audit_event
where  useragent like 'e2e%Services should complete a service status lifecycle%'
and   (endpoint ilike '%NamespacedServiceStatus'
      or endpoint ilike '%NamespacedService')
and release_date::BIGINT > round(((EXTRACT(EPOCH FROM NOW()))::numeric)*1000,0) - 60000
order by endpoint
limit 20;
```

```example
               endpoint               |                             useragent
--------------------------------------+-------------------------------------------------------------------
 createCoreV1NamespacedService        | [sig-network] Services should complete a service status lifecycle
 deleteCoreV1NamespacedService        | [sig-network] Services should complete a service status lifecycle
 listCoreV1NamespacedService          | [sig-network] Services should complete a service status lifecycle
 patchCoreV1NamespacedService         | [sig-network] Services should complete a service status lifecycle
 patchCoreV1NamespacedServiceStatus   | [sig-network] Services should complete a service status lifecycle
 readCoreV1NamespacedService          | [sig-network] Services should complete a service status lifecycle
 readCoreV1NamespacedServiceStatus    | [sig-network] Services should complete a service status lifecycle
 replaceCoreV1NamespacedServiceStatus | [sig-network] Services should complete a service status lifecycle
(8 rows)

```


# Final notes

If a test with these calls gets merged, **test coverage will go up by 4 points**

This test is also created with the goal of conformance promotion.

---

/sig testing

/sig architecture

/area conformance
