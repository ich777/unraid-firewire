# Patch .config with necessary modules for Firewire
while read -r line
do
	line_conf=${line//# /}
	line_conf=${line_conf%%=*}
	line_conf=${line_conf%% *}
	sed -i "/$line_conf/d" "${DATA_DIR}/linux-$UNAME/.config"
	echo "$line" >> "${DATA_DIR}/linux-$UNAME/.config"
done < "${DATA_DIR}/deps/firewire.list"
cd ${DATA_DIR}/linux-$UNAME

# Check configuration for .config file and deny all new packages
while true; do echo -e "n"; sleep 1s; done | make oldconfig

# Compile the modules and install them to a temporary directory
make -j${CPU_COUNT}
mkdir -p /FIREWIRE/lib/modules/${UNAME}/kernel/drivers
cd ${DATA_DIR}/linux-$UNAME
make INSTALL_MOD_PATH=/FIREWIREMods modules_install -j${CPU_COUNT}
cp -R /FIREWIREMods/lib/modules/${UNAME}/kernel/drivers/firewire /FIREWIRE/lib/modules/${UNAME}/kernel/drivers/

# Create Slackware package
PLUGIN_NAME="firewire"
BASE_DIR="/FIREWIRE"
TMP_DIR="/tmp/${PLUGIN_NAME}_"$(echo $RANDOM)""
VERSION="$(date +'%Y.%m.%d')"

mkdir -p $TMP_DIR/$VERSION
cd $TMP_DIR/$VERSION
cp -R $BASE_DIR/* $TMP_DIR/$VERSION/
mkdir $TMP_DIR/$VERSION/install
tee $TMP_DIR/$VERSION/install/slack-desc <<EOF
       |-----handy-ruler------------------------------------------------------|
$PLUGIN_NAME: $PLUGIN_NAME drivers
$PLUGIN_NAME:
$PLUGIN_NAME:
$PLUGIN_NAME: Custom $PLUGIN_NAME driver package for Unraid Kernel v${UNAME%%-*} by ich777
$PLUGIN_NAME:
EOF
${DATA_DIR}/bzroot-extracted-$UNAME/sbin/makepkg -l n -c n $TMP_DIR/$PLUGIN_NAME-plugin-$UNAME-1.txz
md5sum $TMP_DIR/$PLUGIN_NAME-plugin-$UNAME-1.txz | awk '{print $1}' > $TMP_DIR/$PLUGIN_NAME-plugin-$UNAME-1.txz.md5