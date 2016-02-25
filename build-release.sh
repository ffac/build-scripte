#!/bin/bash
# 2015-16 Malte Moeller: Basic Script to build all targets

if [ $# -ne 5 ]; then
        echo "Required Paramater: <GLUON_RELEASE> <branch> <number> <broken> <gracetime in days>"
	echo "e.g. 2015.1.2 beta 06 1 3"
        exit 1;
fi

GLUON_RELEASE=v$1
BRANCH=$2
NUM=$3
BROKEN=$4
PRIORITY=$5

RELEASE_TAG="$GLUON_RELEASE.${BRANCH:0:1}.$NUM"
FFAC_RELEASE="${GLUON_RELEASE:1}-$BRANCH$NUM"

# Some permanet definitions

TARGETS="ar71xx-generic ar71xx-nand mpc85xx-generic x86-xen_domu x86-kvm_guest"
TARGETSx86="x86-generic x86-64"
THREADS="6"

# Begin Logfiles
{
# Show summery
date

echo $RELEASE_TAG
echo $GLUON_RELEASE
echo $FFAC_RELEASE

echo "Targets: $TARGETS"
echo "Futro Targets: $TARGETSx86"
echo "Using $THREADS Cores"

sleep 5

cd gluon
git checkout master
git pull
git checkout $GLUON_RELEASE

sleep 3

cd site
git checkout master
git pull
git checkout $RELEASE_TAG
cd ..

sleep 3

for TARGET in $TARGETS $TARGETSx86
do
	make clean GLUON_TARGET=$TARGET
done
make update

for TARGET in $TARGETS
do
	date
	make GLUON_BRANCH=$BRANCH GLUON_RELEASE=$FFAC_RELEASE BROKEN=$BROKEN GLUON_TARGET=$TARGET -j $THREADS
done

# Enable boot from interal CF Card for Futro

if [ `grep ^CONFIG_PATA_ATIIXP=y$ openwrt/target/linux/x86/generic/config-default -q ` ]
then
	echo "CONFIG_PATA_ATIIXP=y is already set for x86-generic"
else
	echo "CONFIG_PATA_ATIIXP=y is NOT set for x86-generic, adding"
	echo "CONFIG_PATA_ATIIXP=y" >> openwrt/target/linux/x86/generic/config-default
fi

if [ `grep ^CONFIG_PATA_ATIIXP=y$ openwrt/target/linux/x86/64/config-default -q ` ]
then
        echo "CONFIG_PATA_ATIIXP=y is already set for x86-64"
else
        echo "CONFIG_PATA_ATIIXP=y is NOT set for x86-64, adding"
	echo "CONFIG_PATA_ATIIXP=y" >> openwrt/target/linux/x86/64/config-default
fi


for TARGET in $TARGETSx86
do
	date
	make GLUON_BRANCH=$BRANCH GLUON_RELEASE=$FFAC_RELEASE BROKEN=$BROKEN GLUON_TARGET=$TARGET -j $THREADS
done
date

# Clean up Futro stuff for next build
cd openwrt
git checkout -- target/linux/x86/generic/config-default
git checkout -- target/linux/x86/64/config-default
cd ..


cd output/images/sysupgrade
rm -f md5sum
rm -f *.manifest
md5sum * >> md5sums
cd ../factory
rm -f md5sum
rm -f *.manifest
md5sum * >> md5sums
cd ../../..

make manifest GLUON_BRANCH=$BRANCH BROKEN=$BROKEN GLUON_PRIORITY=$5

} > >(tee -a /var/log/firmware-build/$FFAC_RELEASE.log) 2> >(tee -a /var/log/firmware-build/$FFAC_RELEASE.error.log | tee -a /var/log/firmware-build/$FFAC_RELEASE.log >&2)
