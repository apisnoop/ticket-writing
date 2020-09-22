# Progress <code>[2/5]</code>

-   [X] APISnoop org-flow : [MyEndpoint.org](https://github.com/cncf/apisnoop/blob/master/tickets/k8s/)
-   [X] test approval issue : [kubernetes/kubernetes#](https://github.com/kubernetes/kubernetes/issues/)
-   [ ] test pr : kuberenetes/kubernetes#
-   [ ] two weeks soak start date : testgrid-link
-   [ ] two weeks soak end date :
-   [ ] test promotion pr : kubernetes/kubernetes#?

# Identifying an untested feature Using APISnoop

According to this APIsnoop query, there are still some remaining RESOURCENAME endpoints which are untested.

with this query you can filter untested endpoints by their category and eligiblity for conformance. e.g below shows a query to find all conformance eligible untested,stable,core endpoints

```sql-mode
SELECT
  endpoint,
  -- k8s_action,
  -- path,
  -- description,
  kind
  FROM testing.untested_stable_endpoint
  where eligible is true
  -- and category = 'core'
    and endpoint ilike '%PriorityClass%'
  order by kind, endpoint desc
  limit 25;
```

```example
                 endpoint                  |     kind
-------------------------------------------|---------------
 replaceSchedulingV1PriorityClass          | PriorityClass
 readSchedulingV1PriorityClass             | PriorityClass
 patchSchedulingV1PriorityClass            | PriorityClass
 listSchedulingV1PriorityClass             | PriorityClass
 deleteSchedulingV1CollectionPriorityClass | PriorityClass
(5 rows)

```

# API Reference and feature documentation

-   [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/kubernetes-api/)
-   [client-go - RESOURCENAME](https://github.com/kubernetes/client-go/blob/master/kubernetes/typed/core/v1/RESOURCENAME.go)

# The mock test

## Test outline

1.  Create a RESOURCENAME with a static label

2.  Patch the RESOURCENAME with a new label and updated data

3.  Get the RESOURCENAME to ensure it's patched

4.  List all RESOURCENAMEs in all Namespaces with a static label find the RESOURCENAME ensure that the RESOURCENAME is found and is patched

5.  Delete Namespaced RESOURCENAME via a Collection with a LabelSelector

## Test the functionality in Go

```go
package main

import (
  // "encoding/json"
  "fmt"
  "context"
  "flag"
  "os"
  v1 "k8s.io/api/core/v1"
  // "k8s.io/client-go/dynamic"
  // "k8s.io/apimachinery/pkg/runtime/schema"
  metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
  "k8s.io/client-go/kubernetes"
  // "k8s.io/apimachinery/pkg/types"
  "k8s.io/client-go/tools/clientcmd"
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
  // DynamicClientSet, _ := dynamic.NewForConfig(config)
  // podResource := schema.GroupVersionResource{Group: "", Version: "v1", Resource: "pods"}

  // TEST BEGINS HERE

  testPodName := "test-pod"
  testPodImage := "nginx"
  testNamespaceName := "default"

  fmt.Println("creating a Pod")
  testPod := v1.Pod{
    ObjectMeta: metav1.ObjectMeta{
      Name: testPodName,
      Labels: map[string]string{"test-pod-static": "true"},
    },
    Spec: v1.PodSpec{
      Containers: []v1.Container{{
        Name: testPodName,
        Image: testPodImage,
      }},
    },
  }
  _, err = ClientSet.CoreV1().Pods(testNamespaceName).Create(context.TODO(), &testPod, metav1.CreateOptions{})
  if err != nil {
      fmt.Println(err, "failed to create Pod")
      return
  }

  fmt.Println("listing Pods")
  pods, err := ClientSet.CoreV1().Pods("").List(context.TODO(), metav1.ListOptions{LabelSelector: "test-pod-static=true"})
  if err != nil {
      fmt.Println(err, "failed to list Pods")
      return
  }
  podCount := len(pods.Items)
  if podCount == 0 {
      fmt.Println("there are no Pods found")
      return
  }
  fmt.Println(podCount, "Pod(s) found")

  fmt.Println("deleting Pod")
  err = ClientSet.CoreV1().Pods(testNamespaceName).Delete(context.TODO(), testPodName, metav1.DeleteOptions{})
  if err != nil {
      fmt.Println(err, "failed to delete the Pod")
      return
  }

  // TEST ENDS HERE

  fmt.Println("[status] complete")

}
```

    creating a Pod
    listing Pods
    1 Pod(s) found
    deleting Pod
    [status] complete

# Verifying increase in coverage with APISnoop

Discover useragents:

```sql-mode
select distinct useragent
  from testing.audit_event
  where useragent like 'live%';
```

     useragent
    -----------
    (0 rows)

List endpoints hit by the test:

```sql-mode
select * from testing.endpoint_hit_by_new_test;
```

Display endpoint coverage change:

```sql-mode
select * from testing.projected_change_in_coverage;
```

```example
   category    | total_endpoints | old_coverage | new_coverage | change_in_number
---------------|-----------------|--------------|--------------|------------------
 test_coverage |             438 |          183 |          183 |                0
(1 row)

```

# Final notes

If a test with these calls gets merged, ****test coverage will go up by N points****

This test is also created with the goal of conformance promotion.

---

/sig testing

/sig architecture

/area conformance
