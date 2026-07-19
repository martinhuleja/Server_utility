#!/bin/bash

show_help() {
  printf -- "----- UPLOAD TO SERVER UTILITY -----\n"
  printf "> User Guide\n\n"
  printf "Options:\n"
  printf "  -h, --help                   Show this help message\n"
  printf "  -s, --server <server>        Server to use (default: merlin.fit.vutbr.cz)\n"
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

main() {
  show_help
}

main "$@"
