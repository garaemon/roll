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
EOF
}

roll_genrc_zsh() {
cat <<EOF
export ROLL_ROOT=$PREFIX_PATH
export ROLL_LISP=
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

if [ `check_env` ] ; then
    echo environmental variable OK
else
    echo environmental variable NG
    return 3
fi

return 0
}

check_env() {
    if [ "${ROLL_ROOT}" != "" ] ; then
	return 0
    else
	return 1
    fi
}

roll_bootstrap() {
    echo "hoge"
    return 1
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

