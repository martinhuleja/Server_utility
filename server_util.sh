#!/bin/bash

# --- GLOBAL DEFAULT VALUES ---
DEFAULT_SERVER="eva.fit.vutbr.cz"
LOGIN="xhulejm00"

DATE_TIME="$(date +%Y%m%d_%H%M)"
DST_PATH="~/Documents/$DATE_TIME"

SERVER="$DEFAULT_SERVER"
MODE="upload"
SRC_PATHS=()
FILES_TO_UPLOAD=()
DIRS_TO_UPLOAD=()
UPLOAD_DIR=false

# ----- HELP MESSAGE -----
show_help() {
  printf -- "----- UPLOAD TO SERVER UTILITY -----\n"
  printf "> User Guide\n\n"
  printf "Options:\n"
  printf "  -h, --help                   Show this help message\n"
  printf "  -s, --server <server>        Server to use (default: %s)\n" "$DEFAULT_SERVER"
  printf "                               Use '-s merlin' for merlin.fit.vutbr.cz\n"
  printf "  -f, --file <file>...         Upload specific file (or multiple files) from current directory\n"
  printf "  -d, -r, --directory          Upload current directory\n"
  printf "  -dst, --destination <path>   Destination folder on the server\n"
  printf "                               (default: ~/Documents/YYYYMMDD_hhmm)\n\n"
  printf "  -get, -dl, --download        Switch to download mode.\n"
  printf "Examples:\n"
  printf "  %s -f main.c Makefile\n" "$0"
  printf "  %s --directory -s merlin\n" "$0"
  printf "  %s --download -f ~/Documents/main.c -dst .\n\n" "$0"
  printf "Set default values in the begginning of the script!\n"
}

# ----- PARSE ARGUMENTS -----
parse_arguments() {
  if [ $# -eq 0 ]; then
    printf "Error: No parameters provided. Use -h to sohw help message.\n" >&2
    exit 1
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
      show_help
      exit 0
      ;;
    -get | -dl | --download)
      MODE="download"
      DST_PATH="."
      shift
      ;;
    -s | --server)
      if [[ -z "$2" || "$2" == -* ]]; then
        printf "Error: Option %s requires a server name.\n" "$1" >&2
        exit 1
      elif [[ "$2" == "eva" ]]; then
        SERVER="eva.fit.vutbr.cz"
      elif [[ "$2" == "merlin" ]]; then
        SERVER="merlin.fit.vutbr.cz"
      elif [[ -n "$2" && "$2" != -* ]]; then
        SERVER="$2"
      fi
      shift 2
      ;;
    -f | --file)
      opt_name="$1"
      shift
      if [[ -z "$1" || "$1" == -* ]]; then
        printf "Error: Option %s requires a file name.\n" "$opt_name" >&2
        exit 1
      fi
      while [[ -n "$1" && "$1" != -* ]]; do
        FILES_TO_UPLOAD+=("$1")
        shift
      done
      ;;
    -d | -r | --directory)
      UPLOAD_DIR=true
      shift
      while [[ -n "$1" && "$1" != -* ]]; do
        DIRS_TO_UPLOAD+=("$1")
        shift
      done
      ;;
    -dst | --destination)
      if [[ -z "$2" || "$2" == -* ]]; then
        printf "Error: Option %s requires a destination path.\n" "$1" >&2
        exit 1
      fi
      DST_PATH="$2"
      shift 2
      ;;
    *)
      printf "Error: Unknown parameter %s. Use -h to show help message.\n" "$1" >&2
      exit 1
      ;;
    esac
  done
}

# ----- VALIDATE UPLOAD -----
validate_upload() {
  normalize_dst_path

  if [ "$UPLOAD_DIR" = true ]; then
    validate_upload_dirs
  else
    validate_upload_files
  fi
}

normalize_dst_path() {
  if [[ "$SERVER" == "merlin.fit.vutbr.cz" || "$SERVER" == "eva.fit.vutbr.cz" ]]; then
    if [[ "$DST_PATH" == "$HOME"* ]]; then
      DST_PATH=".${DST_PATH#$HOME}"
    fi
  fi
}

validate_upload_dirs() {
  if [ ${#DIRS_TO_UPLOAD[@]} -eq 0 ]; then
    SRC_PATHS=("$(pwd)")
  else
    for dir in "${DIRS_TO_UPLOAD[@]}"; do
      local current_path="$(pwd)/${dir}"
      if [ ! -d "$current_path" ]; then
        printf "Error: Directory '%s does not exist.\n" "$dir" >&2
        exit 1
      fi
      SRC_PATHS+=("$current_path")
    done
  fi
}

validate_upload_files() {
  if [ ${#FILES_TO_UPLOAD[@]} -eq 0 ]; then
    printf "Error: Nothing to upload. Use -h to show help message.\n" >&2
    exit 1
  fi

  for file in "${FILES_TO_UPLOAD[@]}"; do
    local current_path="$(pwd)/${file}"

    if [ ! -e "$current_path" ]; then
      printf "Error: File %s does not exist in current directory.\n" "$file" >&2
      exit 1
    elif [ -d "$current_path" ]; then
      printf "Error: %s is a directory. Use -d to upload directory.\n" "$file" >&2
      exit 1
    fi
    SRC_PATHS+=("$current_path")
  done
}

# ----- VALIDATE DOWNLOAD -----
validate_download() {
  local all_remote_items=("${FILES_TO_UPLOAD[@]}" "${DIRS_TO_UPLOAD[@]}")
  ensure_items_to_download

  for item in "${all_remote_items[@]}"; do
    check_local_overwrite "$item"
    normalize_src_path "$item"
  done
}

ensure_items_to_download() {
  local all_remote_items=("${FILES_TO_UPLOAD[@]}" "${DIRS_TO_UPLOAD[@]}")
  if [ ${#all_remote_items[@]} -eq 0 ]; then
    printf "Error: Nothing to download. Specify remote files or directories using -f or -d.\n" >&2
    exit 1
  fi
}

check_local_overwrite() {
  local target_name="$(basename "$1")"
  local dst_item="${DST_PATH}/${target_name}"

  if [ -e "$dst_item" ]; then
    # Confirmation to overwrite if 'target_name' already exists in '$DST_PATH'
    read -p "Warning: '$target_name' already exists in '$DST_PATH'. Overwrite? [y/N]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
      printf "Download aborted.\n" >&2
      exit 1
    fi
  fi
}

normalize_src_path() {
  local item="$1"

  if [[ "$SERVER" == *"fit.vutbr.cz" ]] && [[ "$item" == "$HOME"* ]]; then
    # In case local bash use '~' into -f path
    SRC_PATHS+=(".${item#$HOME}")
  else
    SRC_PATHS+=("$item")
  fi
}

# ----- EXECUTE UPLOAD -----
create_remote_dir() {
  local target="$LOGIN@$SERVER"
  printf "Connecting to %s as %s and creating directory...\n" "$SERVER" "$LOGIN"

  ssh "$target" "mkdir -p $DST_PATH"
  if [ $? -ne 0 ]; then
    printf "Error: Failed to create directory on the remote server.\n" >&2
    exit 1
  fi

  printf "Directory %s created.\n" "${DST_PATH#.}"
}

upload_data() {
  local target="$LOGIN@$SERVER"
  printf "Transfering data to server...\n\n"

  scp -r "${SRC_PATHS[@]}" "${target}:${DST_PATH}/"
  if [ $? -ne 0 ]; then
    printf "Error: Data transefer failed.\n" >&2
    exit 1
  fi

  printf "\nSuccessfully uploaded to: %s@%s: %s\n" "$LOGIN" "$SERVER" "${DST_PATH#.}"
}

# ----- EXECUTE DOWNLOAD -----
create_local_dir() {
  printf "Creating local directory '%s'...\n" "$DST_PATH"

  mkdir -p "$DST_PATH"
  if [ ! -d "$DST_PATH" ]; then
    printf "Error: Failed to create local directory '%s'.\n" "$DST_PATH" >&2
    exit 1
  fi

  printf "Local directory created.\n" "$DST_PATH"
}

download_data() {
  local target="$LOGIN@$SERVER"
  local scp_sources=()

  for src in "${SRC_PATHS[@]}"; do
    scp_sources+=("${target}:${src}")
  done

  printf "Connecting to %s as %s and transfering data from server...\n\n" "$SERVER" "$LOGIN"

  scp -r "${scp_sources[@]}" "${DST_PATH}/"
  if [ $? -ne 0 ]; then
    printf "Error: Data transfer failed.\n" >&2
    exit 1
  fi

  printf "\nSuccessfully downloaded to: %s\n" "$DST_PATH"
}

# ----- MAIN -----
main() {
  parse_arguments "$@"

  if [ "$MODE" == "upload" ]; then
    # --- Upload mode ---
    validate_upload
    create_remote_dir
    upload_data

  else
    # --- Download mode ---
    validate_download
    create_local_dir
    download_data
  fi
}

main "$@"
