#!/usr/bin/env bash

set -e

skip_opt_in_config() {
    # remove an option inside the config file.
    # argument $1 is the option to be removed
    # argument $2 is the configuration file under $SNAP_DATA/args
    opt="--$1"
    config_file="$SNAP_DATA/args/$2"
    sudo "${SNAP}/bin/sed" -i '/'"$opt"'/d' "${config_file}"
}

echo "Disabling Istio"

skip_opt_in_config "allow-privileged" kubelet
skip_opt_in_config "allow-privileged" kube-apiserver
sudo systemctl restart snap.${SNAP_NAME}.daemon-apiserver
sudo systemctl restart snap.${SNAP_NAME}.daemon-kubelet
while ! (systemctl is-active --quiet snap.${SNAP_NAME}.daemon-apiserver) ||
      ! (systemctl is-active --quiet snap.${SNAP_NAME}.daemon-kubelet) ||
      ! (/snap/bin/microk8s.kubectl get all --all-namespaces &> /dev/null)
do
  sleep 5
done
sleep 5

if [ -f "$SNAP_USER_COMMON/istio-auth.lock" ]
then
  "$SNAP/kubectl" "--kubeconfig=$SNAP/client.config" delete -f "${SNAP}/actions/istio/istio-demo-auth.yaml" &> /dev/null || true
  rm "$SNAP_USER_COMMON/istio-auth.lock"
fi

if [ -f "$SNAP_USER_COMMON/istio.lock" ]
then
  "$SNAP/kubectl" "--kubeconfig=$SNAP/client.config" delete -f "${SNAP}/actions/istio/istio-demo.yaml" &> /dev/null || true
  sudo rm "$SNAP_USER_COMMON/istio.lock"
fi

"$SNAP/kubectl" "--kubeconfig=$SNAP/client.config" delete -f "${SNAP}/actions/istio/crds.yaml" -n istio-system &> /dev/null || true

echo "Istio is terminating"
