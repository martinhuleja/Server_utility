# Upload to server utility

Script `upload_to_server.sh` uploads a file or a folder to a server via `ssh`. Simplifies the process and saves time.

## Setup

Download `upload_to_server.sh` and use `chmod +x upload_to_server.sh`.

## How to use it

You can upload a file or whole folder.

- `-h, --help`: Show help message
- `-s, --server <server>`: Server to use
  - *Note: Default server is `merlin.fit.vutbr.cz`. Use `-s eva` for `eva.fit.vutbr.cz`.*
- `-f, --file <file>...`: Upload specific file (or multiple files) from current directory
- `-d, -r, -directory`: Upload current folder
- `-dst, --destination <path>`: Destionation folder on server
  - *Default: `~/Documents/<YYYYMMDD_hhmm>`*

**Set default values in the begginning of the script!**
