#!/bin/bash
[ -d "$SCRIPT_DIR" ] || SCRIPT_DIR="."
source ${SCRIPT_DIR}/.env

# Run busybox
# Define an array of contexts
contexts=("gke-west-1" "gke-east-1")

# Loop through each context
for context in "${contexts[@]}"; do
  # Check if the busybox pod exists in the current context
  POD_EXISTS=$(kubectl get pod busybox --context="$context" --ignore-not-found)

  # If the pod does not exist, then run it
  if [ -z "$POD_EXISTS" ]; then
    kubectl run busybox --context="$context" --image=busybox --restart=Never -- /bin/sh -c "sleep 1d"
  else
    POD_STATUS=$(kubectl get pod busybox --context="$context" --ignore-not-found -o jsonpath='{.status.phase}')
    if [ "$POD_STATUS" == "Succeeded" ]; then
      kubectl delete pod busybox --context="$context"
      kubectl run busybox --context="$context" --image=busybox --restart=Never -- /bin/sh -c "sleep 1d"
    fi
  fi

  # Wait for the busybox pod to be ready in the current context
  kubectl wait --for=condition=Ready pod/busybox --context="$context"
done

echo "Waiting for GW to get public IP..."
VIP=""
# Initial attempt without waiting
VIP=$(kubectl get gateways.gateway.networking.k8s.io external-http -o=jsonpath="{.status.addresses[0].value}" --context gke-west-1 --namespace store)

# Loop to retry after waiting if the first attempt failed
while [ -z "$VIP" ]; do
    echo "Retrying after 10 seconds..."
    sleep 10 # Wait for 10 second before retrying to avoid hammering the API server
    VIP=$(kubectl get gateways.gateway.networking.k8s.io external-http -o=jsonpath="{.status.addresses[0].value}" --context gke-west-1 --namespace store)
done

echo "VIP is now set to: $VIP"

# Waiting for GW to be ready...
echo Waiting for GW to be ready...
while true; do
    # Use curl to perform the request and check for a 200 status code explicitly
    status_code=$(curl -s -o /dev/null -w "%{http_code}" --header "Host: store.example.com" --connect-timeout 20 http://$VIP)
    
    if [ "$status_code" -eq 200 ]; then
        echo "Successfully received a response with status code 200."
        break
    else
        echo "Request failed or did not return status code 200 (status code: $status_code), trying again in 10 seconds..."
        sleep 10
    fi
done

# running from west
echo 
echo 
echo Testing GW...
echo "Running test from west:"
kubectl exec busybox --context gke-west-1 -- "/bin/sh" "-c" "wget -q --header \"Host: store.example.com\" http://$VIP -O-" | jq -r '"Response from cluster: " + .cluster_name'

# running from east
echo 
echo "Running test from east"
kubectl exec busybox --context gke-east-1 -- "/bin/sh" "-c" "wget -q --header \"Host: store.example.com\" http://$VIP -O-" | jq -r '"Response from cluster: " + .cluster_name'

# running from my pc
echo 
echo "Running from my pc"
wget -q --header "Host: store.example.com" http://$VIP -O- | jq -r '"Response from cluster: " + .cluster_name'
echo 
echo 
echo Testing MCS...
echo "Running MC service test from west:"
kubectl exec busybox --context gke-west-1 -- "/bin/sh" "-c" "wget -q http://store.store.svc.clusterset.local:8080 -O-" | jq -r '"Response from cluster: " + .cluster_name'

echo 
echo "Running MC west service test from west:"
kubectl exec busybox --context gke-west-1 -- "/bin/sh" "-c" "wget -q http://store-west-1.store.svc.clusterset.local:8080 -O-" | jq -r '"Response from cluster: " + .cluster_name'

echo 
echo "Running MC east service test from west:"
kubectl exec busybox --context gke-west-1 -- "/bin/sh" "-c" "wget -q http://store-east-1.store.svc.clusterset.local:8080 -O-" | jq -r '"Response from cluster: " + .cluster_name'
