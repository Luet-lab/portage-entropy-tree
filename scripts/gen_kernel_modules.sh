#!/bin/bash
# Kernel module bump

MODULES=(
"net-vpn@wireguard@0.0.20190406-r1"
"app-emulation@virtualbox-guest-additions@6.0.14"
"app-emulation@virtualbox-modules@6.0.14"
"app-laptop@tp_smapi@0.43"
"media-video@v4l2loopback@0.12.1"
"net-firewall@rtsp-conntrack@4.18"
"net-firewall@xtables-addons@3.7"
"net-wireless@broadcom-sta@6.30.223.271-r6"
"sys-fs@vhba@20190410"
"sys-fs@zfs-kmod@0.8.2"
"sys-power@acpi_call@3.17"
"sys-power@bbswitch@0.8-r2"
"x11-drivers@nvidia-drivers@430.26"
"x11-drivers@nvidia-drivers@390.87-r2"
"x11-drivers@nvidia-drivers@340.107-r1"
)

KERNELS=$(ls $ROOT_DIR/sys-kernel/linux-sabayon)
JOBS=${JOBS:-3}

for i in $KERNELS;
do
    for m in ${MODULES[@]};
    do
        parts=($(echo $m | tr "@" "\n"))
        pn=${parts[1]}
        pkg_version=${parts[2]}
        v="$(pkgs-checker pkg info ${parts[0]}/${pn}-${pkg_version} | grep "version:" | awk '{ print $2 }')"
        vsuff="$(pkgs-checker pkg info ${parts[0]}/${pn}-${pkg_version} | grep "version_suffix:" | awk '{ print $2 }')"
        slot=$(echo $i | awk 'match($0, /[0-9]+[.][0-9]+/) { print substr($0, RSTART, RLENGTH) }')
        ver="${v}.${i}${vsuff}"
        cat="${parts[0]}-${slot}"
        echo "Generating spec for kernel $i, package $cat/$pn-$ver"
        basedir=$DESTINATION/kernel-modules/"$pn"/"${pkg_version}"/"$i"
        mkdir -p $basedir

        if [ "${PORTAGE_ARTIFACTS}" == "true" ]; then
            mottainai-cli task compile "$DESTINATION"/templates/modules.build.yaml.tmpl \
                                        -s LayerCategory="sys-kernel" \
                                        -s LayerVersion=$i \
                                        -s LayerName="linux-sabayon" \
                                        -s PackageCategory="${parts[0]}" \
                                        -s PackageName="$pn" \
                                        -s GentooVersion="${pkg_version}" \
                                        -s PackageVersion="${ver}" \
                                        -s Binhost="true" \
                                        -s Jobs="${JOBS}" \
                                        -o $basedir/build.yaml

        else
            mottainai-cli task compile "$DESTINATION"/templates/modules.build.yaml.tmpl \
                                        -s LayerCategory="sys-kernel" \
                                        -s LayerVersion=$i \
                                        -s LayerName="linux-sabayon" \
                                        -s PackageCategory="${parts[0]}" \
                                        -s PackageName="$pn" \
                                        -s PackageVersion="${ver}" \
                                        -s GentooVersion="${pkg_version}" \
                                        -s Binhost="true" \
                                        -s Jobs="${JOBS}" \
                                        -o $basedir/build.yaml
        fi

        mottainai-cli task compile "$DESTINATION"/templates/definition.yaml.tmpl \
                                    -s PackageCategory="$cat" \
                                    -s PackageVersion="${ver}" \
                                    -s PackageName="$pn" \
                                    -o $basedir/definition.yaml
    done
done
