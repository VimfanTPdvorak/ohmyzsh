# A paranoidly safe way to open a gpg file.

# If run from a script, do not set the completion function
if (( ${+functions[compdef]} )); then
    compdef _gpgOpen gpgOpen
fi

# Print usage
function print_usage() {
    print -l $usage
}

function gpgOpen {
    zparseopts -D -E -F -- \
        {h,-help}=flag_help \
        {f,-file}:=flag_file \
        {e,-editor}:=flag_editor

    _gpgOpen::main
}

function _gpgOpen::main {
    local usage=(
        "Usage:"
        "gpgOpen [-h|--help]"
        "gpgOpen {-f|--file <GPG_Encrypted_File>}"
        "gpgOpen [-e|--editor <vim|nano>]\n"
        "-h --help                      Display this usage info"
        "-f --file <GPG_Encrypted_File> Specify GPG encrypted file tobe opened"
        "-e --editor <vim|nano>         Force gpgOpen to open the file with vim or nano.\n"
        "Example:"
        "1. Open an encrypted file with default editor: gpgOpen -f listOfServer.xlsx.asc"
        "2. Open an encrypted file with vim           : gpgOpen -f secret.txt.asc -e vim"
    )

    if (( $#flag_help ));then
        print_usage
    elif (( $#flag_file ));then
        gpgFile=$flag_file[-1]
        osName=$(uname)

        if (( $#flag_editor ));then
            theEditor=$flag_editor[-1]
        fi

        # Get only the file name from a path and remove the extension
        gpgFN=${$(basename $gpgFile)%.*}

        if [[ -f "$gpgFile" ]];then
            td=$(mktemp -d)
            gpg -do $td/$gpgFN $gpgFile

            if [[ ! -z "$theEditor" ]] && [[ -z $(which $theEditor|grep "not found") ]];then
                cmd="$theEditor"
            else
                [[ "$osName" == "Darwin" ]] && cmd="open" || cmd="xdg-open"
            fi

            eval $cmd \"$td/$gpgFN\"

            vared -p "Press ENTER once you have finished working with the file." -c t

            vared -p "Do you want to re-encrypt the file (y/n)? " -c yn
            if [[ "$yn" = "y" || "$yn" = "Y" ]];then
                IDs=""
                for ID in $(gpg -d "${gpgFile}" > /dev/null 2>&1|\
                            sed -n 's/\(.*ID\ \)\(.*\),.*/\2/p');do
                    IDs="$IDs -r $ID"
                done
                rm "${gpgFile}"
                cmdE="gpg -eao '$gpgFile' $IDs '$td/$gpgFN'"
                eval $cmdE
            fi

            vared -p "Press enter to shred the decrypted file." -c t

            [[ "$osName" == "Darwin" ]] && cmd="gshred" || cmd="shred"
            eval $cmd \"$td/$gpgFN\" --remove=wipesync

            rmdir $td

            unset t
            unset yn
        else
            echo "Please pass a GPG encrypted file that you can decrypt."
        fi

        unset theEditor
        unset osName
        unset gpgFile
    fi
}
