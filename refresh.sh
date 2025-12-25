#!/bin/bash

/usr/bin/certbot renew \
	--manual \
	--preferred-challenges dns \
	--manual-auth-hook '/usr/local/bin/alidns' \
	--manual-cleanup-hook '/usr/local/bin/alidns clean' \
	--agree-tos \
	--email $EMAIL \
	--deploy-hook "/usr/local/bin/reload.sh $DEPLOY_OPER"
