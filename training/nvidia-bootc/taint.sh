#!/bin/bash

set -e

if [ "${TARGET_ARCH}" == "" ]; then
    export TARGET_ARCH="$(arch)"
fi

if [ "${OS_VERSION_MAJOR}" == "" ]; then
    . /etc/os-release
    export OS_VERSION_MAJOR="$(echo ${VERSION} | cut -d'.' -f 1)"
fi

DRIVER_STREAM=$(echo ${DRIVER_VERSION} | cut -d '.' -f 1)
CUDA_VERSION_ARRAY=(${CUDA_VERSION//./ }) 
CUDA_DASHED_VERSION=${CUDA_VERSION_ARRAY[0]}-${CUDA_VERSION_ARRAY[1]} 
CUDA_REPO_ARCH=${TARGET_ARCH} 

if [ "${TARGET_ARCH}" == "aarch64" ]; then
    CUDA_REPO_ARCH="sbsa"
fi

dnf config-manager --best --nodocs --setopt=install_weak_deps=False --save
dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel${OS_VERSION_MAJOR}/${CUDA_REPO_ARCH}/cuda-rhel${OS_VERSION_MAJOR}.repo

dnf -y module enable nvidia-driver:${DRIVER_STREAM}/default
dnf install -y \
        nvidia-driver-cuda-${DRIVER_VERSION} \
        nvidia-driver-libs-${DRIVER_VERSION} \
        nvidia-driver-NVML-${DRIVER_VERSION} \
        cuda-compat-${CUDA_DASHED_VERSION} \
        cuda-cudart-${CUDA_DASHED_VERSION} \
        nvidia-persistenced-${DRIVER_VERSION} \
        nvidia-container-toolkit \
        ${EXTRA_RPM_PACKAGES}

if [ "$DRIVER_TYPE" != "vgpu" ] && [ "$TARGET_ARCH" != "arm64" ]; then
    versionArray=(${DRIVER_VERSION//./ })
    DRIVER_BRANCH=${versionArray[0]}
    dnf module enable -y nvidia-driver:${DRIVER_BRANCH}
    dnf install -y nvidia-fabric-manager-${DRIVER_VERSION} libnvidia-nscq-${DRIVER_BRANCH}-${DRIVER_VERSION}
fi

dnf clean all
ln -s /usr/lib/systemd/system/nvidia-toolkit-firstboot.service /usr/lib/systemd/system/basic.target.wants/nvidia-toolkit-firstboot.service
echo "blacklist nouveau" > /etc/modprobe.d/blacklist_nouveau.conf
