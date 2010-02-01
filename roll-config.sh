#!/bin/sh

COMMANDS="bootstrap clean-fasl check genrc help"
VERBOSE=false


usage() {
echo "usage: roll-config.sh COMMAND PARAMS

currently supported commands:

  roll-config.sh bootstrap [-v] PATH
  roll-config.sh clean-fasl [-v] PATH
  roll-config.sh check [-v]
  roll-config.sh genrc [-v] SHELL PREFIX_PATH
  roll-config.sh help
  
  Options:
    -v: exec commands in verbose mode.
"
};

check_sbcl() {
    which sbcl
}

check_acl() {
    which alisp
}

check_clbuild() {
    which clbuild
}

check_env() {
    if [ "${ROLL_ROOT}" != "" ] ; then
	echo OK
    else
	echo NG
    fi
}

debug_echo() {
    if [ "$VERBOSE" = "true" ] ; then
	echo "[DEBUG] " $@
    fi
}

roll_genrc() {
    TARGET_SHELL=$1
    PREFIX_PATH=$2
    debug_echo "target shell -> $TARGET_SHELL"
    debug_echo "prefix path -> $PREFIX_PATH"
    case $TARGET_SHELL in
	bash ) roll_genrc_bash;;
	csh  ) roll_genrc_csh;;
	zsh  ) roll_genrc_zsh;;
    esac
}

roll_genrc_bash() {
roll_genrc_zsh
}

roll_genrc_csh() {
cat <<EOF
setenv ROLL_ROOT $PREFIX_PATH
setenv ROLL_LISP
setenv ROLL_GITHUB_COMMITTER
EOF
}

roll_genrc_zsh() {
cat <<EOF
export ROLL_ROOT=$PREFIX_PATH
export ROLL_LISP=
export ROLL_GITHUB_COMMITTER=
EOF
}

roll_check() {
if [ `check_sbcl` -o `check_acl` -o "$ROLL_LISP" != "" ] ; then
    echo Lisp OK
else
    echo Lisp NG
    return 1
fi

if [ `check_clbuild` ] ; then
    echo clbuild OK
else
    echo clbuild NG
    return 2
fi

if [ "`check_env`" = "OK" ] ; then
    echo environmental variable OK
else
    echo environmental variable NG
    return 3
fi

return 0
}

roll_clbuild_setup() {
    # setup dependencies
    if [ "`grep -c \"ROLL CONFIG\" $CLBUILD_DIR/dependencies`" = "0" ] ; then
	echo now setting dependencies of clbuild
	echo "# ROLL CONFIG" >> $CLBUILD_DIR/dependencies
	cat ./dependencies >> $CLBUILD_DIR/dependencies
    fi
    # setup my-projects
    touch $CLBUILD_DIR/my-projects
    if [ "`grep -c \"ROLL CONFIG\" $CLBUILD_DIR/my-projects`" = "0" ] ; then
	echo now setting my-projects of clbuild
	echo "# ROLL CONFIG" >> $CLBUILD_DIR/my-projects
	if [ "$ROLL_GITHUB_COMMITTER" = "yes" ] ; then
	    cat ./my-projects-committer >> $CLBUILD_DIR/my-projects
	else
	    cat ./my-projects >> $CLBUILD_DIR/my-projects
	fi
    fi
}

roll_clbuild_install() {
    clbuild install chimi nurarihyon nurikabe komainu yasha tengu clyax
}

roll_bootstrap() {
    CLBUILD_PATH=`which clbuild`
    CLBUILD_DIR=`dirname $CLBUILD_PATH`
    debug_echo CLBUILD_DIR is $CLBUILD_DIR
    roll_clbuild_setup
    roll_clbuild_install
    return 0
}

# main
# $0 = roll-config.sh
# $1 = commands
ROLL_COMMAND=$1
if [ "$ROLL_COMMAND" = "help" ] ; then
    usage
    exit 0
fi
shift 1				# dispose command

# parse options
while getopts v OPT
do
    case $OPT in
	"v" ) VERBOSE=true;;
    esac
done

shift `expr $OPTIND - 1`

for i in $COMMANDS
do
    if [ "$i" = "$ROLL_COMMAND" ] ; then
	roll_$i $@
	exit $?
    fi
done

# error trap
usage
exit 1

