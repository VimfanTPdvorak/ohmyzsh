#!/bin/zsh
#
# Open my Vimwiki directly for a specific tag, or open the diary index if no tag
# option is provided.

if [ -z $NEKOMI_WIKI_DIR ];then
    export NEKOMI_WIKI_DIR=$HOME/Documents/vimwiki/doc
fi

if [ -z $MWIKI_DIR ];then
    export MWIKI_DIR=$HOME/Documents/MWiki/doc
fi

# If run from a script, do not set the completion function
if (( ${+functions[compdef]} )); then
    compdef _vw vw
fi

function vw {
    zparseopts -D -E -F -- \
        {w,-wiki}:=arg_wiki \
        {t,-tag}:=arg_tag_label

    _vw::main
}

function _vw::main {
    if (( $#arg_wiki )) && (( ! $#arg_tag_label ));then
        if [[ $arg_wiki[-1] == "Personal" ]];then
            pushd $NEKOMI_WIKI_DIR > /dev/null
            vim diary/diary.wiki -c "normal zM2zrgg3jzo"
            popd
        else
            pushd $MWIKI_DIR > /dev/null
            vim -c "tag momIndex" -c "normal zM2zrgg5jzo"
            popd
        fi
    else
        cd $NEKOMI_WIKI_DIR

        if (( $#arg_tag_label )); then
            vim -c "tag $arg_tag_label[-1]"
        else
            vim diary/diary.wiki -c "normal zM2zrgg3jzo"
        fi
    fi
}
