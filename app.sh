#!/bin/bash

### Termux SDK Installer

# Variables
install_dir="${HOME}"
manifest_url="https://raw.githubusercontent.com/AndroidIDEOfficial/androidide-tools/main/manifest.json"
manifest="${PWD}/manifest.json"
CURRENT_SHELL="${SHELL##*/}"
CURRENT_DIR="${PWD}"
arch="$(dpkg --print-architecture)"
sdk_installed=false
jdk_installed=false

# Color Codes
red="\e[0;31m"          # Red
green="\e[0;32m"        # Green
cyan="\e[0;36m"         # Cyan
white="\e[0;37m"        # White
nocol="\033[0m"         # Default

# Functions
banner() {
  echo -e "${green}------------------------------------------------"
  echo -e "Android SDK Installer Termux"
  echo -e "https://github.com/Gopartner/android-sdk-installer-termux"
  echo -e "------------------------------------------------${nocol}"
}

check_sdk_installed() {
  if command -v sdkmanager &> /dev/null; then
    sdk_installed=true
  fi
}

check_jdk_installed() {
  if command -v java &> /dev/null; then
    jdk_installed=true
  fi
}

download_and_extract() {
  name="${1}"
  url="${2}"
  dir="${3}"
  dest="${4}"

  cd "${dir}"
  do_download=true

  if [[ -f "${dest}" ]]; then
    name=$(basename "${dest}")
    echo -e "${green}File ${name} already exists.${nocol}"
    read -p "Do you want to skip the download process? (yes/no): " skip
    if [[ "${skip}" = "y" || "${skip}" = "yes" || "${skip}" = "Y" || "${skip}" = "Yes" ]]; then
      do_download=false
    fi
    echo ""
  fi

  if [[ "${do_download}" = "true" ]]; then
    echo -e "${green}Downloading ${name}...${nocol}"
    curl -L -o "${dest}" "${url}"
    echo -e "${green}${name} has been downloaded.${nocol}"
    echo ""
  fi

  if [[ ! -f "${dest}" ]]; then
    echo -e "${red}The downloaded file ${name} does not exist! Aborting...${nocol}"
    exit 1
  fi

  echo -e "${green}Extracting downloaded archive...${nocol}"
  tar xvJf "${dest}"
  echo -e "${green}Extracted successfully${nocol}"
  echo ""

  rm -vf "${dest}"
  cd "${CURRENT_DIR}"
}

gen_data() {
  if ! command -v curl &> /dev/null; then
    echo -e "${red}curl is not installed!${nocol}"
    echo "Install it with pkg install curl"
    echo ""
    exit 1
  fi

  curl --silent -L -o "${manifest}" "${manifest_url}"

  if ! [[ -s "${manifest}" ]]; then
    echo -e "${red}Problem fetching manifest!${nocol}"
    echo "Try again after some seconds"
    echo ""
    if [[ -f "${manifest}" ]]; then
      rm "${manifest}"
    fi
    exit 1
  fi

  sdk_url=$(jq -r .android_sdk "${manifest}")
  sdk_file=${sdk_url##*/}
  sdk_m_version=$(jq -r '.build_tools.'"${arch}" "${manifest}" | jq -r 'keys_unsorted[]')
  sdk_m_version=${sdk_m_version[0]}
  sdk_version=${sdk_m_version:1}
  sdk_version="${sdk_version//_/.}"
  build_tools_url=$(jq -r '.build_tools.'"${arch}" "${manifest}"."${sdk_m_version}" "${manifest}")
  build_tools_file=${build_tools_url##*/}
  cmdline_tools_url=$(jq -r .cmdline_tools "${manifest}")
  cmdline_tools_file=${cmdline_tools_url##*/}
  platform_tools_url=$(jq -r '.platform_tools.'"${arch}"."${sdk_m_version}" "${manifest}")
  platform_tools_file=${platform_tools_url##*/}
  rm "${manifest}"
}

info() {
  gen_data
  echo -e "${green}Active Shell:${nocol} ${CURRENT_SHELL}"
  echo -e "${green}Arch:${nocol} ${arch}"
  echo -e "${green}JDK:${nocol} OpenJDK 17"
  echo -e "${green}SDK/Tools verrsi:${nocol} v${sdk_version}"
  echo -e "${green}SDK url:${nocol} ${sdk_url}"
  echo -e "${green}Build tools url:${nocol} ${build_tools_url}"
  echo -e "${green}Commandline tools url:${nocol} ${cmdline_tools_url}"
  echo -e "${green}Platform tools url:${nocol} ${platform_tools_url}"
  echo -e "${green}SDK dari:${nocol} https://github.com/AndroidIDEOfficial/androidide-tools"
}

install() {
  check_sdk_installed
  check_jdk_installed

  if [[ "${sdk_installed}" = true || "${jdk_installed}" = true ]]; then
    echo -e "${green}Android SDK atau JDK sudah terinstal.${nocol}"
    echo -e "${green}Silakan restart termux.!${nocol}${red}!${nocol}"
    echo ""
    exit 0
  fi

  echo ""
  gen_data
  echo -e "${green}Installing dependencies...${nocol}"
  pkg update
  pkg install curl wget termux-tools jq tar -y
  echo -e "${red}!${nocol}${green}This will download ~400MB size files and will take ~600MB space on disk.${nocol}"
  echo -e "Continue? ([${green}y${nocol}]es/[${red}N${nocol}]o): "
  read proceed
  if ! ([[ "${proceed}" = "y" || "${proceed}" = "yes" || "${proceed}" = "Y" || "${proceed}" = "Yes" ]]); then
    echo -e "${red}Aborted!${nocol}"
    exit 1
  fi
  echo -e "${green}Installing jdk...${nocol}"
  pkg install openjdk-17 -y
  echo -e "${green}Downloading sdk files...${nocol}"
  # Download and extract the android SDK
  download_and_extract "Android SDK" "${sdk_url}" "${install_dir}" "${install_dir}/${sdk_file}"
  # Download and extract build tools
  download_and_extract "Build tools" "${build_tools_url}" "${install_dir}/android-sdk" "${install_dir}/${build_tools_file}"
  # Download and extract cmdline tools
  download_and_extract "Command line tools" "${cmdline_tools_url}" "${install_dir}/android-sdk" "${install_dir}/${cmdline_tools_file}"
  # Download and extract platform tools
  download_and_extract "Platform tools" "${platform_tools_url}" "${install_dir}/android-sdk" "${install_dir}/${platform_tools_file}"
  # Setting env vars
  echo -e "${green}Setting up env vars...${nocol}"
  if [[ "${CURRENT_SHELL}" == "bash" ]]; then
    shell_profile="${HOME}/.bashrc"
  elif [[ "${CURRENT_SHELL}" == "zsh" ]]; then
    shell_profile="${HOME}/.zshrc"
  else
    unsupported_shell_used=true
    echo -e "${red}Unsupported shell!${nocol}"
    echo -e "${green}You will need to manually export env vars JAVA_HOME, ANDROID_SDK_ROOT and ANDROID_HOME on every session to use sdk, or add them to your shell profile manually:${nocol}"
    echo 'export JAVA_HOME=${PREFIX}/opt/openjdk-17'
    echo 'export ANDROID_SDK_ROOT=${HOME}/android-sdk'
    echo 'export ANDROID_HOME=${HOME}/android-sdk'
    echo -e "${green}Also do the same for sdk and jdk bin locations:${nocol}"
    echo 'export PATH=${PREFIX}/opt/openjdk/bin:${HOME}/android-sdk/cmdline-tools/latest/bin:${PATH}'
  fi
  if [[ -z "${unsupported_shell_used}" ]]; then
    if [[ -z "${JAVA_HOME}" ]]; then
      echo -e '\nexport JAVA_HOME=${PREFIX}/opt/openjdk\n' >> "${shell_profile}"
      echo -e '\nexport PATH=${PREFIX}/opt/openjdk/bin:${PATH}\n' >> "${shell_profile}"
    else
      echo "JAVA_HOME is already set to: ${JAVA_HOME}"
      echo "Check if the path is correct, it should be: ${PREFIX}/opt/openjdk"
    fi
    if [[ -z "${ANDROID_SDK_ROOT}" ]]; then
      echo -e '\nexport ANDROID_SDK_ROOT=${HOME}/android-sdk\n' >> "${shell_profile}"
    else
      echo "ANDROID_SDK_ROOT is already set to: ${ANDROID_SDK_ROOT}"
      echo "Check if the path is correct, it should be: ${install_dir}/android-sdk"
    fi
    if [[ -z "${ANDROID_HOME}" ]]; then
      echo -e '\nexport ANDROID_HOME=${HOME}/android-sdk\n' >> "${shell_profile}"
    else
      echo "ANDROID_HOME is already set to: ${ANDROID_HOME}"
      echo "Check if the path is correct, it should be: ${install_dir}/android-sdk"
    fi
    echo -e '\nexport PATH=${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${PATH}\n' >> "${shell_profile}"
  fi
  apt clean
}

# Main program
while true; do
  banner
  echo -e "Note: This will NOT install ndk.\n"
  echo "Pilihan menu:"
  echo "1. Bantuan       Shows brief help"
  echo "2. Info          Show info about sdk, arch, etc"
  echo "3. Install       Start installation, installs jdk and android sdk with cmdline and build tools"
  read -p "Pilih menu: " choice
  case ${choice} in
    1) help ;;
    2) info ;;
    3) install ;;
    *) echo -e "${red}Pilihan tidak valid! Silakan pilih opsi yang benar.${nocol}" ;;
  esac
done

