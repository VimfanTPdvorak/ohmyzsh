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

- Sudah terinstall shell ZSH.
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
    sh -c "$(curl -fsSL https://panda.apikkoho.com/Iron.Man/ohmyzsh/raw/branch/main/tools/install.sh)"
    ```

## Penambahan default plugin ohmyzsh (14 Juli 2025)

Untuk lebih memudahkan lagi menjalankan beberapa perintah melalui CLI, maka kita
tambahkan lagi beberapa plugin berikut ini sebagai default plugin di `~/.zshrc`
sebagai berikut:

- common-aliases: Detail konfigurasi-nya bisa dilihat di
  `~/.oh-my-zsh/plugins/common-aliases/common-aliases.plugin.zsh`. Salah satu
  alias yang ada pada plugin ini adalah alias sufix untuk memungkinkan membuka
  file terenkripsi dengan GPG dengan gpgOpen dengan cara langsung mengetikkan
  saja fullpath file tersebut. Contohnya, bila ada file `/tmp/file.pdf.asc`, maka
  bisa ketik `/tmp/file.pdf.asc` dan tekan enter. Hasilnya akan sama seperti
  mengetikan: `gpgOpen -f /tmp/file.pdf.asc`.
- kubectl: Auto-complete untuk perintah kubectl
- minikube: Auto-complete untuk perintah minikube
- ansible: Auto-complete untuk perintah ansible

Bagi yang telah menginstall plugins ini, untuk menambahkan plugins tersebut,
edit file `~/.zshrc` dan tambahkan line yang diawalin dengan plugins= menjadi
seperti ini:

```
plugins=(git vi-mode starship pz mw gpgOpen common-aliases kubectl minikube ansible)
```
