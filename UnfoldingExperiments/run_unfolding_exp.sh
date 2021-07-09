#!/bin/bash

if [[ -z "$1" ]] ; then
        echo "Missing test-folder"
        exit
fi

#Cleaning previous results

SOURCE=$(basename ${1})
cp -r ../$SOURCE /dev/shm/
F=/dev/shm/${1}
TO=5
VERIFYPN=verifypn-r243

if [[ ! -z "$3" ]] ; then
        TO="$3"
fi

if [[ ! -d "$F" ]] ; then
        echo "$F is not a folder"
        exit
fi

if [ "$2" == "A+B" ] ; then
echo "Running A+B on $F with a timeout of $TO minutes for each net"


ODIR="output/A+B-unfolding-stdout"
BINDIR="output/A+B-unfolding-stats"
mkdir -p $ODIR
mkdir -p $BINDIR

for i in $(ls $F ) ; do
    echo "Running A+B/$i"
    R=$(timeout ${TO}m /usr/bin/time -f "@@@%e,%M@@@" ../binaries/$VERIFYPN -n -x 1 $F/$i/model.pnml $F/$i/ReachabilityCardinality.xml --output-stats output/A+B-unfolding-stats  --noverify 2>&1 )
    echo "$R" > $ODIR/$i
done 

python3 read_AB_results.py --binary output/A+B-unfolding-stats --output A+B-unfolding-results

fi
#----------------------------------------------

if [ "$2" == "MCC" ] ; then
echo "Running MCC on $F with a timeout of $TO minutes for each net"

BINDIR="output/mcc-linux"
mkdir -p $BINDIR
for i in $(ls $F ) ; do
    echo "Running MCC/$i"
    R=$(timeout ${TO}m /usr/bin/time -f "@@@%e,%M@@@" ../binaries/mcc hlnet -i $F/$i/model.pnml --stats 2>&1 )
    echo "$R" > $BINDIR/$i  
done

python3 read_mcc_results.py

fi
#----------------------------------------------

if [ "$2" == "ITS" ] ; then
echo "Running ITS on $F with a timeout of $TO minutes for each net"

BINDIR="output/its-tools"
mkdir -p $BINDIR
for i in $(ls $F ) ; do 
    echo "Running ITS/$i"
    
    timeout ${TO}m /usr/bin/time -f @@@%e,%M@@@ ../binaries/ITS-Tools/its-tools -pnfolder $F/$i -examination ReachabilityCardinality --unfold &> $BINDIR/$i
    rm "$F/$i/model.sr.pnml"
    rm "$F/$i/ReachabilityCardinality.sr.xml"
    rm -r /tmp/.eclipse
done

./get_its_stats.sh its-tools
python3 read_its_results.py
fi

#----------------------------------------------

if [ "$2" == "SPIKE" ] ; then
echo "Running Spike on $F with a timeout of $TO minutes for each net"

BINDIR="output/Spike"
mkdir -p $BINDIR
for i in $(ls $F ) ; do
    echo "Running SPIKE/$i"
    R=$(timeout ${TO}m /usr/bin/time -f @@@%e,%M@@@ ../binaries/spike-1.6.0rc1-linux64 load -f=$F/$i/model.pnml unfold 2>&1 )
    echo "$R" > $BINDIR/$i
done

./get_spike_stats.sh spike
python3 read_spike_trunk_results.py --binary output/spike-stats --output spike-unfolding-results

rm -rf "logs"

fi
#----------------------------------------------

if [ "$2" == "A" ] ; then
echo "Running A on $F with a timeout of $TO minutes for each net"

ODIR="output/A-unfolding-stdout"
BINDIR="output/A-unfolding-stats"
mkdir -p $ODIR
mkdir -p $BINDIR

for i in $(ls $F ) ; do
    echo "Running A/$i"
    R=$(timeout ${TO}m /usr/bin/time -f "@@@%e,%M@@@" ../binaries/$VERIFYPN -n -x 1 $F/$i/model.pnml $F/$i/ReachabilityCardinality.xml --output-stats $BINDIR --noverify --disable-cfp 2>&1 )
    echo "$R" > $ODIR/$i 
done 

python3 read_AB_results.py --binary output/A-unfolding-stats --output A-unfolding-results

fi

#----------------------------------------------

if [ "$2" == "B" ] ; then
echo "Running B on $F with a timeout of $TO minutes for each net"

ODIR="output/B-unfolding-stdout"
BINDIR="output/B-unfolding-stats"
mkdir -p $ODIR
mkdir -p $BINDIR
for i in $(ls $F ) ; do
    echo "Running B/$i"
    R=$(timeout ${TO}m /usr/bin/time -f @@@%e,%M@@@ ../binaries/$VERIFYPN -n -x 1 $F/$i/model.pnml $F/$i/ReachabilityCardinality.xml --output-stats $BINDIR --noverify --disable-partitioning 2>&1 )
    echo "$R" > $ODIR/$i 
done 

python3 read_AB_results.py --binary output/B-unfolding-stats --output B-unfolding-results

fi
#----------------------------------------------

if [ "$2" == "TRUNK" ] ; then
echo "Running trunk-226 on $F with a timeout of $TO minutes for each net"

ODIR="output/trunk-226"
mkdir -p $ODIR
for i in $(ls $F ) ; do
    echo "Running trunk/$i"
    R=$(timeout ${TO}m /usr/bin/time -f @@@%e,%M@@@ ../binaries/trunk-226 -x 1 $F/$i/model.pnml $F/$i/ReachabilityCardinality.xml 2>&1 )
    echo "$R" > $ODIR/$i 
done 

./get_trunk_stats.sh trunk-226
python3 read_spike_trunk_results.py --binary output/trunk-226-stats --output Spike-unfolding-results

fi
#----------------------------------------------

#echo "Creating cactus plots from results"

#python3 ../cactus_plot.py -f ../results -d -s -n 200 -o ../results/sizegraph.png
#python3 ../cactus_plot.py -f ../results -d -t -w -p ../results/timegraph.png
rm -r $F
