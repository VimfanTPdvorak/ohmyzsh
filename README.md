<p align="center"><img src="https://ohmyzsh.s3.amazonaws.com/omz-ansi-github.png" alt="Oh My Zsh"></p>

# Tentang Repository ini

Repository ini adalah fork dari ohmyzsh github dan kita modifikasi untuk
kebutuhan workflow internal.

Untuk awal sekali modifikasi yang dilakukan adalah dengan menambahkan beberapa
plugin berikut ini dan menambahkan ketiga plugins berikut ini sebagai default
plugins OMZ:

- mw: MWiki CLI
- pz: Password store CLI extension
- starship: The minimal, blazing-fast, and infinitely customizable prompt for any shell!

## Pre-requisites

- Sudah terinstall shell ZSH dan starship.
- Bisa lakukan ini dahulu ataupun setelah melakukan instalasi OMZ ini:
    - Clone MWiki
    - Install Password Store

## Instalasi

```bash
unset ZSH
rm -rf ~/.oh-my-zsh
git clone --depth 1 https://panda.apikkoho.com/Iron.Man/ohmyzsh.git /tmp/ohmyzsh
sh /tmp/ohmyzsh/tools/install.sh
```
