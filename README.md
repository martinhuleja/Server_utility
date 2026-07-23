# Server Utility

A Bash script designed to upload and download files and directories to and from a remote server.
It automatically handles the creation of destination directories on the remote server via `ssh` and securely transfers the selected data using `scp`.

While it features convenient shortcuts for FIT BUT servers (`eva` and `merlin`), it is fully compatible with any standard SSH server.

## Prerequisites

To run this script, your system must have standard OpenSSH tools installed:
- `ssh` (for remote directory creation and command execution)
- `scp` (for secure file transfer)

## Compatibility

- **Linux & macOS:** Fully supported out of the box.
- **Windows:** Supported via Git Bash (included with [Git for Windows](https://gitforwindows.org/)) or **WSL** (Windows Subsystem for Linux).

**The script was tested just on Linux.**

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
   Copy the script to your local binaries directory and make it executable.

   ```bash
   mkdir -p ~/.local/bin
   cp src/server_util.sh ~/.local/bin/server_util
   chmod +x ~/.local/bin/server_util
   ```

### SSH Keys Setup (Recommended)

Since the script executes two separate connections per run (`ssh` for directory creation, `scp` for transfer), setting up an SSH key prevents you from typing your password twice.

1. **Generate the key pair on your local machine:**
   ```bash
   ssh-keygen -t ed25519
   ```

2. **Upload the public key using this utility!**
   ```bash
   script_util -f ~/.ssh/id_ed25519.pub --dst ~/.ssh
   ```

3. **Authorize the key on the server:**
   Append the uploaded key to your authorized keys and secure the file permissions:
   ```bash
   ssh your_username@eva.fit.vutbr.cz "cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
   ```

   *Alternatively, you can skip steps 2 and 3 by using the standard `ssh-copy-id username@server.com` command.*

## Usage

Since the script is installed in your `~/.local/bin`, you can execute it directly from any directory:

```bash
server_util <OPTION>...
```

### Options

| Flag                                | Description                                                                                                         |
| -----                               | -----                                                                                                               |
| `-h`, `--help`                      | Show the help message.                                                                                              |
| `--put`, `--up`, `--upload`         | Switch to upload mode (default).                                                                                    |
| `--get`, `--dl`, `--download`       | Switch to download mode.                                                                                            |
| `-f`, `--file <file>...`            | Target specific file(s) fot the transfer.                                                                           |
| `-r`, `--dir`, `--directory` [dir]...  | Target the entire current directory/directories. (default: Current directory).                                   |
| `-s`, `--server <server>`           | Specify the target server (default: `eva.fit.vutbr.cz`). Use `-s eva` (default) or `-s merlin` for FIT BUT servers. |
| `--dst`, `--destination <path>`     | Specify the destination folder (default upload: `~/Documents/YYYYMMDD_HHMM`, default download: Current folder).     |

### Examples

Upload specific files to default directory on default server.

```bash
server_util -f main.c Makefile
```

Upload the entire current directory to `merlin.fit.vutbr.cz` to specific destination path.

```bash
server_util -r -s merlin --dst ~/Documents/dir
```

Download specific files from a custom server and to a current local directory.

```bash
server_util --download -s custom.server.com -f index.html styles.css
```

## License

This project is distributed under MIT License. See the [LICENSE](LICENSE) file for details.
