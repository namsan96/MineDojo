#!/bin/bash

# run from the script directory
cd "$(dirname "$0")"

echo "$(dirname "$0")"

replaceable=0
port=0
scorepolicy=0
env=0
seed="NONE"
runDir="run"
jvm_debug_port=0

while [ $# -gt 0 ]
do
    case "$1" in
        -replaceable) replaceable=1;;
        -port) port="$2"; shift;;
        -seed) seed="$2"; shift;;
        -scorepolicy) scorepolicy="$2"; shift;;
        -env) env=1;;
        -runDir) runDir="$2"; shift;;
        -jvm_debug_port) jvm_debug_port="$2"; shift;;
        *) echo >&2 \
            "usage: $0 [-replaceable] [-port 10000] [-seed 123123] [-scorepolicy 0123] [-env] [-runDir /home/asdasd] [-jvm_debug_port 1044]"
            exit 1;;
    esac
    shift
done
  
if ! [[ $port =~ ^-?[0-9]+$ ]]; then
    echo "Port value should be numeric"
    exit 1
fi


if [ \( $port -lt 0 \) -o \( $port -gt 65535 \) ]; then
    echo "Port value out of range 0-65535"
    exit 1
fi

if ! [[ $scorepolicy =~ ^-?[0-9]+$ ]]; then
    echo "Score policy should be numeric"
    exit 1
fi

# - - - - - - - - - - - - - - - - - -
# Validate jvm port (if any)
# - - - - - - - - - - - - - - - - - -
if ! [[ $jvm_debug_port =~ ^-?[0-9]+$ ]]; then
    echo "Port value should be numeric"
    exit 1
fi


if [ \( $jvm_debug_port -lt 0 \) -o \( $port -gt 65535 \) ]; then
    echo "Port value out of range 0-65535"
    exit 1
fi

# - - - - - - - - - - - - - - - - - -

configDir="$runDir/config"

# Now write the configuration file
if [ ! -d $configDir ]; then
  mkdir $configDir
fi
echo "# Configuration file
# Autogenerated from command-line options

malmoports {
  I:portOverride=$port
}
malmoscore {
  I:policy=$scorepolicy
}

malmoseed {
  I:seed=$seed
}
" > $configDir/malmomodCLIENT.cfg

if [ $replaceable -gt 0 ]; then
    echo "runtype {
  B:replaceable=true
}
" >> $configDir/malmomodCLIENT.cfg
fi


if [ $env -gt 0 ]; then
    echo "envtype {
  B:env=true
}
" >> $configDir/malmomodCLIENT.cfg
fi

cat $configDir/malmomodCLIENT.cfg

echo "$runDir"
# Finally we can launch the Mod, which will load the config file
# ./gradlew makeStart

#    ./gradlew setupDecompWorkspace
#    ./gradlew build 
# gradle does not respect --gradle-user-home when it comes to where to download itself
# rather, it is set in gradle.properties and is controlled by an env variable
# If build/libs/MalmoMod-0.37.0-fat.jar does not exist change command to 'test'
echo $MINEDOJO_FORCE_BUILD 

if [ ! -e build/libs/MalmoMod-0.37.0-fat.jar ] || [ "$MINEDOJO_FORCE_BUILD" == "1" ]; then
    echo "HELLO"
    cmd="./gradlew runClient --stacktrace -Pjvm_debug_port=$jvm_debug_port -PrunDir=$runDir"
else

    #export GRADLE_USER_HOME=${runDir}/gradle
    export GRADLE_USER_HOME=~/.gradle
    cd $runDir
    cmd="java -Dfml.coreMods.load=com.microsoft.Malmo.OverclockingPlugin -Xmx2G -Dfile.encoding=UTF-8 -Duser.country=US -Duser.language=en -Duser.variant -jar ../build/libs/MalmoMod-0.37.0-fat.jar"
fi
# If build/libs/MalmoMod-0.37.0-fat.jar does not exist change command to 'test'

if [ "$MINEDOJO_HEADLESS" == "1" ]; then
  xvfb-run -a -s "-screen 0 1024x768x24" $cmd
else
  $cmd
fi
[ $replaceable -gt 0 ]

