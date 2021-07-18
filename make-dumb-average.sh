#!/bin/bash

quick_com_align() {
  tmpdir2=$(mktemp -d)

  moving=$1
  fixed=$2
  output=$3

  antsAI -d 3 --convergence 0 --verbose 1 -m Mattes[${fixed},${moving},32,None] -o ${tmpdir2}/transform.mat -t Rigid

  antsApplyTransforms -d 3 -r ${fixed} -i ${moving} -t ${tmpdir2}/transform.mat -o ${output} --verbose

  rm -rf ${tmpdir2}


}


tmpdir=$(mktemp -d)

template=$1
average_type=$2
shift
shift
inputs="$@"

# get path to script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

AverageImages 3 ${template} 1 ${inputs}

for file in "$@"; do
  quick_com_align ${file} ${template} ${tmpdir}/$(basename ${file})
done

${SCRIPT_DIR}/get_average.py -o ${template} --normalize --image_type image --method ${average_type} --file_list ${tmpdir}/*

for file in "$@"; do
  quick_com_align ${file} ${template} ${tmpdir}/$(basename ${file})
done

${SCRIPT_DIR}/get_average.py -o ${template} --normalize --image_type image --method ${average_type} --file_list ${tmpdir}/*

rm -rf ${tmpdir}
