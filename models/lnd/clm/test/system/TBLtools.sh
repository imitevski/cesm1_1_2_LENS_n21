#!/bin/sh 
#

if [ $# -ne 3 ]; then
    echo "TBLtools.sh: incorrect number of input arguments" 
    exit 1
fi

if [ -z "$BL_ROOT" ] && [ -z "$BL_TESTDIR" ]; then
    echo "TBL.sh: no environment variables set for baseline test - will skip"
    exit 255
fi

test_name=TBLtools.$1.$2.$3

if [ -f ${CLM_TESTDIR}/${test_name}/TestStatus ]; then
    if grep -c PASS ${CLM_TESTDIR}/${test_name}/TestStatus > /dev/null; then
        echo "TBLtools.sh: smoke test has already passed; results are in "
	echo "        ${CLM_TESTDIR}/${test_name}" 
        exit 0
    elif grep -c GEN ${CLM_TESTDIR}/${test_name}/TestStatus > /dev/null; then
        echo "TBLtools.sh: test already generated"
    else
	read fail_msg < ${CLM_TESTDIR}/${test_name}/TestStatus
        prev_jobid=${fail_msg#*job}

	if [ $JOBID = $prev_jobid ]; then
            echo "TBLtools.sh: smoke test has already failed for this job - will not reattempt; "
	    echo "        results are in: ${CLM_TESTDIR}/${test_name}" 
	    exit 2
	else
	    echo "TBLtools.sh: this smoke test failed under job ${prev_jobid} - moving those results to "
	    echo "        ${CLM_TESTDIR}/${test_name}_FAIL.job$prev_jobid and trying again"
            cp -rp ${CLM_TESTDIR}/${test_name} ${CLM_TESTDIR}/${test_name}_FAIL.job$prev_jobid
        fi
    fi
fi

rundir=${CLM_TESTDIR}/${test_name}
if [ -d ${rundir} ]; then
    rm -r ${rundir}
fi
mkdir -p ${rundir} 
if [ $? -ne 0 ]; then
    echo "TBLtools.sh: error, unable to create work subdirectory" 
    exit 3
fi
cd ${rundir}

echo "TBLtools.sh: calling TSMtools.sh to run $1 executable" 
${CLM_SCRIPTDIR}/TSMtools.sh $1 $2 $3
rc=$?
if [ $rc -ne 0 ]; then
    echo "TBLtools.sh: error from TSMtools.sh= $rc" 
    echo "FAIL.job${JOBID}" > TestStatus
    exit 4
fi

if [ -n "${BL_ROOT}" ]; then
    if [ -z "$BL_TESTDIR" ]; then
        BL_TESTDIR=${CLM_TESTDIR}.bl
    fi
    echo "TBLtools.sh: generating baseline data from root $BL_ROOT - results in $BL_TESTDIR"

    echo "TBLtools.sh: calling ****baseline**** TSMtools.sh for smoke test"
    bl_dir=`/bin/ls -1d ${BL_ROOT}/models/lnd/clm/test/system`
    env CLM_TESTDIR=${BL_TESTDIR} \
        CLM_ROOT=${BL_ROOT} \
        CLM_SCRIPTDIR=$bl_dir \
        $bl_dir/TSMtools.sh $1 $2 $3
    rc=$?
    if [ $rc -ne 0 ]; then
        echo "TBLtools.sh: error from *baseline* TSMtools.sh= $rc"
        echo "FAIL.job${JOBID}" > TestStatus
        exit 5
    fi
fi

echo "TBLtools.sh: starting b4b comparisons "
files_to_compare=`cd ${CLM_TESTDIR}/TSMtools.$1.$2.$3; ls *.nc`
if [ -z "${files_to_compare}" ] && [ "$debug" != "YES" ]; then
    echo "TBLtools.sh: error locating files to compare"
    echo "FAIL.job${JOBID}" > TestStatus
    exit 6
fi

all_comparisons_good="TRUE"
for compare_file in ${files_to_compare}; do

    env CPRNC_EXE=${CLM_SCRIPTDIR}/../../tools/ncl_scripts/cprnc.pl \
        ${CLM_SCRIPTDIR}/CLM_compare.sh \
        ${BL_TESTDIR}/TSMtools.$1.$2.$3/${compare_file} \
        ${CLM_TESTDIR}/TSMtools.$1.$2.$3/${compare_file}
    rc=$?
    mv cprnc.out cprnc.${compare_file}.out
    if [ $rc -eq 0 ]; then
        echo "TBLtools.sh: comparison successful; output in ${rundir}/cprnc.${compare_file}.out"
    else
        echo "TBLtools.sh: error from CLM_compare.sh= $rc; see ${rundir}/cprnc.${compare_file}.out for details
"
        all_comparisons_good="FALSE"
    fi
done

if [ ${all_comparisons_good} = "TRUE" ]; then
    echo "TBLtools.sh: baseline test passed"
    echo "PASS" > TestStatus
    if [ $CLM_RETAIN_FILES != "TRUE" ]; then
        echo "TBLtools.sh: removing some unneeded files to save disc space"
        rm *.nc
        rm *.r*
    fi
else
    echo "TBLtools.sh: at least one file comparison did not pass"
    echo "FAIL.job${JOBID}" > TestStatus
    exit 7
fi

exit 0
