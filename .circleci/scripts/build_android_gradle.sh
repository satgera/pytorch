#!/usr/bin/env bash
set -eux -o pipefail

echo "build_android_gradle.sh"
echo "$(pwd)"

# ---------------------------------
# Installing openjdk-8
# https://hub.docker.com/r/picoded/ubuntu-openjdk-8-jdk/dockerfile/

sudo apt-get update && \
    sudo apt-get install -y openjdk-8-jdk && \
    sudo apt-get install -y ant && \
    sudo apt-get clean && \
    sudo rm -rf /var/lib/apt/lists/* && \
    sudo rm -rf /var/cache/oracle-jdk8-installer;

sudo apt-get update && \
    sudo apt-get install -y ca-certificates-java && \
    sudo apt-get clean && \
    sudo update-ca-certificates -f && \
    sudo rm -rf /var/lib/apt/lists/* && \
    sudo rm -rf /var/cache/oracle-jdk8-installer;

# ---------------------------------
# Installing android sdk
# https://github.com/circleci/circleci-images/blob/staging/android/Dockerfile.m4

_sdk_version=sdk-tools-linux-3859397.zip
_android_home=/opt/android/sdk

rm -rf $_android_home
sudo mkdir -p $_android_home
curl --silent --show-error --location --fail --retry 3 --output /tmp/$_sdk_version https://dl.google.com/android/repository/$_sdk_version
sudo unzip -q /tmp/$_sdk_version -d $_android_home
rm /tmp/$_sdk_version

sudo chmod -R 755 $_android_home

export ANDROID_HOME=$_android_home
export ADB_INSTALL_TIMEOUT=120

export PATH="${ANDROID_HOME}/emulator:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools:${PATH}"
echo "PATH:${PATH}"

sudo mkdir ~/.android
sudo chmod -R 755 ~/.android
sudo echo '### User Sources for Android SDK Manager' > ~/.android/repositories.cfg
sudo chmod -R 755 ~/.android

sudo yes | sudo sdkmanager --licenses
sudo yes | sudo sdkmanager --update

sdkmanager \
  "tools" \
  "platform-tools" \
  "emulator"

sdkmanager \
  "build-tools;28.0.3"

sdkmanager "platforms;android-28"

sdkmanager --list

# ---------------------------------
# Installing android sdk
# https://github.com/keeganwitt/docker-gradle/blob/a206b4a26547df6d8b29d06dd706358e3801d4a9/jdk8/Dockerfile
export GRADLE_VERSION=5.1.1
_gradle_home=/opt/gradle
sudo rm -rf $_gradle_home
sudo mkdir -p $_gradle_home

wget --no-verbose --output-document=/tmp/gradle.zip \
"https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip"

sudo unzip -q /tmp/gradle.zip -d $_gradle_home
rm /tmp/gradle.zip

sudo chmod -R 755 $_gradle_home

export GRADLE_HOME=$_gradle_home/gradle-$GRADLE_VERSION

export PATH="${GRADLE_HOME}/bin/:${PATH}"
echo "PATH:${PATH}"

gradle --version

# ---------------------------------
# --- Everything above will be in docker image ---
PYTORCH_ANDROID_SRC_MAIN_DIR=~/workspace/android/pytorch_android/src/main

JNI_LIBS_DIR=${PYTORCH_ANDROID_SRC_MAIN_DIR}/jniLibs
mkdir -p $JNI_LIBS_DIR
JNI_LIBS_DIR_x86=${JNI_LIBS_DIR}/x86
mkdir -p $JNI_LIBS_DIR_x86
JNI_INCLUDE_DIR_x86=${JNI_INCLUDE_DIR}/x86
echo "ANDROID_GRADLE_BUILD_ONLY_X86:${ANDROID_GRADLE_BUILD_ONLY_X86}"

if [ -z "${ANDROID_GRADLE_BUILD_ONLY_X86}" ]; then
    BUILD_ANDROID_INCLUDE_DIR_x86=~/workspace/build_android_install_x86/install/include
    BUILD_ANDROID_LIB_DIR_x86=~/workspace/build_android_install_x86/install/lib

    BUILD_ANDROID_INCLUDE_DIR_x86_64=~/workspace/build_android_install_x86_64/install/include
    BUILD_ANDROID_LIB_DIR_x86_64=~/workspace/build_android_install_x86_64/install/lib

    BUILD_ANDROID_INCLUDE_DIR_arm_v7a=~/workspace/build_android_install_arm_v7a/install/include
    BUILD_ANDROID_LIB_DIR_arm_v7a=~/workspace/build_android_install_arm_v7a/install/lib

    BUILD_ANDROID_INCLUDE_DIR_arm_v8a=~/workspace/build_android_install_arm_v8a/install/include
    BUILD_ANDROID_LIB_DIR_arm_v8a=~/workspace/build_android_install_arm_v8a/install/lib

    JNI_LIBS_DIR_x86_64=${JNI_LIBS_DIR}/x86_64
    mkdir -p $JNI_LIBS_DIR_x86_64
    JNI_LIBS_DIR_arm_v7a=${JNI_LIBS_DIR}/armeabi-v7a
    mkdir -p $JNI_LIBS_DIR_arm_v7a
    JNI_LIBS_DIR_arm_v8a=${JNI_LIBS_DIR}/arm64-v8a
    mkdir -p $JNI_LIBS_DIR_arm_v8a

    JNI_INCLUDE_DIR=${PYTORCH_ANDROID_SRC_MAIN_DIR}/cpp/libtorch_include
    mkdir -p $JNI_INCLUDE_DIR

    JNI_INCLUDE_DIR_x86_64=${JNI_INCLUDE_DIR}/x86_64
    JNI_INCLUDE_DIR_arm_v7a=${JNI_INCLUDE_DIR}/armeabi-v7a
    JNI_INCLUDE_DIR_arm_v8a=${JNI_INCLUDE_DIR}/arm64-v8a

    ln -s ${BUILD_ANDROID_INCLUDE_DIR_x86_64} ${JNI_INCLUDE_DIR_x86_64}
    ln -s ${BUILD_ANDROID_INCLUDE_DIR_arm_v7a} ${JNI_INCLUDE_DIR_arm_v7a}
    ln -s ${BUILD_ANDROID_INCLUDE_DIR_arm_v8a} ${JNI_INCLUDE_DIR_arm_v8a}

    ln -s ${BUILD_ANDROID_LIB_DIR_x86_64}/libc10.so ${JNI_LIBS_DIR_x86_64}/libc10.so
    ln -s ${BUILD_ANDROID_LIB_DIR_x86_64}/libtorch.so ${JNI_LIBS_DIR_x86_64}/libtorch.so

    ln -s ${BUILD_ANDROID_LIB_DIR_arm_v7a}/libc10.so ${JNI_LIBS_DIR_arm_v7a}/libc10.so
    ln -s ${BUILD_ANDROID_LIB_DIR_arm_v7a}/libtorch.so ${JNI_LIBS_DIR_arm_v7a}/libtorch.so

    ln -s ${BUILD_ANDROID_LIB_DIR_arm_v8a}/libc10.so ${JNI_LIBS_DIR_arm_v8a}/libc10.so
    ln -s ${BUILD_ANDROID_LIB_DIR_arm_v8a}/libtorch.so ${JNI_LIBS_DIR_arm_v8a}/libtorch.so
else
    #x86 only
    BUILD_ANDROID_INCLUDE_DIR_x86=~/workspace/build_android/install/include
    BUILD_ANDROID_LIB_DIR_x86=~/workspace/build_android/install/lib
fi

ln -s ${BUILD_ANDROID_INCLUDE_DIR_x86} ${JNI_INCLUDE_DIR_x86}
ln -s ${BUILD_ANDROID_LIB_DIR_x86}/libc10.so ${JNI_LIBS_DIR_x86}/libc10.so
ln -s ${BUILD_ANDROID_LIB_DIR_x86}/libtorch.so ${JNI_LIBS_DIR_x86}/libtorch.so

echo "ANDROID_HOME:${ANDROID_HOME}"
echo "ANDROID_NDK_HOME:${ANDROID_NDK_HOME}"

export GRADLE_LOCAL_PROPERTIES=~/workspace/android/local.properties
rm -f $GRADLE_LOCAL_PROPERTIES
echo "sdk.dir=/opt/android/sdk" >> $GRADLE_LOCAL_PROPERTIES
echo "ndk.dir=/opt/ndk" >> $GRADLE_LOCAL_PROPERTIES

if [ -z "${ANDROID_GRADLE_BUILD_ONLY_X86}" ]; then
    gradle -p ~/workspace/android/ assembleRelease
else
    gradle -PABI_FILTERS=x86 -p ~/workspace/android/ assembleRelease
fi


find . -type f -name *aar | xargs ls -lah
