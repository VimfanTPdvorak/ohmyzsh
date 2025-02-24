# Quickly open an MWiki file by its tag label or open its MOM's index file if no
# parameter is provided, from anywhere.

if [ -z $MWIKI_DIR ];then
    export MWIKI_DIR=$HOME/Documents/MWiki/doc
fi

# If run from a script, do not set the completion function
if (( ${+functions[compdef]} )); then
    compdef _mw mw
fi

# Print usage
function print_usage() {
    print -l $usage
}

function mw {
    zparseopts -D -E -F -- \
        {h,-help}=flag_help \
        {c,-convention}=flag_convention \
        {t,-tag}:=arg_tag_label

    _mw::main
}

function _mw::main {
    local usage=(
        "Usage:"
        "mw"
        "mw [-h|--help]"
        "mw [-c|--convention]"
        "mw {-t|--tag <tag_name>}\n"
        "-h --help                    Display this usage info"
        "-c --convention              Print tag convention"
        "-t --tag <tag_name>          Search for and open a MWiki by tag label\n"
        "Example:"
        "1. Open MWiki MOM Index: mw<Enter>"
        "2. Open stdMISRoadmap  : mw -t MISRo<Tab><Enter>"
    )

    if (( $#flag_help ));then
        print_usage
    elif (( $#flag_convention ));then
        echo "1. camelCase, i.e: momReviewIncentiveSOI."
        echo "2. The mom in the above example is called the initial tag label."
        echo "3. Below are the standardized initial tag labels:"
        echo ""
        echo "about  : Good to know general knowledge."
        echo "alert  : Task need tobe follow up."
        echo "cli    : Sharing knowledge article related to CLI."
        echo "def    : Definition."
        echo "git    : Sharing knowledge article related to GIT."
        echo "gpg    : Sharing knowledge article related to GPG."
        echo "hsw    : General troubleshoot or how stuff works guide."
        echo "latex  : Sharing knowledge article related to LaTeX."
        echo "misc   : Any other note not fit to all defined initial tag."
        echo "mom    : Meeting Agenda & MOM."
        echo "srs    : Work in progress SRS."
        echo "ss     : Reference to Support System ID."
        echo "std    : Work in progress standardization."
        echo "svn    : Sharing knowledge article related to SVN."
        echo "tex    : LaTeX file within MWiki."
        echo "vim    : Sharing knowledge article related to VIM."
        echo "vimwiki: Sharing knowledge article related to Vimwiki."
        echo "xAlert : Task has been followed up."
    elif (( $#arg_tag_label ));then
        pushd $MWIKI_DIR > /dev/null
        vim -c "tag $arg_tag_label[-1]"
        popd > /dev/null
    else
        pushd $MWIKI_DIR > /dev/null
        vim -c "tag momIndex" -c "normal zM2zrgg5jzo"
        popd > /dev/null
    fi
}
