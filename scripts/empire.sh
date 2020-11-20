#!/bin/bash

cd /home/data/out/STAR/quant

[ -z "$JAVAMAXMEM" ] && JAVAMAXMEM="60000M"

jar=/home/software/nlEmpiRe.jar

commands=""
for com in `cut -f1 /home/scripts/emp.commands`
do
	[ ! -z "$commands" ] && commands="$commands,"
	commands="$commands$com"
done
	
[ -z "$1" ] && echo "$0 <cmd> where cmd is one of $commands" && exit 0

cmd=`grep "^$1	" /home/scripts/emp.commands | cut -f2`

[ -z "$cmd" ] && echo "$0 <cmd> where cmd is one of $commands" && exit 0

shift 1

echo "java -Xmx$JAVAMAXMEM -cp $jar $cmd $*"
java -Xmx$JAVAMAXMEM -cp $jar $cmd $*
