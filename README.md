<p align="center"><img src="https://ohmyzsh.s3.amazonaws.com/omz-ansi-github.png" alt="Oh My Zsh"></p>

# Tentang Repository ini

Repository ini adalah fork dari ohmyzsh github dan kita modifikasi untuk
kebutuhan workflow internal.

Modifikasi yang dilakukan adalah dengan menambahkan plugin `mw`, `pz`,
`starship`, dan `gpgOpen` sebagai default plugins OMZ:

- mw: MWiki CLI
- pz: Password store CLI extension
- gpgOpen: CLI untuk secara aman membuka GPG encrypted file
- starship: The minimal, blazing-fast, and infinitely customizable prompt for any shell!

Sehingga default plugin OMZ yang terkonfigurasi adalah `git`, `starship`, `mw`,
`pz`, dan `gpgOpen`.

## Pre-requisites

- Sudah terinstall shell ZSH dan starship.
- Bisa lakukan ini dahulu ataupun setelah melakukan instalasi OMZ ini:
    - Clone MWiki
    - Install Password Store

## Instalasi

1. Bila sudah pernah melakukan instalasi OMZ Official sebelum-nya, maka jalankan
   dua perintah berikut ini:
    ```bash
    unset ZSH
    rm -rf ~/.oh-my-zsh
    ```
2. Jalankan perintah ini untuk install OMZ:
    ```bash
    sh -c "$(curl -fsSL https://panda.apikkoho.com/Iron.Man/ohmyzsh/raw/branch/office/tools/install.sh)"
    ```
