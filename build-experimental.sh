TARGETS="ar71xx-generic ar71xx-nand mpc85xx-generic brcm2708-bcm2709 brcm2708-bcm2708 sunxi ramips-rt305x x86-xen_domu x86-kvm_guest"
TARGETSx86="x86-generic x86-64"
GLUON_RELEASE="v2016.1"
FFAC_RELEASE=2016.1~1-exp$(date '+%Y%m%d')
THREADS=6

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

git pull
git checkout $GLUON_RELEASE

make update

for TARGET in $TARGETS
do
        date
        make GLUON_BRANCH=experimental GLUON_RELEASE=$FFAC_RELEASE BROKEN=1 GLUON_TARGET=$TARGET -j $THREADS
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
        make GLUON_BRANCH=experimental GLUON_RELEASE=$FFAC_RELEASE BROKEN=1 GLUON_TARGET=$TARGET -j $THREADS
done
date

# Clean up Futro stuff for next build
cd openwrt
git checkout -- target/linux/x86/generic/config-default
git checkout -- target/linux/x86/64/config-default
cd ..

make manifest GLUON_BRANCH=experimental BROKEN=1 GLUON_PRIORITY=0

} > >(tee -a /var/log/firmware-build/$FFAC_RELEASE.log) 2> >(tee -a /var/log/firmware-build/$FFAC_RELEASE.error.log | tee -a /var/log/firmware-build/$FFAC_RELEASE.log >&2)

