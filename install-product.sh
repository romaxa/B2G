#!/bin/bash

. setup.sh

CURDIR=$(pwd)
LOCAL_PATH=$CURDIR/device/$VENDOR/$DEVICE
TARGET_PATH=$CURDIR/out/target/product/$DEVICE
TOOLCHAIN=$ANDROID_EABI_TOOLCHAIN/arm-linux-androideabi
KERNEL_VER=2.6.32.48-dfl61-20115101
KERNEL_PATH=$CURDIR/boot/kernel-$VENDOR-$DEVICE-prebuilt

function install_core_init()
{
  mkdir -p $TARGET_PATH/root/bin
  mkdir -p $TARGET_PATH/system/etc/wifi

  cp $LOCAL_PATH/busybox/busybox $TARGET_PATH/root/bin/busybox
  cp $LOCAL_PATH/init.rc $TARGET_PATH/root/init.rc
  cp $LOCAL_PATH/init.nokiarm-696board.rc $TARGET_PATH/root/init.nokiarm-696board.rc
  rm -f $TARGET_PATH/root/init.nokiarm-680board.rc
  ln -s init.nokiarm-696board.rc $TARGET_PATH/root/init.nokiarm-680board.rc
  cp $LOCAL_PATH/ueventd.nokiarm-696board.rc $TARGET_PATH/root/ueventd.nokiarm-696board.rc
  rm -f $TARGET_PATH/root/ueventd.nokiarm-680board.rc
  ln -s ueventd.nokiarm-696board.rc $TARGET_PATH/root/ueventd.nokiarm-680board.rc
  cp $LOCAL_PATH/etc/media_profiles.xml $TARGET_PATH/system/etc/media_profiles.xml
  cp $LOCAL_PATH/etc/vold.fstab $TARGET_PATH/system/etc/vold.fstab
  cp $LOCAL_PATH/etc/modem.conf $TARGET_PATH/system/etc/modem.conf
  cp $LOCAL_PATH/etc/gps.conf $TARGET_PATH/system/etc/gps.conf
  cp $LOCAL_PATH/etc/*.sh $TARGET_PATH/system/etc/
  chmod a+x $TARGET_PATH/system/etc/*.sh
  cp $LOCAL_PATH/etc/wifi/wpa_supplicant.conf $TARGET_PATH/system/etc/wifi/wpa_supplicant.conf
  cp $LOCAL_PATH/etc/excluded-input-devices.xml $TARGET_PATH/system/etc/excluded-input-devices.xml
  cp $LOCAL_PATH/system/xbin/rr $TARGET_PATH/system/xbin/rr
  rm -rf $TARGET_PATH/system/etc/firmware
  mkdir -p $TARGET_PATH/system/etc/firmware
  cp -rf $KERNEL_PATH/firmware/* $TARGET_PATH/system/etc/firmware/
  cp -rf $KERNEL_PATH/hacks/* $TARGET_PATH/system/bin/
  cp $TARGET_PATH/obj/EXECUTABLES/fakedsme_intermediates/fakedsme $TARGET_PATH/system/bin/
}


function install_sgx()
{
  CURDIR=$(pwd)
  cd $CURDIR/hardware/ti/sgx/gfx_rel_es6.x_android;
  ./install.sh -u --no-x --no-bcdevice --root $CURDIR/out/target/product/$DEVICE
  ./install.sh --no-x --no-bcdevice --root $CURDIR/out/target/product/$DEVICE
  cp $CURDIR/hardware/ti/sgx/gfx_rel_es5.x_android/rc.pvr $CURDIR/out/target/product/$DEVICE/system/bin/sgx/;
  cd $CURDIR
}

# Kernel modules
function install_km_fm()
{
  rm -rf $TARGET_PATH/system/lib/modules/$KERNEL_VER
  mkdir -p $TARGET_PATH/system/lib/modules/$KERNEL_VER
  cp -rf $KERNEL_PATH/modules/* $TARGET_PATH/system/lib/modules/
  rm -f $TARGET_PATH/system/lib/modules/current
  ln -s $KERNEL_VER $TARGET_PATH/system/lib/modules/current

  mkdir -p $TARGET_PATH/system/bin/sgx/
  cp -f `find $KERNEL_PATH -name omaplfb.ko` $TARGET_PATH/system/bin/sgx/
  cp -f `find $KERNEL_PATH -name pvrsrvkm.ko` $TARGET_PATH/system/bin/sgx/
  mkdir -p $TARGET_PATH/system/vendor/firmware
  cp -rf $KERNEL_PATH/vendor/* $TARGET_PATH/system/vendor/
}

function install_hw_utils()
{
  # Input device calibration files
  cp $LOCAL_PATH/Atmel_mXT_Touchscreen.idc $TARGET_PATH/system/usr/idc/Atmel_mXT_Touchscreen.idc
  cp $LOCAL_PATH/TWL4030_Keypad.idc $TARGET_PATH/system/usr/idc/TWL4030_Keypad.idc
  cp $LOCAL_PATH/TWL4030_Keypad.kl $TARGET_PATH/system/usr/keylayout/TWL4030_Keypad.kl
  cp $LOCAL_PATH/TWL4030_Keypad.kcm $TARGET_PATH/system/usr/keychars/TWL4030_Keypad.kcm

  # Permissions
  cp frameworks/base/data/etc/handheld_core_hardware.xml $TARGET_PATH/system/etc/permissions/handheld_core_hardware.xml
  cp frameworks/base/data/etc/android.hardware.wifi.xml $TARGET_PATH/system/etc/permissions/android.hardware.wifi.xml
  cp frameworks/base/data/etc/android.hardware.telephony.gsm.xml $TARGET_PATH/system/etc/permissions/android.hardware.telephony.gsm.xml
  cp frameworks/base/data/etc/android.hardware.location.gps.xml $TARGET_PATH/system/etc/permissions/android.hardware.location.gps.xml
  cp frameworks/base/data/etc/android.software.sip.voip.xml $TARGET_PATH/system/etc/permissions/android.software.sip.voip.xml
}

function install_b2g_helpers()
{
  cp $TARGET_PATH/obj/EXECUTABLES/rilproxy_intermediates/rilproxy $TARGET_PATH/system/bin/
  cp $TARGET_PATH/obj/EXECUTABLES/fakeperm_intermediates/fakeperm $TARGET_PATH/system/bin/
  cp $TARGET_PATH/obj/EXECUTABLES/omapupdater_intermediates/omapupdater $TARGET_PATH/system/bin/
  cat gonk-misc/init.b2g.rc >> $TARGET_PATH/root/init.nokiarm-696board.rc
  rm -rf $TARGET_PATH/system/b2g
  cp -rf $GECKO_OBJDIR/dist/b2g $TARGET_PATH/system/
  mkdir -p $TARGET_PATH/root/data
  rm -rf $TARGET_PATH/root/data/local
  cp -rf gaia/profile $TARGET_PATH/root/data/local
}

function install_busybox_links()
{
  # Setup bin dir, busybox and links
  mkdir $TARGET_PATH/root/bin
  cd $TARGET_PATH/root/bin/
  busyfiles="sh ash base64 bash cat chgrp chmod chown cp cttyhack date dd df echo egrep false fgrep fsync grep gunzip gzip iostat kill ln ls mkdir mknod more mount mpstat mv netstat nice pidof powertop printenv ps pwd rm rmdir sleep stat sync tar touch true umount uname usleep vi watch zcat"
  set -- junk $busyfiles
  shift
  for word; do
    rm -f $word
    ln -s /bin/busybox $word;
  done
  cd $CURDIR

  # setup sbin dir
  mkdir $TARGET_PATH/root/sbin
  cd $TARGET_PATH/root/sbin/
  busyfiles="depmod fdisk halt ifconfig insmod losetup lsmod modinfo modprobe poweroff reboot rmmod route swapoff swapon"
  set -- junk $busyfiles
  shift
  for word; do
    rm -f $word
    ln -s /bin/busybox $word;
  done
  cd $CURDIR

  # setup /usr/bin dir
  mkdir -p $TARGET_PATH/root/usr/bin
  cd $TARGET_PATH/root/usr/bin
  busyfiles="[ [[ basename bunzip2 bzcat bzip2 chrt cut dirname du env expr find free fuser head id install killall less lzcat lzma md5sum nohup od pmap readahead readlink realpath renice seq sort split strings tail tee test time tr unlzma unzip wc which xargs yes"
  set -- junk $busyfiles
  shift
  for word; do
    rm -f $word
    ln -s /bin/busybox $word;
  done
  cd $CURDIR

  # setup /usr/sbin dir
  mkdir -p $TARGET_PATH/root/usr/sbin
  cd $TARGET_PATH/root/usr/sbin
  busyfiles="chroot fbset rfkill ubiattach ubidetach"
  set -- junk $busyfiles
  shift
  for word; do
    rm -f $word
    ln -s /bin/busybox $word;
  done
  cd $CURDIR
}

function install_system_props()
{
  echo "# begin addon properties
ro.addon.type=gapps
ro.addon.platform=ICS
ro.addon.version=gapps-ics-20120317
# end addon properties" > $TARGET_PATH/system/etc/g.prop

  echo "
ro.secure=0
ro.allow.mock.location=1
ro.debuggable=1

#persist.sys.usb.config=adb
persist.service.adb.enable=1
service.adb.tcp.port=5039

debug.nfc.LOW_LEVEL_TRACES=1

#
# FakeGPS location/settings
#
hw.fakegps.latitude=55.085754
hw.fakegps.longitude=38.770379
hw.fakegps.altitude=310.0
" > $TARGET_PATH/root/default.prop
}

function pack_b2g_fs_full()
{
  rm -rf $TARGET_PATH/b2g_fs
  mkdir -p $TARGET_PATH/b2g_fs
  cp -rf $TARGET_PATH/root/* $TARGET_PATH/b2g_fs
  cp -rf $TARGET_PATH/system/* $TARGET_PATH/b2g_fs/system/
  cd $TARGET_PATH/b2g_fs && tar -cf ../b2g_fs.tar ./
  rm -f $TARGET_PATH/b2g_fs.tar.gz
  gzip $TARGET_PATH/b2g_fs.tar
  rm -rf $TARGET_PATH/b2g_fs
}

install_core_init
install_busybox_links
install_system_props
install_b2g_helpers
install_hw_utils
install_sgx
install_km_fm
pack_b2g_fs_full
