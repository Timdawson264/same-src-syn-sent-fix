
OCP_VER="$1"

IMAGE="$( oc adm release info ${OCP_VER} --image-for=sdn )"

cat ds.yaml | sed -e "s|image:.*|image: $IMAGE|" > ds-$OCP_VER.yaml