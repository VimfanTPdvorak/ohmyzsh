# Purpose:
# Shorten some of the frequently used pass commands.
#
# Important:
# Please read the comment sections at the top of the ~/tools/pz/_pz file.

function reconstruct_auto_complete_script {
    if [ ! -f $ZSH/templates/pz.completion.template ];then
        echo "File $ZSH/templates/pz.completion.template doesn't exist"
    else
        echo "Reconstructing pz's auto-complete index..."

        pass grep -i -e "^ *alias:" -e "^ *info:"|sed 's/\x1b\[[0-9;]*[sumJK]//g;s/:$//' > /tmp/src.$$

        if [[ -f $HOME/_pz.index ]];then
            rm $HOME/_pz.index
        fi

        spaces=$(printf ' %.0s' {1..20})

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
                echo "$a:$r" >> $HOME/_pz.index
                r=""
                a=""
                i=""
            fi
        done < /tmp/src.$$

        rm /tmp/src.$$

        echo "The pz's autocomplete index has been reconstructed."
    fi
    return 0
}

function get_pwd_record_from_index_file {
    echo $(
        grep -w $1 $HOME/_pz.index| \
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
    valid_args=("--copy" "-c" "--edit" "-e" "--info" "-i" "--login" "-l" "--otp" "-o")
    _pz::main $*
}

function _pz::main {
    if [[ "${valid_args[@]}" =~ "${1}" ]];then
        if [[ -z "$2" ]];then
            echo "You'll need to provide the record's alias after the $1 option."
            exit 1
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
                *)
                    echo "Invalid option: $1"
                    return 1;;
            esac
            shift
        done
    fi
}
