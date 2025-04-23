# Purpose:
# Shorten some of the frequently used pass commands.
#
# Important:
# Please read the comment sections at the top of the ~/tools/pz/_pz file.

function reconstruct_auto_complete_script {
    if [ ! -f $ZSH/templates/pz.completion.template ];then
        echo "File $ZSH/templates/pz.completion.template doesn't exist"
    else
        echo -ne "\rLoading pass files with aliases..."

        pass grep -i -e "^ *alias:" -e "^ *info:"|sed 's/\x1b\[[0-9;]*[sumJK]//g;s/:$//' > /tmp/src.$$

        m=0
        n=$( wc -l /tmp/src.$$ | awk '{print $1}' )

        echo "\rLoading pass files with aliases...[$n]"

        if [[ -f $HOME/.pz.index ]];then
            rm $HOME/.pz.index
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

        rm /tmp/src.$$

        echo
    fi
    return 0
}

function get_pwd_record_from_index_file {
    echo $(
        grep -w $1 $HOME/.pz.index| \
        awk -F':' '{print $2}'
    )
}

function get_password_store_directory () {
    if [[ -n "$PASSWORD_STORE_DIR" ]]; then
        echo "$PASSWORD_STORE_DIR"
    else
        echo "$HOME/.password-store"
    fi
}

function update_pass_to_be_auto-deleted_record() {
    echo "${clip2pz}" | gpg -eao $HOME/.pz --yes \
        -r $(gpg -K|grep ultimate|sed 's/.*<\(.*\)>.*/\1/')
}

function register_retrieved_pass_to_be_auto-deleted() {
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

function pz {
    valid_args=("--copy" "-c" "--edit" "-e" "--info" "-i" "--login" "-l" "--otp" "-o" "--add-credentials" "-a")
    _pz::main $*
}

function add_or_update_netrc_credentials {
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
                    pass git config credential.helper "netrc -f ~/.netrc.gpg -v"
                elif [[ ! "$currHelper" == "netrc"* ]];then
                    echo "Your current git credential.helper has been set to:"
                    echo $currHelper
                    echo
                    vared -p "Override it [y/n]? " -c t
                    if [[ $t == "y" ]];then
                        echo "Setting up pass git credential.helper to netrc."
                        pass git config credential.helper "netrc -f ~/.netrc.gpg -v"
                    else
                        echo "Okay. Setting up the remote credentials has been canceled."
                        return 1
                    fi

                fi

                pwd=$(echo -n "$pwd"|sed 's/\\/\\\\/g')
                pwd=$(echo -n "$pwd"|sed 's/\$/\\$/g')
                pwd=$(echo -n "$pwd"|sed 's/#/\\#/g')
                pwd=$(echo -n "$pwd"|sed 's/@/\\@/g')
                pwd=$(echo -n "$pwd"|sed 's/{/\\{/g')
                pwd=$(echo -n "$pwd"|sed 's/}/\\}/g')

                newEntry="machine $remoteAddr"
                newEntry="$newEntry\n login $username"
                newEntry="$newEntry\n password $pwd"
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
                        netrcContent="$netrcContent\n$newEntry"
                    else
                        netrcContent="$newEntry"
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
                        eval "$cmd"
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
