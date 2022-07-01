#!/bin/bash

OCP_VER="$1"

IMAGE="$( oc adm release info ${OCP_VER} --image-for=sdn )"

cat ds.yaml | sed -e "s|<IMAGE>|$IMAGE|" 