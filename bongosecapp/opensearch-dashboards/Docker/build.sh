#!/bin/bash

set -ex

# Script parameters
bongosec_branch=$1
checksum=$2
app_revision=$3

# Paths
plugin_platform_dir="/tmp/source"
source_dir="${plugin_platform_dir}/plugins"
packages_list=( "main_bongosec" "bongosec-check-updates_bongosecCheckUpdates" "bongosec-core_bongosecCore" )
destination_dir="/bongosec_app"
checksum_dir="/var/local/checksum"
git_clone_tmp_dir="/tmp/bongosec-app"

# Repositories URLs
bongosec_app_clone_repo_url="https://github.com/bongosec/bongosec-dashboard-plugins.git"
bongosec_app_raw_repo_url="https://raw.githubusercontent.com/bongosec/bongosec-dashboard-plugins"
plugin_platform_app_repo_url="https://github.com/opensearch-project/OpenSearch-Dashboards.git"
plugin_platform_app_raw_repo_url="https://raw.githubusercontent.com/opensearch-project/OpenSearch-Dashboards"
bongosec_app_package_json_url="${bongosec_app_raw_repo_url}/${bongosec_branch}/plugins/main/package.json"
bongosec_app_nvmrc_url="${bongosec_app_raw_repo_url}/${bongosec_branch}/.nvmrc"

# Script vars
bongosec_version=""
plugin_platform_version=""
plugin_platform_yarn_version=""
plugin_platform_node_version=""


change_node_version () {
    installed_node_version="$(node -v)"
    node_version=$1

    n ${node_version}

    if [[ "${installed_node_version}" != "v${node_version}" ]]; then
        mv /usr/local/bin/node /usr/bin
        mv /usr/local/bin/npm /usr/bin
        mv /usr/local/bin/npx /usr/bin
    fi

    echo "Using $(node -v) node version"
}


prepare_env() {
    echo "Downloading package.json and .nvmrc from bongosec-dashboard-plugins repository"
    if ! curl $bongosec_app_package_json_url -o "/tmp/package.json" ; then
        echo "Error downloading package.json from GitHub."
        exit 1
    fi

    if ! curl $bongosec_app_nvmrc_url -o "/tmp/.nvmrc" ; then
        echo "Error downloading .nvmrc from GitHub."
        exit 1
    fi
    bongosec_version=$(python -c 'import json, os; f=open("/tmp/package.json"); pkg=json.load(f); f.close();\
                    print(pkg["version"])')
    plugin_platform_version=$(python -c 'import json, os; f=open("/tmp/package.json"); pkg=json.load(f); f.close();\
                    plugin_platform_version=pkg.get("pluginPlatform", {}).get("version");\
                    print(plugin_platform_version)')

    plugin_platform_package_json_url="${plugin_platform_app_raw_repo_url}/${plugin_platform_version}/package.json"

    echo "Downloading package.json from opensearch-project/OpenSearch-Dashboards repository"
    if ! curl $plugin_platform_package_json_url -o "/tmp/package.json" ; then
        echo "Error downloading package.json from GitHub."
        exit 1
    fi

    plugin_platform_node_version=$(cat /tmp/.nvmrc)

    plugin_platform_yarn_version=$(python -c 'import json, os; f=open("/tmp/package.json"); pkg=json.load(f); f.close();\
                          print(str(pkg["engines"]["yarn"]).replace("^",""))')
}


download_plugin_platform_sources() {
    if ! git clone $plugin_platform_app_repo_url --branch "${plugin_platform_version}" --depth=1 plugin_platform_source; then
        echo "Error downloading OpenSearch-Dashboards source code from opensearch-project/OpenSearch-Dashboards GitHub repository."
        exit 1
    fi

    mkdir -p plugin_platform_source/plugins
    mv plugin_platform_source ${plugin_platform_dir}
}


install_dependencies () {
    cd ${plugin_platform_dir}
    change_node_version $plugin_platform_node_version
    npm install -g "yarn@${plugin_platform_yarn_version}"

    sed -i 's/node scripts\/build_ts_refs/node scripts\/build_ts_refs --allow-root/' ${plugin_platform_dir}/package.json
    sed -i 's/node scripts\/register_git_hook/node scripts\/register_git_hook --allow-root/' ${plugin_platform_dir}/package.json

    yarn osd bootstrap --skip-opensearch-dashboards-plugins
}


download_bongosec_app_sources() {
    if ! git clone $bongosec_app_clone_repo_url --branch ${bongosec_branch} --depth=1 ${git_clone_tmp_dir}; then
        echo "Error downloading the source code from bongosec-dashboard-app GitHub repository."
        exit 1
    fi

    for item in ${packages_list[@]}; do
        array=(${item//_/ })
        cp -r "${git_clone_tmp_dir}/plugins/${array[0]}" "${source_dir}/${array[0]}"
    done
}

check_revisions() {
    dirs=()
    for item in ${packages_list[@]}; do
        dirs+=(${item//_/ })
    done

    main_revision=$(jq -r '.revision' ${source_dir}/${dirs[0]}/package.json)
    check_update_revision=$(jq -r '.revision' ${source_dir}/${dirs[2]}/package.json)
    core_revision=$(jq -r '.revision' ${source_dir}/${dirs[4]}/package.json)

    if [ "${main_revision}" != "${check_update_revision}" ] || [ "${check_update_revision}" != "${core_revision}" ]; then
        echo "The package.json revisions do not match. All revisions must be equal."
        exit 1
    else
        echo "The package.json revision match."
    fi
}

build_package(){

    for item in ${packages_list[@]}; do

        array=(${item//_/ })

        if [ -z "${app_revision}" ]; then
            bongosec_app_pkg_name="${array[1]}-${bongosec_version}.zip"
        else
            bongosec_app_pkg_name="${array[1]}-${bongosec_version}-${app_revision}.zip"
        fi

        cd "${source_dir}/${array[0]}"
        yarn
        OPENSEARCH_DASHBOARDS_VERSION=${plugin_platform_version} yarn build --allow-root

        find "${source_dir}/${array[0]}" -name "*.zip" -exec mv {} ${destination_dir}/${bongosec_app_pkg_name} \;

        if [ "${checksum}" = "yes" ]; then
            cd ${destination_dir} && sha512sum "${bongosec_app_pkg_name}" > "${checksum_dir}/${bongosec_app_pkg_name}".sha512
        fi

    done

    exit 0
}


prepare_env
download_plugin_platform_sources
install_dependencies
download_bongosec_app_sources
check_revisions
build_package
