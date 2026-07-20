# Upload to Server Utility

A Bash script designed to upload files and directories to a remote server.
It automatically handles the creation of destination directories on the remote server via `ssh` and securely transfers the selected data using `scp`.

While it features FIT BUT servers (`eva` and `merlin`), it is fully compatible with any standard SSH server.

## Setup

1. **Configure your credentials:**
   Open the `src/server_util.sh` script in your text editor and set your default values at the top of the file.
   **You must set the `LOGIN` variable** for the script to work properly:
   
   ```bash
   # --- GLOBAL DEFAULT VALUES ---
   DEFAULT_SERVER="eva.fit.vutbr.cz"
   LOGIN="username" # e.g. xlogin00
   ```

2. **Install the script:** 
   Move the script to your local binaries directory and make it executable.

   ```bash
   mkdir -p ~/.local/bin
   mv src/server_util.sh ~/.local/bin/server_util
   chmod +x ~/.local/bin/server_util
   ```

## Usage

Since the script is installed in your `~/.local/bin`, you can execute it directly from any directory:

```bash
server_util <OPTION>...
```

### Options

| Flag                           | Description                                                                                         |
| ---                            | ---                                                                                                 |
| `-h`, `--help`                 | Show the help message.                                                                              |
| `-f`, `--file <file>...`       | Upload specific file(s) from the current directory.                                                 |
| `-d`, `-r`, `--directory`      | Upload the entire current directory.                                                                |
| `-s`, `--server <server>`      | Specify the target server (default: `eva.fit.vutbr.cz`). Use `-s merlin` for `merlin.fit.vutbr.cz`. |
| `-dst`, `--destination <path>` | Specify the destination folder on the server (default: `~/Documents/YYYYMMDD_HHMM`).                |

### Examples

Upload specific files to default directory on default server.

```bash
server_util -f main.c Makefile
```

Upload the entire current directory to `merlin.fit.vutbr.cz`.

```bash
server_util --directory -s merlin
```

Upload specific files to a custom server and a specific destination path.

```bash
server_util -s custom.server.com -dst /var/www/html/ -f index.html styles.css
```