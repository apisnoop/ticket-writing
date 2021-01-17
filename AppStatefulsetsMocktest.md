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
    and endpoint like '%StatefulSetScale%'
  --and category = 'core'
  order by kind, endpoint desc
  limit 25;
```

```example
               endpoint                | kind
---------------------------------------|-------
 patchAppsV1NamespacedStatefulSetScale | Scale
(1 row)

```

# API Reference and feature documentation

-   [[<https://kubernetes.io/docs/reference/kubernetes-api/>][Kubernetes API Reference Docs]
-   [client-go - RESOURCENAME](https://github.com/kubernetes/client-go/blob/master/kubernetes/typed/core/v1/RESOURCENAME.go)

-   [kubeclt scale / updating resources](https://kubernetes.io/docs/reference/kubectl/cheatsheet/#updating-resources)
-   [Scale](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#scale)
-   [kubectl-commands#patch](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#patch)
-   [kubectl-commands#replace](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#replace)
-   [StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)

# The mock test

## Test outline

### 1. Create a Statefulset yaml file, namespace and Deployment

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  ports:
  - port: 80
    name: web
  clusterIP: None
  selector:
    app: nginx
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  serviceName: "nginx"
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: k8s.gcr.io/nginx-slim:0.8
        ports:
        - containerPort: 80
          name: web
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
  - metadata:
      name: www
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 1Gi


```

-   Tangle to create the .yaml file - \`,bt\`

-   See if the yaml file was created

```shell
  pwd
# ls -al /home/riaan/Project/ticket-writing |grep .yaml

 ls -al /home/ii/ticket-writing | grep yaml
```

    /home/ii/ticket-writing
    -rw-r--r--  1 ii ii    840 Jan 15 09:22 statefulset_test.yaml

-   Create a Namespace

```shell
kubectl create namespace app-statefulset-tests
```

    namespace/app-statefulset-tests created

-   Create a StatefulSet

```shell
kubectl apply -f statefulset_test.yaml --namespace=app-statefulset-tests
```

    service/nginx created
    statefulset.apps/web created

### 2. Find the statefulset

```shell
kubectl get statefulset -A | grep web
```

    app-statefulset-tests   web                     0/2     14s

### 3. Scale the Statefulset up to 4 replicas

```shell
kubectl scale statefulsets web -n app-statefulset-tests --replicas=5
sleep 5
kubectl get statefulset -A | grep web
```

    statefulset.apps/web scaled
    app-statefulset-tests   web                     0/5     17m

### Scaling down by patch of the spec - STUCK HIER, WIL NIE PATCH

```shell
kubectl scale statefulsets web -p '{"spec":{"replicas":3}}'

#kubectl scale statefulsets web -p -n app-statefulset-tests '{"spec":{"replicas":3}}'
kubectl get statefulset -A | grep web

```

    app-statefulset-tests   web                     0/5     20m

WIP- Still to convert below this point

### 4. Update the deployment:

```shell
kubectl set image deployment.v1.apps/nginx-deployment -n app-deploy-tests nginx=nginx:1.16.0 --record
```

-   and update it agaian, because we can&#x2026;

```shell
kubectl set image deployment.v1.apps/nginx-deployment -n app-deploy-tests nginx=nginx:1.16.1 --record
```

### 5. Describe the deployments to see if it was updated with history

```shell
kubectl describe deployments -n app-deploy-tests | grep image
kubectl rollout history deployment.v1.apps/nginx-deployment -n app-deploy-tests
```

### 6. Describe the status of the deployment

```shell
kubectl rollout status deployment.v1.apps/nginx-deployment -n app-deploy-tests
```

### 7. The following kubectl command sets the spec with progressDeadlineSeconds to make the controller report lack of progress for a Deployment after 1 minute:

```shell
#This command fail!
kubectl patch deployment.v1.apps/nginx-deployment -p -n app-deploy-tests '{"spec":{"progressDeadlineSeconds":60}}'
```

### 8. Cleanup

-   Delete the deployment and the namespace

```shell
kubectl delete statefulset web
kubectl delete namespaces/app-statefulset-tests

```

    namespace "app-statefulset-tests" deleted

-   Look for deployment and namespace to check if it is deleted

```shell
kubectl get namespace app-deploy-tests
kubectl get deployment nginx-deployment
```

-   ALL DONE!

### Delete audit events to check for success

-   Count all audit events

```sql-mode
select count(*) from testing.audit_event;
```

```example
 count
-------
  1503
(1 row)

```

-   Delete all audit events

```sql-mode
delete from testing.audit_event;
```

```example
DELETE 2228333
```

### Test to see is new endpoint was hit by the test

```sql-mode
select distinct  endpoint, useragent
                 -- to_char(to_timestamp(release_date::bigint), ' HH:MI') as time
from testing.audit_event
where endpoint ilike '%Deployment%'
  -- and release_date::BIGINT > round(((EXTRACT(EPOCH FROM NOW()))::numeric)*1000,0) - 60000
and useragent like 'kubectl%'
order by endpoint
limit 100;

```

```example
 endpoint | useragent
----------|-----------
(0 rows)

```

### About Scale enpoints

-   The file [deployment.go](https://github.com/kubernetes/kubernetes/blob/master/staging/src/k8s.io/client-go/kubernetes/typed/apps/v1/deployment.go#L186-L228) have three code sections that deal with scale endpoint replace-, read- and patchAppsV1NamespacedDeploymentScale. However neither of these tests blocks touch the endpoint
    
    The [statefulsets.go](https://github.com/kubernetes/kubernetes/blob/master/test/e2e/apps/statefulset.go#L848-L872) file contain test similar scale endpoint for relace and read which make these endpoint conformance tested.
    
    If the statefulsets file could be used as a temple it could be applied to the deployment endpoint. The Patch &#x2013;Deploymentscale endpoint was touch with a simple kubeclt command The same logic could then be applied to the Patch &#x2013; statefulsetsScale endpoint in another test.

****Patch**** StatefulSet HTTP Request PATCH /apis/apps/v1/namespaces/{namespace}/statefulsets/{name}

Deployment HTTP Request PATCH /apis/apps/v1/namespaces/{namespace}/deployments/{name}

Patch for both statefulsets and deployments use the same HTTP Request logic

## Test the functionality in Go - AS IS IN statefulSet.go test

```go
           package main

           import (
             // "encoding/json"
             "fmt"
            // "context"
             "flag"
             "os"
            // v1 "k8s.io/api/core/v1"
             // "k8s.io/client-go/dynamic"
             // "k8s.io/apimachinery/pkg/runtime/schema"
             //metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
             "k8s.io/client-go/kubernetes"
             // "k8s.io/apimachinery/pkg/types"
             "k8s.io/client-go/tools/clientcmd"
              e2estatefulset "k8s.io/kubernetes/test/e2e/framework/statefulset"
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
              ssName := "ss"
              labels := map[string]string{
               "foo": "bar",
               "baz": "blah",
             headlessSvcName := "test"


            ss := e2estatefulset.NewStatefulSet(ssName, ns, headlessSvcName, 1, nil, nil, labels)
            setHTTPProbe(ss)
             ss, err := c.AppsV1().StatefulSets(ns).Create(context.TODO(), ss, metav1.CreateOptions{})
            ExpectNoError(err, "failed to create pod")
            e2estatefulset.WaitForRunningAndReady(c, *ss.Spec.Replicas, ss)
            waitForStatus(c, ss)

            framework.ExpectEqual(*(ss.Spec.Replicas), int32(2))
              })
      })


             scale, err := c.AppsV1().StatefulSets(ns).GetScale(context.TODO(), ssName, metav1.GetOptions{})                                         
             if err != nil {                                                                                                                         
                     framework.Failf("Failed to get scale subresource: %v", err)
             }
             framework.ExpectEqual(scale.Spec.Replicas, int32(1))
             framework.ExpectEqual(scale.Status.Replicas, int32(1))

             scale.ResourceVersion = "" // indicate the scale update should be unconditional
             scale.Spec.Replicas = 2
             scaleResult, err := c.AppsV1().StatefulSets(ns).UpdateScale(context.TODO(), ssName, scale, metav1.UpdateOptions{})
             if err != nil {
                     framework.Failf("Failed to put scale subresource: %v", err)
             }
             framework.ExpectEqual(scaleResult.Spec.Replicas, int32(2))

             ss, err = c.AppsV1().StatefulSets(ns).Get(context.TODO(), ssName, metav1.GetOptions{})
             if err != nil {
                     framework.Failf("Failed to get statefulset resource: %v", err)
             }


  })
})




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


             // TEST ENDS HERE

             fmt.Println("[status] complete")

           }
```

```go

```

## Test the functionality in Go - As updated by Riaankl accoding to rc.go example for Patch &#x2014;Scale

```go
        package main

        import (
          "encoding/json"
          "fmt"
         // "context"
          "flag"
          "os"
         // v1 "k8s.io/api/core/v1"
          "k8s.io/client-go/dynamic"
          // "k8s.io/apimachinery/pkg/runtime/schema"
          //metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
          "k8s.io/client-go/kubernetes"
          // "k8s.io/apimachinery/pkg/types"
          "k8s.io/client-go/tools/clientcmd"
           e2estatefulset "k8s.io/kubernetes/test/e2e/framework/statefulset"
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
           ssName := "ss"
           labels := map[string]string{
            "foo": "bar",
            "baz": "blah",
          headlessSvcName := "test"


                  ss := e2estatefulset.NewStatefulSet(ssName, ns, headlessSvcName, 1, nil, nil, labels)
                  setHTTPProbe(ss)
                  ss, err := c.AppsV1().StatefulSets(ns).Create(context.TODO(), ss, metav1.CreateOptions{})
                  framework.ExpectNoError(err)
                  e2estatefulset.WaitForRunningAndReady(c, *ss.Spec.Replicas, ss)
                  waitForStatus(c, ss)

                  scale, err := c.AppsV1().StatefulSets(ns).GetScale(context.TODO(), ssName, metav1.GetOptions{})                                                                             
                  framework.Logf("scale: %#v", scale)                                                                                                                                         
                  framework.Logf("err: %+v", err)                                                                                                                                             
                  if err != nil {                                                                                                                                                             
                          framework.Failf("Failed to get scale subresource: %v", err)
                  }
                  framework.ExpectEqual(scale.Spec.Replicas, int32(1))
                  framework.ExpectEqual(scale.Status.Replicas, int32(1))
                  ginkgo.By("updating a scale subresource")
                  scale.ResourceVersion = "" // indicate the scale update should be unconditional
                  scale.Spec.Replicas = 2
                  ssScalePatchPayload, err := json.Marshal(autoscalingv1.Scale{
                          Spec: autoscalingv1.ScaleSpec{
                                  Replicas: scale.Spec.Replicas,
                          },
                  })
                  scaleResult, err := c.AppsV1().StatefulSets(ns).Patch (context.TODO(), ssName, types.StrategicMergePatchType, []byte(ssScalePatchPayload), metav1.PatchOptions{}, "scale")
                  framework.Logf("scaleResult: %#v", scaleResult)
                  framework.Logf("err: %#v", err)
                  x := scaleResult.Status.ReadyReplicas
                  framework.Logf("ReadyReplicas: %#v", x)
                  if err != nil {
                          framework.Failf("Failed to put scale subresource: %v", err)
                  }
                  framework.ExpectEqual(scaleResult.Spec.Replicas, int32(2))

                  ss, err = c.AppsV1().StatefulSets(ns).Get(context.TODO(), ssName, metav1.GetOptions{})                                                                                      
                  if err != nil {                                                                                                                                                             
                          framework.Failf("Failed to get statefulset resource: %v", err)                                                                                                      
                  }                                                                                                                                                                           
                  framework.ExpectEqual(*(ss.Spec.Replicas), int32(0))                                                                                                                        
          })                                                                                                                                                                                  
  })                                                                                                                                                                                          
















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


          // TEST ENDS HERE

          fmt.Println("[status] complete")

        }
```

```go

```

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

```example
 useragent | endpoint | hit_by_ete | hit_by_new_test
-----------|----------|------------|-----------------
(0 rows)

```

Display endpoint coverage change:

```sql-mode
select * from testing.projected_change_in_coverage;
```

```example
   category    | total_endpoints | old_coverage | new_coverage | change_in_number
---------------|-----------------|--------------|--------------|------------------
 test_coverage |             862 |          343 |          343 |                0
(1 row)

```

```sql-mode
select distinct  endpoint, right(useragent,73) AS useragent
from testing.audit_event
-- where useragent ilike '%subresource%'
 where endpoint ilike '%AppsV1NamespacedStatefulSetScale%'
 and release_date::BIGINT > round(((EXTRACT(EPOCH FROM NOW()))::numeric)*1000,0) - 60000
and useragent like 'e2e%'
order by endpoint
limit 30;

```

```example
                endpoint                 |                                 useragent
-----------------------------------------|---------------------------------------------------------------------------
 patchAppsV1NamespacedStatefulSetScale   |  [StatefulSetBasic] should have a working scale subresource [Conformance]
 readAppsV1NamespacedStatefulSetScale    |  [StatefulSetBasic] should have a working scale subresource [Conformance]
 replaceAppsV1NamespacedStatefulSetScale |  [StatefulSetBasic] should have a working scale subresource [Conformance]
(3 rows)

```

# Final notes

If a test with these calls gets merged, ****test coverage will go up by N points****

This test is also created with the goal of conformance promotion.

---

/sig testing

/sig architecture

/area conformance
