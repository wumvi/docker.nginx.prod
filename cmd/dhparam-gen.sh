#!/bin/bash
openssl dhparam -out /www/dhparam.pem 4096
exit $?