#!/bin/bash

# --- GLOBAL DEFAULT VALUES ---
DEFAULT_SERVER="merlin.fit.vutbr.cz"
LOGIN="xhulejm00"

DATE_TIME="$(date +%Y%m%d_%H%M)"
DST_PATH="~/Documents/$DATE_TIME"

SERVER="$DEFAULT_SERVER"
SRC_PATHS=()
FILES_TO_UPLOAD=()
UPLOAD_DIR=false

show_help() {
  printf -- "----- UPLOAD TO SERVER UTILITY -----\n"
  printf "> User Guide\n\n"
  printf "Options:\n"
  printf "  -h, --help                   Show this help message\n"
  printf "  -s, --server <server>        Server to use (default: %s)\n" "$DEFAULT_SERVER"
  printf "                               Use '-s eva' for eva.fit.vutbr.cz\n"
  printf "  -f, --file <file>...         Upload specific file (or multiple files) from current directory\n"
  printf "  -d, -r, --directory          Upload current directory\n"
  printf "  -dst, --destination <path>   Destination folder on the server\n"
  printf "                               (default: ~/Documents/YYYYMMDD_hhmm)\n\n"
  printf "Examples:\n"
  printf "  %s -f main.c Makefile\n" "$0"
  printf "  %s --directory -s eva\n\n" "$0"
  printf "Set default values in the begginning of the script!\n"
}

parse_arguments() {
  if [ $# -eq 0 ]; then
    printf "Error: No parameters provided.\n" >&2
    show_help
    exit 1
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
      show_help
      exit 0
      ;;
    -s | --server)
      if [[ "$2" == "eva" ]]; then
        SERVER="eva.fit.vutbr.cz"
      elif [[ -n "$2" && "$2" != -* ]]; then
        SERVER="$2"
      fi
      shift 2
      ;;
    -f | --file)
      shift
      if [[ -z "$1" || "$1" == -* ]]; then
        printf "Error: Option -f, --file requires a file name.\n" >&2
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
      ;;
    -dst | --destination)
      if [[ -n "$2" && "$2" != -* ]]; then
        DST_PATH="$2"
      fi
      shift 2
      ;;
    *)
      printf "Error: Unknown parameter %s. Use -h to show help message.\n" "$1" >&2
      exit 1
      ;;
    esac
  done
}

validate_input() {
  if [[ "$SERVER" == "merlin.fit.vutbr.cz" || "$SERVER" == "eva.fit.vutbr.cz" ]]; then
    if [[ "$DST_PATH" == "$HOME"* ]]; then
      DST_PATH=".${DST_PATH#$HOME}"
    fi
  fi

  # Directory upload
  if [ "$UPLOAD_DIR" = true ]; then
    SRC_PATHS=($(pwd))
  # Files upload
  else
    if [ ${#FILES_TO_UPLOAD[@]} -eq 0 ]; then
      printf "Error: Nothing to upload.\n" >&2
      show_help
      exit 1
    fi

    for file in "${FILES_TO_UPLOAD[@]}"; do
      local current_path="$(pwd)/${file}"

      if [ ! -e "$current_path" ]; then
        printf "Error: File %s does not exist in current directory.\n" "$file" >&2
        exit 1
      elif [ -d "$current_path" ]; then
        printf "Error: %s is a directory. Use -d to upload directory.\n" "$file" >&2
      fi

      SRC_PATHS+=("$current_path")
    done
  fi
}

execute_upload() {
  local target="$LOGIN@$SERVER"

  printf "Connecting to %s as %s and creating directory.\n" "$SERVER" "$LOGIN"

  # Create folder
  ssh "$target" "mkdir -p $DST_PATH"
  if [ $? -ne 0 ]; then
    printf "Error: Failed to create directory on the remote server.\n" >&2
    exit 1
  fi

  printf "Directory %s created.\n" "${DST_PATH#.}"
  printf "Transfering data.\n\n"

  # Transfer data
  scp -r "${SRC_PATHS[@]}" "${target}:${DST_PATH}/"
  if [ $? -ne 0 ]; then
    printf "Error: Data transefer failed.\n" >&2
    exit 1
  fi

  printf "\nSuccessfully uploaded to: %s@%s: %s\n" "$LOGIN" "$SERVER" "${DST_PATH#.}"
}

main() {
  parse_arguments "$@"
  validate_input
  execute_upload
}

main "$@"
