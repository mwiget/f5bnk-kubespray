#!/usr/bin/env bash
set -euo pipefail

# === Settings (override via env or edit here) ===
: "${NS:=iperf3}"                 # workload namespace (Service/Endpoints/L4Route live here)
: "${GW_NS:=default}"             # namespace of Gateway and F5BnkGateway
: "${ROUTE_NAME:=iperf3-route}"   # L4Route name
: "${SVC_NAME:=iperf3-backend}"   # Service/Endpoints name
: "${GW_NAME:=iperf-l4-gw}"       # Gateway name
: "${BNK_GW_NAME:=bnk-ipv4-only}" # F5BnkGateway name

# Optional safety knobs:
: "${DELETE_GATEWAY:=true}"       # also delete the Gateway (set to false to keep it)
: "${DELETE_BNK_GATEWAY:=true}"   # also delete the F5BnkGateway (set to false to keep it)
: "${FORCE_GATEWAY_DELETE:=false}"# delete Gateway even if other L4Routes reference it

info(){ echo -e "\033[1;34m[INFO]\033[0m $*"; }
warn(){ echo -e "\033[1;33m[WARN]\033[0m $*"; }
ok(){   echo -e "\033[1;32m[OK]\033[0m $*"; }

# --- 1) Delete L4Route (first, to release listener binding) ---
info "Deleting L4Route ${NS}/${ROUTE_NAME} ..."
kubectl -n "${NS}" delete l4route "${ROUTE_NAME}" --ignore-not-found
ok "L4Route removed (or did not exist)."

# --- 2) Delete Service and Endpoints for iperf3 backends ---
info "Deleting Service/Endpoints ${NS}/${SVC_NAME} ..."
kubectl -n "${NS}" delete svc "${SVC_NAME}" --ignore-not-found
kubectl -n "${NS}" delete endpoints "${SVC_NAME}" --ignore-not-found
ok "Service/Endpoints removed (or did not exist)."

# --- 3) Optionally delete the Gateway (only if not referenced elsewhere) ---
if [[ "${DELETE_GATEWAY}" == "true" ]]; then
  # Check if any L4Routes anywhere still reference this Gateway
  info "Checking if other L4Routes reference Gateway ${GW_NS}/${GW_NAME} ..."
  # Grep jsonpath on parentRefs; tolerates absence of CRD in other clusters
  set +e
  other_refs=$(kubectl get l4route -A -o json 2>/dev/null \
    | jq -r --arg gw "${GW_NAME}" --arg ns "${GW_NS}" '
        .items[]
        | select(any(.spec.parentRefs[]?; .name==$gw and (.namespace//""==$ns or (.namespace|not))))
        | "\(.metadata.namespace)/\(.metadata.name)"' )
  rc=$?
  set -e
  if [[ $rc -ne 0 ]]; then
    warn "Could not enumerate L4Routes (jq or CRD may be missing). Proceeding with Gateway delete."
    other_refs=""
  fi

  if [[ -n "${other_refs}" && "${FORCE_GATEWAY_DELETE}" != "true" ]]; then
    warn "Found L4Routes still referencing ${GW_NS}/${GW_NAME}:\n${other_refs}\nSkip deleting Gateway. Set FORCE_GATEWAY_DELETE=true to override."
  else
    info "Deleting Gateway ${GW_NS}/${GW_NAME} ..."
    kubectl -n "${GW_NS}" delete gateway "${GW_NAME}" --ignore-not-found
    ok "Gateway removed (or did not exist)."
  fi
else
  info "DELETE_GATEWAY=false → keeping Gateway ${GW_NS}/${GW_NAME}."
fi

# --- 4) Optionally delete the BNK Gateway (infra params object) ---
if [[ "${DELETE_BNK_GATEWAY}" == "true" ]]; then
  info "Deleting F5BnkGateway ${GW_NS}/${BNK_GW_NAME} ..."
  kubectl -n "${GW_NS}" delete f5bnkgateway "${BNK_GW_NAME}" --ignore-not-found || \
  kubectl -n "${GW_NS}" delete f5bnkgateways "${BNK_GW_NAME}" --ignore-not-found || true
  ok "F5BnkGateway removed (or did not exist)."
else
  info "DELETE_BNK_GATEWAY=false → keeping F5BnkGateway ${GW_NS}/${BNK_GW_NAME}."
fi

echo "removing iperf3 deployment ..."
kubectl delete -f iperf3-deployment.yaml

info "Done."
