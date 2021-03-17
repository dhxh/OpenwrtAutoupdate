#!/bin/bash
# https://github.com/Hyy2001X/AutoBuild-Actions
# AutoBuild Module by Hyy2001
# AutoBuild Functions

GET_TARGET_INFO() {
	[ -f ${GITHUB_WORKSPACE}/Openwrt.info ] && . ${GITHUB_WORKSPACE}/Openwrt.info
        TARGET_BOARD="$(awk -F '[="]+' '/TARGET_BOARD/{print $2}' .config)"
	TARGET_SUBTARGET="$(awk -F '[="]+' '/TARGET_SUBTARGET/{print $2}' .config)"
	TARGET_PROFILE="$(egrep -o "CONFIG_TARGET.*DEVICE.*=y" .config | sed -r 's/.*DEVICE_(.*)=y/\1/')"
	if [[ "${TARGET_BOARD}-64" == "x86-64" ]];then
		TARGET_PROFILE="64"
		Devicename="x86-64"
	else
		TARGET_PROFILE="$(egrep -o "CONFIG_TARGET.*DEVICE.*=y" .config | sed -r 's/.*DEVICE_(.*)=y/\1/')"
		Devicename="${TARGET_PROFILE}"
	fi
	[[ -z "${TARGET_PROFILE}" ]] && TARGET_PROFILE="Unknown"
        if [[ "${TARGET_BOARD}-64" == "x86-64" ]]; then
		grep "CONFIG_TARGET_IMAGES_GZIP=y" ${Home}/.config > /dev/null 2>&1
		if [[ ! $? -ne 0 ]];then
			Firmware_sfx="img.gz"
		else
			Firmware_sfx="img"
		fi
        elif [[ "${TARGET_BOARD}" == "bcm53xx" ]]; then
	         Firmware_sfx="trx"
        elif [[ "${TARGET_BOARD}-${TARGET_SUBTARGET}" = "ramips-mt7621" ]]; then
	         Firmware_sfx="bin"
	fi
	case "${REPO_URL}" in
	"${LEDE}")
		COMP1="lede"
		COMP2="lean"
		if [[ "${TARGET_BOARD}" == "x86" ]]; then
			Legacy_Firmware="openwrt-x86-64-generic-squashfs-combined.${Firmware_sfxo}"
			EFI_Default_Firmware="openwrt-x86-64-generic-squashfs-combined-efi.${Firmware_sfxo}"
		elif [[ "${TARGET_BOARD}" == "bcm53xx" ]]; then
			Default_Firmware="openwrt-${TARGET_BOARD}-${TARGET_SUBTARGET}-${TARGET_PROFILE}-squashfs.trx"
		elif [[ "${TARGET_BOARD}-${TARGET_SUBTARGET}" = "ramips-mt7621" ]]; then
			Default_Firmware="openwrt-${TARGET_BOARD}-${TARGET_SUBTARGET}-${TARGET_PROFILE}-squashfs-sysupgrade.bin"
		fi
	;;
	"${LIENOL}") 
		COMP1="lienol"
		COMP2="${REPO_BRANCH}"
		if [[ "${TARGET_BOARD}" == "x86" ]]; then
			Legacy_Firmware="openwrt-x86-64-generic-squashfs-combined.${Firmware_sfxo}"
			EFI_Default_Firmware="openwrt-x86-64-generic-squashfs-combined-efi.${Firmware_sfxo}"
		elif [[ "${TARGET_BOARD}" == "bcm53xx" ]]; then
			Default_Firmware="openwrt-${TARGET_BOARD}-${TARGET_SUBTARGET}-${TARGET_PROFILE}-squashfs.trx"
		elif [[ "${TARGET_BOARD}-${TARGET_SUBTARGET}" = "ramips-mt7621" ]]; then
			Default_Firmware="openwrt-${TARGET_BOARD}-${TARGET_SUBTARGET}-${TARGET_PROFILE}-squashfs-sysupgrade.bin"
		fi
	;;
	"${PROJECT}")
		COMP1="immortalwrt"
                COMP2="${REPO_BRANCH}"
		if [[ "${TARGET_BOARD}" == "x86" ]]; then
			Default_Firmware="immortalwrt-x86-64-generic-squashfs-combined.${Firmware_sfxo}"
			EFI_Default_Firmware="immortalwrt-x86-64-generic-squashfs-combined-efi.${Firmware_sfxo}"
		elif [[ "${TARGET_BOARD}" == "bcm53xx" ]]; then
			Default_Firmware="immortalwrt-${TARGET_BOARD}-${TARGET_SUBTARGET}-${TARGET_PROFILE}-squashfs.trx"
		elif [[ "${TARGET_BOARD}-${TARGET_SUBTARGET}" = "ramips-mt7621" ]]; then
			Default_Firmware="immortalwrt-${TARGET_BOARD}-${TARGET_SUBTARGET}-${TARGET_PROFILE}-squashfs-sysupgrade.bin"
		fi	
	;;		
	esac
	AutoBuild_Info=${GITHUB_WORKSPACE}/openwrt/package/base-files/files/etc/openwrt_info
	Github_Repo="$(grep "https://github.com/[a-zA-Z0-9]" ${GITHUB_WORKSPACE}/.git/config | cut -c8-100)"
	AutoUpdate_Version="$(awk 'NR==6' package/base-files/files/bin/AutoUpdate.sh | awk -F '[="]+' '/Version/{print $2}')"
	Openwrt_Version=${Compile_Date_Day}-${Compile_Date_Minute}
}

Diy_Part1() {
	sed -i '/luci-app-autoupdate/d' .config > /dev/null 2>&1
	echo -e "\nCONFIG_PACKAGE_luci-app-autoupdate=y" >> .config
	sed -i '/luci-app-ttyd/d' .config > /dev/null 2>&1
	echo -e "\nCONFIG_PACKAGE_luci-app-ttyd=y" >> .config
}

Diy_Part2() {
	GET_TARGET_INFO
	[[ -z "${AutoUpdate_Version}" ]] && AutoUpdate_Version="Unknown"
	[[ -z "${Author}" ]] && Author="Unknown"
	echo "Author: ${Author}"
	echo "Openwrt Version: ${Openwrt_Version}"
	echo "Router: ${TARGET_PROFILE}"
	echo "Github: ${Github_Repo}"
	echo "${Openwrt_Version}" > ${AutoBuild_Info}
	echo "${Github_Repo}" >> ${AutoBuild_Info}
	echo "${Devicename}" >> ${AutoBuild_Info}
	echo "${COMP1}" >> ${AutoBuild_Info}
	echo "${COMP2}" >> ${AutoBuild_Info}
	echo "${Firmware_sfx}" >> ${AutoBuild_Info}
}

Diy_Part3() {
	GET_TARGET_INFO
	Firmware_Path="bin/targets/${TARGET_BOARD}/${TARGET_SUBTARGET}"
	mkdir bin/Firmware
	case "${TARGET_PROFILE}" in
	x86_64)
		cd ${Firmware_Path}
		Legacy_Firmware="${Legacy_Firmware}"
		EFI_Firmware="${EFI_Default_Firmware}"
		if [ -f "${Legacy_Firmware}" ];then
		        AutoBuild_Firmware="${COMP1}-${COMP2}-Legacy-${TARGET_BOARD}-${TARGET_PROFILE}-${Openwrt_Version}"
			_MD5=$(md5sum ${Legacy_Firmware} | cut -d ' ' -f1)
			_SHA256=$(sha256sum ${Legacy_Firmware} | cut -d ' ' -f1)
			touch ${Home}/bin/Firmware/${AutoBuild_Firmware}.detail
			echo -e "\nMD5:${_MD5}\nSHA256:${_SHA256}" > ${Home}/bin/Firmware/${AutoBuild_Firmware}.detail
			mv -f ${Firmware_Path}/${Legacy_Firmware} ${Home}/bin/Firmware/${AutoBuild_Firmware}.${Firmware_sfx}
			echo "Legacy Firmware is detected !"
		fi
		if [ -f "${EFI_Firmware}" ];then
		        AutoBuild_Firmware="${COMP1}-${COMP2}-UEFI-${TARGET_BOARD}-${TARGET_PROFILE}-${Openwrt_Version}"
			_MD5=$(md5sum ${EFI_Firmware} | cut -d ' ' -f1)
			_SHA256=$(sha256sum ${EFI_Firmware} | cut -d ' ' -f1)
			touch ${Home}/bin/Firmware/${AutoBuild_Firmware}-UEFI.detail
			echo -e "\nMD5:${_MD5}\nSHA256:${_SHA256}" > ${Home}/bin/Firmware/${AutoBuild_Firmware}.detail
			cp ${Firmware_Path}/${EFI_Firmware} ${Home}/bin/Firmware/${AutoBuild_Firmware}.${Firmware_sfx}
			echo "UEFI Firmware is detected !"
		fi
	;;
	*)
		cd ${Home}
		AutoBuild_Firmware="${COMP1}-${COMP2}-${TARGET_PROFILE}-${Openwrt_Version}.${Firmware_sfx}"
		AutoBuild_Detail="${COMP1}-${COMP2}-${TARGET_PROFILE}-${Openwrt_Version}.detail"
		echo "Firmware: ${AutoBuild_Firmware}"
		mv -f ${Firmware_Path}/${Default_Firmware} bin/Firmware/${AutoBuild_Firmware}
		_MD5=$(md5sum bin/Firmware/${AutoBuild_Firmware} | cut -d ' ' -f1)
		_SHA256=$(sha256sum bin/Firmware/${AutoBuild_Firmware} | cut -d ' ' -f1)
		echo -e "\nMD5:${_MD5}\nSHA256:${_SHA256}" > bin/Firmware/${AutoBuild_Detail}
	;;
	esac
	cd ${Home}
	echo "Actions Avaliable: $(df -h | grep "/dev/root" | awk '{printf $4}')"
}
