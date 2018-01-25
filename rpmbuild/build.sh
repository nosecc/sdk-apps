#!/bin/sh
# Run from repo root level

# Verify proper command use
if [ "$1" == "" ]; then
  echo "No arguements provided."
  echo "Proper use is: build.sh master/stable"
  exit 1
fi

mkdir -p $WORKSPACE/archive/tmp/doc

# Quickview:
# Build quickview war
COMPONENT=boundless-server-quickview

source ~/.bashrc

cd $WORKSPACE/sdk-apps/quickview
nvm use 6.0.0
npm cache clean
npm i
npm run package <<< "quickview.war"
mv quickview.war $WORKSPACE/archive/quickview-orig.war
cd $WORKSPACE/archive/tmp
jar -xvf ../quickview-orig.war 
cp $WORKSPACE/sdk-apps/rpmbuild/LICENSE.txt doc/
cp $WORKSPACE/sdk-apps/rpmbuild/EULA doc/
jar -cvf ../quickview.war .
rm -f ../quickview-orig.war

# Build quickview RPM
cd $WORKSPACE/sdk-apps/rpmbuild
for dir in BUILD BUILDROOT RPMS SOURCE SPECS SRPMS SRC
do
 [[ -d $WORKSPACE/sdk-apps/rpmbuild/$COMPONENT/$dir ]] && rm -Rf $WORKSPACE/sdk-apps/rpmbuild/$COMPONENT/$dir
  mkdir -p $WORKSPACE/sdk-apps/rpmbuild/$COMPONENT/$dir
done
cp SPECS/${COMPONENT}.spec $COMPONENT/SPECS
mkdir -p $COMPONENT/SRC/opt/boundless/server/quickview
unzip $WORKSPACE/archive/quickview.war -d $COMPONENT/SRC/opt/boundless/server/quickview/
mkdir -p $COMPONENT/SRC/usr/share/doc/
mv $COMPONENT/SRC/opt/boundless/server/quickview/doc $COMPONENT/SRC/usr/share/doc/$COMPONENT
mkdir -p $COMPONENT/SRC/etc/tomcat8/Catalina/localhost/
cp tomcat-context/quickview.xml $COMPONENT/SRC/etc/tomcat8/Catalina/localhost/
cp tomcat-context/quickview.xml $COMPONENT/SRC/etc/tomcat8/Catalina/localhost/quickview.xml.new

# Do versioning
if [ "$1" == "master" ]; then
  CURRENT_VER=${DATE_TIME_STAMP}
#elif [ "$1" == "test" ];  then
#  CURRENT_VER=`cat $WORKSPACE/version.txt`rc
elif [ "$1" == "stable" ]; then
#  CURRENT_VER=`cat $WORKSPACE/version.txt`
  CURRENT_VER=${VER}
else
  echo "Improper arguement provided."
  echo "Proper use is: build.sh dev/master"
  exit 1
fi
sed -i "s/REPLACE_VERSION/${CURRENT_VER}/" $WORKSPACE/sdk-apps/rpmbuild/$COMPONENT/SPECS/$COMPONENT.spec
sed -i "s/REPLACE_RELEASE/$BUILD_NUMBER/" $WORKSPACE/sdk-apps/rpmbuild/$COMPONENT/SPECS/$COMPONENT.spec
sed -i "s/CURRENT_VER/${CURRENT_VER}/g" $WORKSPACE/sdk-apps/rpmbuild/$COMPONENT/SPECS/$COMPONENT.spec

if [[ "$CURRENT_VER" =~ (.*[^0-9])([0-9]+)$ ]]; then
  NEXT_VER="${BASH_REMATCH[1]}$((${BASH_REMATCH[2]} + 1))"
else
  NEXT_VER="${CURRENT_VER}.1"
fi

sed -i "s/NEXT_VER/${NEXT_VER}/g" $WORKSPACE/sdk-apps/rpmbuild/$COMPONENT/SPECS/$COMPONENT.spec


#sed -i "s/REPLACE_VERSION/$MINOR_VERSION/" $WORKSPACE/rpmbuild/$COMPONENT/SPECS/$COMPONENT.spec

sed -i "s|REPLACE_RPMDIR|${WORKSPACE}/archive|" $WORKSPACE/sdk-apps/rpmbuild/$COMPONENT/SPECS/$COMPONENT.spec
find $WORKSPACE/sdk-apps/rpmbuild/$COMPONENT/SRC/ -type f | sed "s|$WORKSPACE/sdk-apps/rpmbuild/$COMPONENT/SRC||" | awk -F\\ '{print "\""$1"\""}' >> $WORKSPACE/sdk-apps/rpmbuild/$COMPONENT/SPECS/$COMPONENT.spec

rpmbuild -ba --define "_topdir $WORKSPACE/sdk-apps/rpmbuild/$COMPONENT" --define "_WORKSPACE $WORKSPACE/sdk-apps/rpmbuild/$COMPONENT" --buildroot $WORKSPACE/sdk-apps/rpmbuild/$COMPONENT/BUILDROOT/ $WORKSPACE/sdk-apps/rpmbuild/$COMPONENT/SPECS/$COMPONENT.spec

#for i in `find $WORKSPACE/rpmbuild/ -name *.rpm`; do
#  mv $i $WORKSPACE/archive/
#done
