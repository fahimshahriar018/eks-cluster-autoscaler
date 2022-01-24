# Configuring EKS Cluster Auto-scaler using AWS cli and Helm


## Cluster Autoscaler
The Kubernetes Cluster Autoscaler automatically adjusts the number of nodes in your cluster when pods fail or are rescheduled onto other nodes. The Cluster Autoscaler is typically installed as a Deployment in your cluster. It uses leader election to ensure high availability, but scaling is done by only one replica at a time.

##  Prerequisites
Before deploying the Cluster Autoscaler, you must meet the following prerequisites:

1. An existing Amazon EKS cluster – If you don’t have a cluster, see Creating an Amazon EKS cluster.

2. An existing IAM OIDC provider for your cluster. To determine whether you have one or need to create one, see Create an IAM OIDC provider for your cluster.

3. Node groups with Auto Scaling groups tags. The Cluster Autoscaler requires the following tags on your Auto Scaling groups so that they can be auto-discovered.

    |Key                                       | value  |
    |----------------------------------------  |:------:|
    |k8s.io/cluster-autoscaler/**cluster-name**| owned  |
    | k8s.io/cluster-autoscaler/enabled        |  TRUE  |

4. [AWS Cli v2](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html) and [Helm](https://helm.sh/) must be installed in your local linux machine. 

## Steps:
1. download this repository.

    ``` 
        git clone https://github.com/fahimshahriar018/eks-cluster-autoscaler.git
    ```
2. Go to ***script*** folder and edit ***script.sh***
    ``` 
        cd script/ 
        vim script.sh
    ```

    Change the variables value accordingly. Variables are described below:
    
   + ***env*** = Your cluster environment value. (Example: dev/stage/prod)
   + ***iamPolicyName*** = Name of the iam policy.
   + ***iamRole*** = iam Role name required for service account
   + ***accountId*** = Your AWS Account ID.
   + ***region*** = Your EKS Cluster Region
   + ***clusterName*** = Your cluster name
   + ***clusterAutoScalerImageTag*** = Cluster Autoscaler image tag(Example v1.21.2)  Open the Cluster Autoscaler [releases](https://github.com/kubernetes/autoscaler/releases) page from GitHub in a web browser and find the latest Cluster Autoscaler version that matches the Kubernetes major and minor version of your cluster. For example, if the Kubernetes version of your cluster is 1.20, find the latest Cluster Autoscaler release that begins with 1.20. Ue  the semantic version number (1.20.n) for that release in value.
3. add execute permission to run the script and run it. 
    ```
    chmod +x script.sh
    . script.sh
    ```
    Deployment is done. 
## View your Cluster Autoscaler logs

After you have deployed the Cluster Autoscaler, you can view the logs and verify that it's monitoring your cluster load.

View your Cluster Autoscaler logs with the following command.

```
kubectl -n kube-system logs -f deployment.apps/cluster-autoscaler
```
## Reference:
+ https://docs.aws.amazon.com/eks/latest/userguide/autoscaling.html#ca-deployment-considerations

