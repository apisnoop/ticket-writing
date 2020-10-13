# Progress <code>[1/6]</code>

-   [X] APISnoop org-flow : [ServiceProxyWithPath.org](https://github.com/cncf/apisnoop/blob/master/tickets/k8s/ServiceProxyWithPath.org)
-   [ ] test approval issue : [kubernetes/kubernetes#](https://github.com/kubernetes/kubernetes/issues/)
-   [ ] test pr : kuberenetes/kubernetes#
-   [ ] two weeks soak start date : testgrid-link
-   [ ] two weeks soak end date :
-   [ ] test promotion pr : kubernetes/kubernetes#?

# Identifying an untested feature Using APISnoop

According to this APIsnoop query, there are still some remaining ProxyWithPath endpoints which are untested.

with this query you can filter untested endpoints by their category and eligiblity for conformance. e.g below shows a query to find all conformance eligible untested,stable,core endpoints

```sql-mode
SELECT
  endpoint,
  -- k8s_action,
  path,
  -- description,
  kind
  FROM testing.untested_stable_endpoint
  where eligible is true
  and category = 'core'
  and endpoint like '%ServiceProxyWithPath'
  order by kind, endpoint desc
  limit 25;
```

```example
                      endpoint                      |                            path                             |        kind
----------------------------------------------------|-------------------------------------------------------------|---------------------
 connectCoreV1PutNamespacedServiceProxyWithPath     | /api/v1/namespaces/{namespace}/services/{name}/proxy/{path} | ServiceProxyOptions
 connectCoreV1PostNamespacedServiceProxyWithPath    | /api/v1/namespaces/{namespace}/services/{name}/proxy/{path} | ServiceProxyOptions
 connectCoreV1PatchNamespacedServiceProxyWithPath   | /api/v1/namespaces/{namespace}/services/{name}/proxy/{path} | ServiceProxyOptions
 connectCoreV1OptionsNamespacedServiceProxyWithPath | /api/v1/namespaces/{namespace}/services/{name}/proxy/{path} | ServiceProxyOptions
 connectCoreV1HeadNamespacedServiceProxyWithPath    | /api/v1/namespaces/{namespace}/services/{name}/proxy/{path} | ServiceProxyOptions
 connectCoreV1DeleteNamespacedServiceProxyWithPath  | /api/v1/namespaces/{namespace}/services/{name}/proxy/{path} | ServiceProxyOptions
(6 rows)

```

# API Reference and feature documentation

-   [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/kubernetes-api/)
-   [client-go](https://github.com/kubernetes/client-go/blob/master/kubernetes/typed/core/v1)
-   [Kubernetes 1.19: Service v1 Core: Proxy Operations](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.19/#-strong-proxy-operations-service-v1-core-strong-)

# The mock test

## Test outline

1.  Create a pod with a static label using the agnhost image

2.  Confirm that the pod is in the running phase

3.  Create a service and link it to the pod

4.  Iterate through a list of http methods and check the response from the porter app

5.  Confirm that each response code is 200 OK

## Test the functionality in Go

```go
package main

import (
  // "encoding/json"
  "context"
  "flag"
  "fmt"
  "net/http"
  "os"
  "time"

  v1 "k8s.io/api/core/v1"
  // "k8s.io/client-go/dynamic"
  // "k8s.io/apimachinery/pkg/runtime/schema"
  metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
  "k8s.io/apimachinery/pkg/util/wait"
  "k8s.io/client-go/kubernetes"
  "k8s.io/client-go/transport"
  // "k8s.io/apimachinery/pkg/types"
  "k8s.io/client-go/tools/clientcmd"
  "k8s.io/apimachinery/pkg/util/intstr"
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

const (
  podRetryPeriod  = 1 * time.Second
  podRetryTimeout = 1 * time.Minute
)

func main() {
  // uses the current context in kubeconfig
  kubeconfig := flag.String("kubeconfig", fmt.Sprintf("%v/%v/%v", os.Getenv("HOME"), ".kube", "config"), "(optional) absolute path to the kubeconfig file")
  flag.Parse()
  config, err := clientcmd.BuildConfigFromFlags("", *kubeconfig)
  ExpectNoError(err, "Could not build config from flags")
  // make our work easier to find in the audit_event queries
  config.UserAgent = "live-test-writing"
  // creates the clientset
  ClientSet, _ := kubernetes.NewForConfig(config)
  // DynamicClientSet, _ := dynamic.NewForConfig(config)
  // podResource := schema.GroupVersionResource{Group: "", Version: "v1", Resource: "pods"}

  // TEST BEGINS HERE

  ns := "default" // f.Namespace.Name

  fmt.Println("Creating pod...")
  _, err = ClientSet.CoreV1().Pods(ns).Create(context.TODO(), &v1.Pod{
    ObjectMeta: metav1.ObjectMeta{
      Name: "agnhost",
      Labels: map[string]string{
        "test": "response"},
    },
    Spec: v1.PodSpec{
      Containers: []v1.Container{{
        Image:   "us.gcr.io/k8s-artifacts-prod/e2e-test-images/agnhost:2.21",
        Name:    "agnhost",
        Command: []string{"/agnhost", "porter"},
        Env: []v1.EnvVar{{
          Name:  "SERVE_PORT_80",
          Value: "foo",
        }},
      }},
      RestartPolicy: v1.RestartPolicyNever,
    }}, metav1.CreateOptions{})
  ExpectNoError(err, "failed to create pod")

  err = wait.PollImmediate(podRetryPeriod, podRetryTimeout, checkPodStatus(ClientSet, "test=response"))
  ExpectNoError(err, "Pod didn't start within time out period")

  _, err = ClientSet.CoreV1().Services(ns).Create(context.TODO(), &v1.Service{
    ObjectMeta: metav1.ObjectMeta{
      Name: "test-service",
      Namespace: ns,
      Labels: map[string]string{
        "test": "response",
      },
    },
    Spec: v1.ServiceSpec{
      Ports: []v1.ServicePort{{
        Port: 80,
        TargetPort: intstr.FromInt(80),
        Protocol: v1.ProtocolTCP,
      }},
      Selector: map[string]string{
        "test": "response",
      },
    }}, metav1.CreateOptions{})
  ExpectNoError(err, "Failed to create the service")
  fmt.Println("Service created")

  transportCfg, err := config.TransportConfig()
  ExpectNoError(err, "Error creating transportCfg")
  restTransport, err := transport.New(transportCfg)
  ExpectNoError(err, "Error creating restTransport")

  client := &http.Client{
    CheckRedirect: func(req *http.Request, via []*http.Request) error {
      return http.ErrUseLastResponse
    },
    Transport: restTransport,
  }

  time.Sleep(1 * time.Second) // not required in e2e test
  httpVerbs := []string{"DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"}
  for _, httpVerb := range httpVerbs {

    urlString := config.Host + "/api/v1/namespaces/" + ns + "/services/test-service/proxy/some/path/with/" + httpVerb
    fmt.Printf("Starting http.Client for %s\n", urlString)
    request, err := http.NewRequest(httpVerb, urlString, nil)
    ExpectNoError(err, "processing request")

    resp, err := client.Do(request)
    ExpectNoError(err, "processing response")
    defer resp.Body.Close()

    fmt.Printf("http.Client request:%s StatusCode:%d\n", httpVerb, resp.StatusCode)
    ExpectEqual(resp.StatusCode, 200, "The resp.StatusCode returned: %d", resp.StatusCode)
  }
  // TEST ENDS HERE

  fmt.Println("[status] complete")
}

func checkPodStatus(cs *kubernetes.Clientset, label string) func() (bool, error) {
  return func() (bool, error) {
    var err error

    list, err := cs.CoreV1().Pods("default").List(context.TODO(), metav1.ListOptions{
      LabelSelector: label})

    if err != nil {
      return false, err
    }

    if list.Items[0].Status.Phase != "Running" {
      fmt.Printf("Pod Quantity: %d Status: %s\n", len(list.Items), list.Items[0].Status.Phase)
      return false, err
    }
    fmt.Printf("Pod Status: %v\n", list.Items[0].Status.Phase)
    return true, nil
  }
}
```

# Verifying increase in coverage with APISnoop

## Reset stats

```sql-mode
delete from testing.audit_event;
```

```example
DELETE 89563
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
select * from testing.endpoint_hit_by_new_test ORDER BY hit_by_ete;
```

```example
     useragent     |                     endpoint                      | hit_by_ete | hit_by_new_test
-------------------|---------------------------------------------------|------------|-----------------
 live-test-writing | connectCoreV1DeleteNamespacedServiceProxyWithPath | f          |              12
 live-test-writing | connectCoreV1PatchNamespacedServiceProxyWithPath  | f          |              12
 live-test-writing | connectCoreV1PostNamespacedServiceProxyWithPath   | f          |              12
 live-test-writing | connectCoreV1PutNamespacedServiceProxyWithPath    | f          |              12
 live-test-writing | listCoreV1NamespacedPod                           | t          |              24
 live-test-writing | connectCoreV1GetNamespacedServiceProxyWithPath    | t          |              24
 live-test-writing | createCoreV1NamespacedPod                         | t          |               8
 live-test-writing | createCoreV1NamespacedService                     | t          |               8
(8 rows)

```

## Display endpoint coverage change:

```sql-mode
select * from testing.projected_change_in_coverage;
```

```example
   category    | total_endpoints | old_coverage | new_coverage | change_in_number
---------------|-----------------|--------------|--------------|------------------
 test_coverage |             831 |          306 |          310 |                4
(1 row)

```

# Final notes

If a test with these calls gets merged, **test coverage will go up by 4 points**

This test is also created with the goal of conformance promotion.

---

/sig testing

/sig architecture

/area conformance