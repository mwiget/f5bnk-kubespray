#!/bin/bash

NODE=$(kubectl -n f5-utils get pod -l app=cwc -o jsonpath='{.items[0].status.hostIP}')

CURL_CMD=(
    curl -s --cacert ~/cwc/cwc_api/ca_certificate.pem \
        --cert ~/cwc/cwc_api/client_certificate.pem \
        --key ~/cwc/cwc_api/client_key.pem \
        --resolve f5-spk-cwc.f5-utils:30881:"$NODE"
)

"${CURL_CMD[@]}" https://f5-spk-cwc.f5-utils:30881/"$@"
