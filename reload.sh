#!/bin/bash

DOMAIN_PATH=/etc/letsencrypt/live/${DOMAIN}

cas_name() {
    echo let-cert-$(date "+%Y%m%d%H%M%S")
}

ngx() {
    cp ${DOMAIN_PATH}/* /etc/letsencrypt/certs
}

upld() {
    local CERT_ID=$(aliyun cas UploadUserCertificate \
        --region cn-hangzhou \
        --Name "$(cas_name)" \
        --Cert "$(cat ${DOMAIN_PATH}/fullchain.pem)" \
        --Key "$(cat ${DOMAIN_PATH}/privkey.pem)" \
        | grep "CertId" \
        | grep -Eo "[0-9]+")
    /bin/sleep 3
    echo ${CERT_ID}
}

cdn() {
    aliyun cdn SetCdnDomainSSLCertificate \
        --DomainName ${DOMAIN} \
        --SSLProtocol on \
        --CertType cas \
        --CertId $(upld)
}

vod() {
    aliyun vod SetVodDomainCertificate \
        --region cn-shanghai \
        --DomainName "${DOMAIN}" \
        --CertName "$(cas_name)" \
        --SSLProtocol on \
        --SSLPub "$(cat ${DOMAIN_PATH}/fullchain.pem)" \
        --SSLPri "$(cat ${DOMAIN_PATH}/privkey.pem)"
}

cname_config() {
    echo "{"
    echo "  \"Cname\": {"
    echo "    \"Domain\": \"${DOMAIN}\","
    echo "    \"CertificateConfiguration\": {"
    echo "      \"CertId\": \"$1-cn-hangzhou\","
    echo "      \"Force\": true"
    echo "    }"
    echo "  }"
    echo "}"
}

oss() {
    local CNM_CFG=$(cname_config $(upld))
    aliyun ossutil api put-cname \
        --bucket "${OSS_BUCKET}" \
        --cname-configuration "${CNM_CFG}"
}

case "$1" in
    "ngx") ngx ;;
    "cdn") cdn ;;
    "vod") vod ;;
    "oss") oss ;;
    *) echo "deploy options is [ngx|cdn|vod|oss] ..." ;;
esac

