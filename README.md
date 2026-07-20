# Upload to server utility

Script `upload_to_server.sh` uploads a file or a folder to a server via `ssh`. Simplifies the process and saves time.

## Setup

Download `upload_to_server.sh` and use `chmod +x upload_to_server.sh`.

## How to use it

You can upload a file or whole folder.

- `-h, --help`: Show help message
- `-s, --server <server>`: Server to use
  - *Note: Default server is `eva.fit.vutbr.cz`. Use `-s merlin` for `merlin.fit.vutbr.cz`.*
- `-f, --file <file>...`: Upload specific file (or multiple files) from current directory
- `-r, --dir, --directory`: Upload current folder
- `--dst, --destination <path>`: Destionation folder on server
  - *Default: `~/Documents/<YYYYMMDD_hhmm>`*
- `--get, --dl, --download`: Switch to download mode

**Set default values in the begginning of the script!**
