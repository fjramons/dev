# DNS Tester in K8s cluster

Utility to test reliability of communications between the DNS of a Kubernetes cluster and pods running in each of the worker nodes.

## Pre-requirements

- K8s cluster available with sufficient permissions.
- `kubectl` client.
- `helm` client (option).

**NOTE:** For basic testing, a _kind_ cluster may suffice:

```bash
kind create cluster --name cluster-dns-test --config=kind/multi-node-LARGE.yaml
```

## Usage

First, deploy the dns-tester:

```bash
# Using the helm chart
helm install dns-tester ./dns-tester/ --namespace dns-tester --create-namespace

# Same, but using raw manifests
# kubectl apply -f manifests/

# Verify correct deployment
kubectl get pod -n dns-tester | grep dns-tester
```

This creates a `daemonset` where each pod sends continuous queries to the cluster's DNS.

Once deployed, logs generated by the tester pods can be retrieved based on the corresponding label:

```bash
kubectl -n dns-tester logs -l app.kubernetes.io/name=dns-tester -f
```

which should yield the following output:

```text
dns-tester-rq8pl: 03-14 23:58:44 --> 142.250.178.174
dns-tester-jh7rf: 03-14 23:58:45 --> 142.250.178.174
dns-tester-rq8pl: 03-14 23:58:45 --> 142.250.178.174
dns-tester-zrnxv: 03-14 23:58:45 --> 142.250.178.174
dns-tester-jh7rf: 03-14 23:58:46 --> 142.250.178.174
dns-tester-rq8pl: 03-14 23:58:46 --> 142.250.178.174
dns-tester-zrnxv: 03-14 23:58:46 --> 142.250.178.174
dns-tester-jh7rf: 03-14 23:58:47 --> 142.250.178.174
dns-tester-rq8pl: 03-14 23:58:47 --> 142.250.178.174
dns-tester-zrnxv: 03-14 23:58:47 --> 142.250.178.174
dns-tester-jh7rf: 03-14 23:58:48 --> 142.250.178.174
dns-tester-rq8pl: 03-14 23:58:48 --> 142.250.178.174
dns-tester-zrnxv: 03-14 23:58:48 --> 142.250.178.174
dns-tester-jh7rf: 03-14 23:58:49 --> 142.250.178.174
dns-tester-rq8pl: 03-14 23:58:49 --> 142.250.178.174
dns-tester-zrnxv: 03-14 23:58:49 --> 142.250.178.174
dns-tester-jh7rf: 03-14 23:58:50 --> 142.250.178.174
dns-tester-zrnxv: 03-14 23:58:50 --> 142.250.178.174
dns-tester-rq8pl: 03-14 23:58:50 --> 142.250.178.174
dns-tester-jh7rf: 03-14 23:58:51 --> 142.250.178.174
dns-tester-rq8pl: 03-14 23:58:51 --> 142.250.178.174
      .                  .                 .
      .                  .                 .
      .                  .                 .
      .                  .                 .
```

Where each line should follow the format:

_**\<pod_ip\>**_`:` _**\<timestamp\>**_ `-->` _**\<response\>**_

> **NOTE:** For some domain names, the DNS response includes several entries instead of just one. Although, as a result, the formatting may become a bit awkward, the dns-tester will be working normally.

For better interpretation, the correspondence between pod names and worker node names can also be retrieved by:

```bash
kubectl get pod -l app.kubernetes.io/name=dns-tester -o=custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName --all-namespaces
```

## Cleanup

Deletion of the tester:

```bash
helm delete dns-tester --namespace dns-tester

# In case we deployed with the manifest:
# kubectl delete -f manifests/
```

NOTE: If a _kind_ cluster had been used, it could be deleted by:

```bash
kind delete cluster --name cluster-dns-test
```

## Advanced topics

### Configuration and reconfiguration

The behaviour of the tester pod can be adapted by using environment variables:

- `DESTINATION`: Domain name to be resolved by DNS (defaults to _google.com_).
- `INTERVAL`: Time (in seconds) between DNS queries from each pod.

For instance, you can change the DNS query and the interval by doing:

```bash
helm upgrade \
    --set config.destination=amazon.com \
    --set config.interval=2 dns-tester \
    ./dns-tester/ \
    --namespace dns-tester
```

### Development: How to build, test and push the Docker image

Image build and push:

```bash
# Login
#export CR_PAT=TOKEN
#echo $CR_PAT | docker login docker.io -u fjramons --password-stdin

# Build
export REPO=docker.io/fjramons
export TAG=0.2
docker build -t $REPO/dns-tester:$TAG .
docker image ls | grep dns-tester

# Push
docker push $REPO/dns-tester:$TAG

# Docker run test 1 (default: query about 'google.com' every 2 seconds)
docker run -it --rm --name mitester $REPO/dns-tester:$TAG

# Docker run test 2
export DEST=disney.com  # other query
export INTERV=0.5       # 2 queries per second
docker run -it --rm --name mitester --env DESTINATION=$DEST --env INTERVAL=$INTERV $REPO/dns-tester:$TAG
```

**NOTE:** If using a _kind_ cluster, the local image needs to be transferred to the nodes manually:

```bash
kind load docker-image $REPO/dns-tester:$TAG -n cluster-dns-test
```
