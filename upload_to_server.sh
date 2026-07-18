#!/bin/bash

# --- GLOBAL DEFAULT VALUES ---
DEFAULT_SERVER="merlin.fit.vutbr.cz"
LOGIN="xhulejm00"

DATE_TIME="$(date +%Y%m%d_%H%M)"
DST_PATH="~/Documents/$DATE_TIME"

SERVER="$DEFAULT_SERVER"
SRC_PATH=""
FILE_TO_UPLOAD=""
UPLOAD_DIR=false

show_help() {
  printf -- "----- UPLOAD TO SERVER UTILITY -----\n"
  printf "> User Guide\n\n"
  printf "Options:\n"
  printf "  -h, --help                   Show this help message\n"
  printf "  -s, --server <server>        Server to use (default: %s)\n" "$DEFAULT_SERVER"
  printf "                               Use '-s eva' for eva.fit.vutbr.cz\n"
  printf "  -f, --file <file>            Upload specific file from current directory\n"
  printf "  -d, -r, --directory          Upload current directory\n"
  printf "  -dst, --destination <path>   Destination folder on the server\n"
  printf "                               (default: ~/Documents/YYYYMMDD_hhmm)\n\n"
  printf "Examples:\n"
  printf "  %s -f main.c\n" "$0"
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
      if [[ -z "$2" || "$2" == -* ]]; then
        printf "Error: Option -f, --file requires a file name.\n" >&2
        exit 1
      fi

      FILE_TO_UPLOAD="$2"
      shift 2
      ;;
    -d | -r | --directory)
      UPLOAD_DIR=true
      shift
      ;;
    -dst | --destination)
      if [[ -z "$2" || "$2" == -* ]]; then
        printf "Error: Option -dst, --destination requires a destination path.\n" >&2
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

validate_input() {
  # Directory upload
  if [ "$UPLOAD_DIR" = true ]; then
    SRC_PATH=$(pwd)
  # File upload
  else
    if [ -z "$FILE_TO_UPLOAD" ]; then
      printf "Error: Nothing to upload." >&2
      show_help
      exit 1
    fi

    SRC_PATH="$(pwd)/${FILE_TO_UPLOAD}"

    if [ ! -e "$SRC_PATH" ]; then
      printf "Error: File %s does not exist in current directory" "$FILE_TO_UPLOAD" >&2
      exit 1
    elif [ -d "$SRC_PATH" ]; then
      printf "Error: %s is a directory. Use -d to upload directory." "$FILE_TO_UPLOAD" >&2
    fi
  fi
}

main() {
  parse_arguments "$@"
  validate_input
}

main "$@"
