# Functions:
# pack_boot_image

source functions/common.sh


pack_boot_image()
{
    # boot loader
    local boot=/tmp/boot
    [ -d ${boot} ] && rm -rf ${boot}
    mkdir -p ${boot}

    # initramfs
    echo
   	info_msg "initramfs"
    local ramdisk=/tmp/ramdisk
    [ -d ${ramdisk} ] && rm -rf ${ramdisk}
    mkdir -p ${ramdisk}
    cd ${ramdisk}
    ## busybox
    cp -rf ${BUILD}/initramfs/* ./
    ## overlay
    cp -rf ${HOME}/scripts/overlays/initramfs/* ./
    ## dptx.bin
    local dptx_src=${BUILD}/rk-rootfs-build/overlay-firmware/lib/firmware/rockchip/dptx.bin
    local dptx_dst=${ramdisk}/lib/firmware/rockchip
    mkdir -p ${dptx_dst}
    cp -vf ${dptx_src} ${dptx_dst}
    ## ramdisk.cpio.gz
    rm -f linuxrc
    find . | cpio -oH newc | gzip > ${boot}/ramdisk.cpio.gz

    # boot
    cd ${BUILD}/kernel/arch/arm64/boot
    ## kernel
    echo
   	info_msg "kernel"
    cp -v Image.gz ${boot}/kernel.gz
    ## dtb
    echo
   	info_msg "dtb(s)"
    cp -v dts/rockchip/rk3399-nanopi4-rev0*.dtb ${boot}/

    # resource
    echo
   	info_msg "resource"
    cd ${boot}/
    cp ${HOME}/scripts/boot/logo.bmp ./
    cp ${HOME}/scripts/boot/logo_kernel.bmp ./
    ${BUILD}/kernel/scripts/resource_tool --verbose --pack --root=/ --image=${DISTRO}/resource.img logo.bmp logo_kernel.bmp rk3399-nanopi4-rev01.dtb

    # FIT
    echo
   	info_msg "flattened device tree"
    cd ${HOME}/scripts/boot
    cp -v boot.cmd fitImage.its ${boot}/
    ## binary path
    local fit_path=${boot}/uImage
    [ -d ${fit_path} ] && rm -rf ${fit_path}
    mkdir -p ${fit_path}
    ## mkimage
    cd ${BUILD}/u-boot/tools
    ./mkimage -C none -A arm64 -T script -d ${boot}/boot.cmd ${fit_path}/boot.scr
    ./mkimage -f ${boot}/fitImage.its ${fit_path}/fitImage.itb
    ## ext2fs
    local boot_img=${DISTRO}/boot.img
    [ -f ${boot_img} ] && rm -f ${boot_img}
    echo
   	info_msg "boot.img"
    genext2fs -b 16384 -d ${fit_path} ${boot_img}
    e2fsck -p -f ${boot_img}
    resize2fs -M ${boot_img}
}
