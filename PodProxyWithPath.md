# Progress <code>[1/6]</code>

-   [X] APISnoop org-flow : [PodProxyWithPath.org](https://github.com/cncf/apisnoop/blob/master/tickets/k8s/PodProxyWithPath.org)
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
  and endpoint like '%PodProxyWithPath'
  order by kind, endpoint desc
  limit 25;
```

```example
                    endpoint                    |                          path                           |      kind
------------------------------------------------|---------------------------------------------------------|-----------------
 connectCoreV1PutNamespacedPodProxyWithPath     | /api/v1/namespaces/{namespace}/pods/{name}/proxy/{path} | PodProxyOptions
 connectCoreV1PostNamespacedPodProxyWithPath    | /api/v1/namespaces/{namespace}/pods/{name}/proxy/{path} | PodProxyOptions
 connectCoreV1PatchNamespacedPodProxyWithPath   | /api/v1/namespaces/{namespace}/pods/{name}/proxy/{path} | PodProxyOptions
 connectCoreV1OptionsNamespacedPodProxyWithPath | /api/v1/namespaces/{namespace}/pods/{name}/proxy/{path} | PodProxyOptions
 connectCoreV1HeadNamespacedPodProxyWithPath    | /api/v1/namespaces/{namespace}/pods/{name}/proxy/{path} | PodProxyOptions
 connectCoreV1DeleteNamespacedPodProxyWithPath  | /api/v1/namespaces/{namespace}/pods/{name}/proxy/{path} | PodProxyOptions
(6 rows)

```

# API Reference and feature documentation

-   [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/kubernetes-api/)
-   [client-go](https://github.com/kubernetes/client-go/blob/master/kubernetes/typed/core/v1)
-   [Kubernetes 1.19: Pod v1 Core: Proxy Operations](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.19/#-strong-proxy-operations-pod-v1-core-strong-)

# The mock test

## Test outline

1.  Create a pod with a static label using the agnhost image

2.  Confirm that the pod is in the running phase

3.  Iterate through a list of http methods and check the response from the porter app

4.  Confirm that each response code is 200 OK

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
  httpVerbs := []string{"DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"}
  // httpVerbs := []string{"HEAD"}
  // httpVerbs := []string{"OPTIONS"}

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

  for _, httpVerb := range httpVerbs {

    urlString := config.Host + "/api/v1/namespaces/" + ns + "/pods/agnhost/proxy/some/path/with/" + httpVerb
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
DELETE 977385
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
     useragent     |                   endpoint                    | hit_by_ete | hit_by_new_test
-------------------|-----------------------------------------------|------------|-----------------
 live-test-writing | connectCoreV1PostNamespacedPodProxyWithPath   | f          |               9
 live-test-writing | connectCoreV1PatchNamespacedPodProxyWithPath  | f          |               9
 live-test-writing | connectCoreV1DeleteNamespacedPodProxyWithPath | f          |               9
 live-test-writing | connectCoreV1PutNamespacedPodProxyWithPath    | f          |               9
 live-test-writing | connectCoreV1GetNamespacedPodProxyWithPath    | t          |              18
 live-test-writing | listCoreV1NamespacedPod                       | t          |              42
 live-test-writing | createCoreV1NamespacedPod                     | t          |               6
(7 rows)

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

# Exploring / Questions about missing endpoints

Where/How does PATCH/HEAD/OPTIONS requests for the following endpoints line up with the API reference?

-   connectCoreV1PatchNamespacedPodProxyWithPath
-   connectCoreV1HeadNamespacedPodProxyWithPath
-   connectCoreV1OptionsNamespacedPodProxyWithPath

**Pod v1 core: Proxy Operations**

<https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.19/#-strong-proxy-operations-pod-v1-core-strong>-

| httpVerb | Endpoint                   |
|-------- |-------------------------- |
| POST     | Create Connect Proxy       |
|          | Create Connect Proxy Path  |
| DELETE   | Delete Connect Proxy       |
|          | Delete Connect Proxy Path  |
| GET      | Get Connect Proxy          |
|          | Get Connect Proxy Path     |
| HEAD     | Head Connect Proxy         |
|          | Head Connect Proxy Path    |
| PUT      | Replace Connect Proxy      |
|          | Replace Connect Proxy Path |

# Locate why 2 endpoints are missing

<https://apisnoop.cncf.io/conformance-progress/endpoints/1.9.0?filter=promotedWithoutTests&filter=untested> shows the following endpoints are listed as valid endpoints;

-   connectCoreV1HeadNamespacedPodProxyWithPath
-   connectCoreV1OptionsNamespacedPodProxyWithPath

## Missing HEAD requests

These requests are getting logged as a `get` verb.

Line 24520: api/openapi-spec

```json
"head": {
  "consumes": [
    "*/*"
  ],
  "description": "connect HEAD requests to proxy of Pod",
  "operationId": "connectCoreV1HeadNamespacedPodProxyWithPath",
  "produces": [
    "*/*"
  ],
  "responses": {
    "200": {
      "description": "OK",
      "schema": {
        "type": "string"
      }
    },
    "401": {
      "description": "Unauthorized"
    }
  },
  "schemes": [
    "https"
  ],
  "tags": [
    "core_v1"
  ],
  "x-kubernetes-action": "connect",
  "x-kubernetes-group-version-kind": {
    "group": "",
    "kind": "PodProxyOptions",
    "version": "v1"
  }
```

## Missing OPTIONS requests

Line 24553: api/openapi-spec

```json
"options": {
  "consumes": [
    "*/*"
  ],
  "description": "connect OPTIONS requests to proxy of Pod",
  "operationId": "connectCoreV1OptionsNamespacedPodProxyWithPath",
  "produces": [
    "*/*"
  ],
  "responses": {
    "200": {
      "description": "OK",
      "schema": {
        "type": "string"
      }
    },
    "401": {
      "description": "Unauthorized"
    }
  },
  "schemes": [
    "https"
  ],
  "tags": [
    "core_v1"
  ],
  "x-kubernetes-action": "connect",
  "x-kubernetes-group-version-kind": {
    "group": "",
    "kind": "PodProxyOptions",
    "version": "v1"
  }
```

## Verbs missing

Looking at snoopUtils.py there doesn't look to be a mapping for the above methods.

```python
VERB_TO_METHOD={
    'get': 'get',
    'list': 'get',
    'proxy': 'proxy',
    'create': 'post',
    'post':'post',
    'put':'post',
    'update':'put',
    'patch':'patch',
    'connect':'connect',
    'delete':'delete',
    'deletecollection':'delete',
    'watch':'get'
}
```