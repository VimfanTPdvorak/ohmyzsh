# Purpose:
# Shorten some of the frequently used pass commands.
#
# Important:
# Please read the comment sections at the top of the ~/tools/pz/_pz file.

ohtrailViewer() {
    local ym="$(date +%Y/%m)"
    local yn

    vared -p "Enter an oh-trail short hostname [water, singa, potato, acorn, etc] " -c shost
    vared -p "Enter data period [yyyy/mm] : " -c ym

    echo "Retrieving asciicast and log from /asciicast/clients/$shost/$(date +%Y/%m)"

    theFiles=$(ssh water "ls -1t /asciicast/clients/$shost/$ym 2> /dev/null")

    if [[ $? -eq 0 ]];then
        if [[ -z "$theFiles" ]];then
            echo "The query is empty. The directory might not exist."
        else
            # Display menu with fzf and capture selection
            selected=$(printf "%s\n" "${theFiles[@]}" | fzf --height=40% --reverse --prompt="Select a file: ")

            scp water:/asciicast/clients/$shost/$ym/$selected /tmp

            if [[ -f "/tmp/$selected" ]];then
                echo "The selected file has been copied to /tmp/$selected."
                vared -p "Would you like to view the file now [Y/n] ? " -c yn
                if [[ $yn != "N" && $yn != "n" ]];then
                    if [[ "$selected" =~ ^.*\.log\..*$ ]];then
                        gpgOpen -f /tmp/$selected -e vim
                    else
                        gpgOpen -f /tmp/$selected
                    fi
                fi
            fi
        fi
    else
        echo "You might not have defined the 'Host water' in your ~/.ssh/config file."
        echo "Define it like something like this (adjust the 'Hostname', 'Port', and 'User' accordingly):\n"
        echo "Host water"
        echo "    Hostname water.lumon.com"
        echo "    Port 2255"
        echo "    User your_user_name\n"
        echo "Please configure it and try again."
    fi
}

reconstruct_auto_complete_script() {
    if [ ! -f $ZSH/templates/pz.completion.template ];then
        echo "File $ZSH/templates/pz.completion.template doesn't exist"
    else
        echo -ne "\rLoading pass files with aliases..."

        pass grep -i -e "^ *alias:" -e "^ *info:"|sed 's/\x1b\[[0-9;]*[sumJK]//g;s/:$//' > /tmp/src.$$

        m=0
        n=$( wc -l /tmp/src.$$ | awk '{print $1}' )

        echo "\rLoading pass files with aliases...[$n]"

        if [[ -f $HOME/.pz.index ]];then
            rm -f $HOME/.pz.index
        fi

        while read l;do
            if [[ -z "$r" ]];then
                r=$(echo "$l"|grep -vie "^ *alias:" -e "^ *info:")
            fi
            if [[ -z "$a" ]];then
                a=$(echo "$l"|grep -i alias|awk -F':' '{print $2}'|sed 's/^\ *//;s/\ *$//')
            fi
            if [[ -z "$i" ]];then
                i=$(echo "$l"|grep -i info|awk -F':' '{print $2}'|sed 's/^\ *//;s/\ *$//')
            fi
            if [[ ! -z "$a" && ! -z "$i" ]];then
                echo "$a:$r:$i" >> $HOME/.pz.index
                r=""
                a=""
                i=""
            fi
            (( m = m + 1 ))
            p=$(( (m * 100) / n ))
            echo -ne "\rReconstructing pz's auto-complete index...[$m/$n ($p%)]"
        done < /tmp/src.$$

        rm -f /tmp/src.$$

        echo
    fi
    return 0
}

get_pwd_record_from_index_file() {
    echo $(
        grep -w $1 $HOME/.pz.index| \
        awk -F':' '{print $2}'
    )
}

get_password_store_directory() {
    if [[ -n "$PASSWORD_STORE_DIR" ]]; then
        echo "$PASSWORD_STORE_DIR"
    else
        echo "$HOME/.password-store"
    fi
}

update_pass_to_be_auto-deleted_record() {
    echo "${clip2pz}" | gpg -eao $HOME/.pz --yes \
        -r $(gpg -K|grep ultimate|sed 's/.*<\(.*\)>.*/\1/')
}

register_retrieved_pass_to_be_auto-deleted() {
    if which cliphist > /dev/null 2>&1;then
        pwd=$1
        if [[ -n $pwd ]];then
            if [[ -f $HOME/.pz ]];then
                if [[ -z $(gpg -qd $HOME/.pz|grep "^${pwd}$") ]];then
                    clip2pz=$(gpg -qd $HOME/.pz)
                    clip2pz="${clip2pz}\n${pwd}"
                    update_pass_to_be_auto-deleted_record
                fi
            else
                clip2pz="${pwd}"
                update_pass_to_be_auto-deleted_record
            fi
        fi
    fi
    return 0
}

pz() {
    valid_args=("--copy" "-c" "--edit" "-e" "--info" "-i" "--login" "-l" "--otp" "-o" "--add-credentials" "-a")
    _pz::main $*
    unset pwd gitPwd
}

add_or_update_netrc_credentials() {
    if which pass > /dev/null;then
        remoteAddr=$(pass git remote -v|head -1|awk -F/ '{print $3}')
        protocol=$(pass git remote -v|head -1|awk -F'://' '{print $1}'|awk '{print $2}')

        if [[ "$protocol" != "http" && "$protocol" != "https" ]];then
            echo "It currently only support http or https protocol."
            return 1
        fi

        if [[ -n $remoteAddr ]];then
            if [[ "$remoteAddr" == "github.com" ]];then
                echo "Sorry. github.com is not supported."
                echo "You should use the gh CLI from github or the other method recommended by github."
                return 1
            else
                if [[ ! -f /usr/bin/git-credential-netrc ]];then
                    echo "Setting up the netrc script."
                    sudo cp $ZSH/lib/git-credential-netrc /usr/bin
                    sudo chmod a+x /usr/bin/git-credential-netrc
                fi

                currHelper=$(pass git config --get credential.helper)

                if [[ -z $currHelper ]];then
                    echo "Setting up pass git credential.helper to netrc."
                    pass git config credential.helper "netrc -f ~/.netrc.gpg"
                elif [[ ! "$currHelper" == "netrc"* ]];then
                    echo "Your current git credential.helper has been set to:"
                    echo $currHelper
                    echo
                    vared -p "Override it [y/n]? " -c t
                    if [[ $t == "y" ]];then
                        echo "Setting up pass git credential.helper to netrc."
                        pass git config credential.helper "netrc -f ~/.netrc.gpg"
                    else
                        echo "Okay. Setting up the remote credentials has been canceled."
                        return 1
                    fi

                fi

                # Escaping generated password for netrc
                gitPwd=${pwd//\\/\\\\}
                gitPwd=${gitPwd//\$/\\$}
                gitPwd=${gitPwd//\#/\\#}
                gitPwd=${gitPwd//\@/\\@}
                gitPwd=${gitPwd//\{/\\\{}
                gitPwd=${gitPwd//\}/\\\}}

                newEntry="machine $remoteAddr"
                newEntry="$newEntry\n login $username"
                newEntry="$newEntry\n password "$gitPwd
                newEntry="$newEntry\n protocol $protocol"

                gpgId=$(gpg -K|grep ultimate|sed -n 's/[^<]*<//;s/>//p')

                if [[ -z $gpgId ]];then
                    echo "err: Ultimately trusted GPG ID was not found."
                    return 1
                fi

                if [[ -f $HOME/.netrc.gpg ]];then
                    echo "About to update the netrc configuration file."
                    netrcContent=$(gpg -qd $HOME/.netrc.gpg|sed '/machine '"$remoteAddr"'/,/\sprotocol/d')
                    if [[ $? -eq 0 ]];then
                        rm -f $HOME/.netrc.gpg
                    fi
                else
                    echo "About to create the netrc configuration file."
                    netrcContent=
                fi

                if [[ $? -eq 0 ]];then
                    if [[ -n "$netrcContent" ]];then
                        netrcContent="$netrcContent\n"$newEntry
                    else
                        netrcContent=$newEntry
                    fi

                    eval "echo \"$netrcContent\"|gpg -eao $HOME/.netrc.gpg -r $gpgId"

                    if [[ -f $HOME/.netrc.gpg ]];then
                        echo "The netrc configuration file has been created/updated."
                        echo "You can now pass git push your record to the server."
                    fi
                fi
            fi
        else
            echo "You haven't added a git remote repository for the pass storage yet."
            return 1
        fi
    else
        echo "I have nothing to do. You haven't even installed the pass yet."
        return 1
    fi
    return 0
}

function _pz::main {
    local usage=(
        "Usage:"
        "pz [-h, --help]"
        "pz {-a, --add-credentials|-c, --copy|-e, --edit|-i, --info|-l, --login|-o, --otp} <alias>"
        "pz {-k, --kill|-b, --rebuild}\n"
        "-h --help                      Display this usage info"
        "-a --add-credentials <alias>   Add netrc credential helper based on given alias"
        "-c --copy <alias>              Copy matches alias pass' password"
        "-e --edit <alias>              Edit matches alias pass' file"
        "-i --info <alias>              Display matches alias pass' file except its password"
        "-l --login <alias>             Copy password and run cmd of matches alias pass' file"
        "-o --otp <alias>               Prints OTP of matches alias pass' file"
        "                                Adds -c to copy OTP"
        "                                Adds -q displays TOTP secret QR-Code"
        "-k --kill                      Clear GPG cache entries"
        "-b --rebuild                   Regenerate pz alias index file\n"
        "Example:"
        "1. Copy matches alias pass' password: pz -c sshLion"
        "2. Print matches alias pass' otp    : pz -o otpLian"
        "3. Copy matches alias pass' otp file: pz -o otpLion -c"
    )

    if [[ "${valid_args[@]}" =~ "${1}" ]];then
        if [[ -z "$2" ]];then
            echo "You'll need to provide the record's alias after the $1 option."
            return 1
        else
            pwdRecord=$(get_pwd_record_from_index_file $2)
        fi
    fi

    if [[ -z "$2" || -n "$2" && -n $pwdRecord ]];then
        while (( $# > 0 )); do
            case $1 in
                --qrcode|-q)
                    if [[ $OTPQRCODE -eq 0 ]];then
                        pass otp uri -q $pwdRecord
                    fi
                    return 0;;
                --copy|-c)
                    if test "$OTPCOPYMODE" = "true";then
                        pwd=$(pass otp $pwdRecord)
                        pass otp -c $pwdRecord
                        unset OTPCOPYMODE
                    else
                        pwd=$(pass $pwdRecord|head -1)
                        pass -c $pwdRecord
                    fi
                    register_retrieved_pass_to_be_auto-deleted "$pwd"
                    return 0;;
                --help|-h)
                    print -l $usage
                    return 0;;
                --edit|-e)
                    pass edit $pwdRecord
                    return 0;;
                --info|-i)
                    echo $pwdRecord:
                    pass $pwdRecord|sed -n '2,$p'
                    return 0;;
                --login|-l)
                    cmd=$(
                    pass $pwdRecord| \
                        grep -i "^ *cmd:"| \
                        awk -F':' '{print $2}'| \
                        sed 's/^\ *//;s/\ *$//'
                    )
                    if [[ -z "$cmd" ]];then
                        echo "The selected password store record doesn't have the 'cmd:' field."
                        echo "Add something like this: 'cmd: ssh jack@dummy.apikk.oho' to a password"
                        echo "store record that you wanted to 'pz --login' to."
                    else
                        pwd=$(pass $pwdRecord|head -1)
                        pass -c $pwdRecord
                        register_retrieved_pass_to_be_auto-deleted "$pwd"
                        cmdCount=$(echo $cmd|wc -l)
                        if [[ $cmdCount -eq 1 ]];then
                            eval "$cmd"
                        else
                            echo "Which command you want to executed?\n"
                            echo $cmd|sed =|sed 'N;s/\n/ /'
                            echo
                            x=
                            vared -p "Enter its number. Empty to cancel: " -c x
                            if [[ -n "$x" && "$x" -ge 1 && "$x" -le "$cmdCount" ]];then
                                eval "$(echo $cmd|sed -n $x,$x'p')"
                            fi
                        fi
                    fi
                    return 0;;
                --otp|-o)
                    if [[ $3 = "-c" || $3 = "--copy" ]];then
                        OTPCOPYMODE=true
                        shift
                    elif [[ $3 = "-q" || $3 = "--qrcode" ]];then
                        OTPQRCODE=0
                        shift
                    else
                        pass otp $pwdRecord
                        return 0
                    fi
                    ;;
                --kill|-k)
                    gpgconf --kill gpg-agent
                    echo "GPG cache entries cleared."
                    return 0;;
                --rebuild|-b)
                    reconstruct_auto_complete_script
                    return 0;;
                --add-credentials|-a)
                    secret=$(pass $pwdRecord)
                    pwd=$(echo $secret|head -1)
                    username=$(echo $secret|grep -i "^\s*login:"|sed 's/login://i;s/\s//')
                    if [[ -z $username ]];then
                        echo "Err: The password file you selected has no \"Login:\" line in it."
                        return 1
                    else
                        add_or_update_netrc_credentials
                        if [[ $? -eq 0 ]];then
                            return 0
                        else
                            return 1
                        fi
                    fi
                    return 0;;
                *)
                    echo "Invalid option: $1"
                    return 1;;
            esac
            shift
        done
    fi
}
