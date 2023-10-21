# Deploying WordPress and MySQL with Persistent Volumes in Kubernetes

This guide provides step-by-step instructions on how to deploy WordPress and MySQL with persistent volumes in a Kubernetes cluster.

## Prerequisites

Before you begin, make sure you have the following:

- A running Kubernetes cluster
- `kubectl` command-line tool configured to communicate with your cluster
- Change default password to strong password in `kustomization.yaml` file

## Steps

### Step 1: Create the stack of MySQL and WordPress using below command

Change working directory, and move inside `WordPress_MySQL_Deployment` folder before running below commands

```bash
# run below command to apply all the changes
kubectl apply -k ./

# run below command to check the Persistent Volume
kubectl get pv
# sample output
# NAME                    CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM       STORAGECLASS   REASON   AGE
# my-pv-mysql             2Gi        RWO            Retain           Available                                       18s
# my-pv-wordpress         2Gi        RWO            Retain           Available                                       18s

# running Persistent Volume Claim command to check if the claim has been Bound
kubectl get pvc
# sample output
# NAME             STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
# mysql-pv-claim   Bound    pvc-ce3367a3-9863-4be1-afee-d0944f78b501   2Gi        RWO            standard       33s
# wp-pv-claim      Bound    pvc-c03a99d3-4a9e-44aa-9d13-96e1b3c69078   2Gi        RWO            standard       33s

# run below command to check the pods status
kubectl get pods
# sample output
# NAME                               READY   STATUS    RESTARTS   AGE
# wordpress-84444b9976-86g2f         1/1     Running   0          71s
# wordpress-mysql-7d9fbb77cf-4cs5d   1/1     Running   0          71s

# run below command to check the running service status and port number for the next step
kubectl get service
# sample output
# NAME              TYPE           CLUSTER-IP    EXTERNAL-IP   PORT(S)        AGE
# kubernetes        ClusterIP      10.96.0.1     <none>        443/TCP        7m51s
# wordpress         LoadBalancer   10.96.68.73   <pending>     80:31385/TCP   97s
# wordpress-mysql   ClusterIP      None          <none>        3306/TCP       97s

# run below command to make port forward if you are using single master/slave node strategy, otherwise access the wordpress using worker node's IP address and port
kubectl port-forward service/wordpress 8081:80
# # sample output
# Forwarding from 127.0.0.1:8081 -> 80
# Forwarding from [::1]:8081 -> 80
# Handling connection for 8081
```
### Step 2: Cleanup the stack

After performing test, stack can be deleted using the below command

```bash
kubectl delete -k ./
```

## Acknowledgments

This is a modified/corrected version from the official kubernetes documentation. [Documentation Link](https://kubernetes.io/docs/tutorials/stateful-application/mysql-wordpress-persistent-volume/)