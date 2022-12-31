#!/bin/bash
# Loop over similarity and affine transform transforms for input population
# and compute the mean determinant
# For enough iterations, determinant should average to 1

set -euo pipefail

calc() { awk "BEGIN{ print $* }"; }

shopt -s nullglob


for dir in ${1}/similarity/*/; do
    for file in ${dir}/transforms/*mat; do
        if [[ ! -s $(dirname ${file})/$(basename ${file} .mat).xfm ]]; then
            echo itk_convert_xfm ${file} $(dirname ${file})/$(basename ${file} .mat).xfm
        fi
    done | parallel
    echo similarity,$(basename ${dir}),$(calc $(xfm2det ${dir}/transforms/*xfm | cut -d "," -f 2 | tail -n +2 | paste -sd+ | bc) / $(ls -1q  ${dir}/transforms/*xfm | wc -l) )
done | sort -h --field-separator=',' --key=2


for dir in ${1}/affine/*/; do
    for file in ${dir}/transforms/*mat; do
        if [[ ! -s $(dirname ${file})/$(basename ${file} .mat).xfm ]]; then
            echo itk_convert_xfm ${file} $(dirname ${file})/$(basename ${file} .mat).xfm
        fi
    done | parallel
    echo affine,$(basename ${dir}),$(calc $(xfm2det ${dir}/transforms/*xfm | cut -d "," -f 2 | tail -n +2 | paste -sd+ | bc) / $(ls -1q  ${dir}/transforms/*xfm | wc -l) )
done | sort -h --field-separator=',' --key=2

for dir in ${1}/nlin/*/; do
    for file in ${dir}/transforms/*mat; do
        if [[ ! -s $(dirname ${file})/$(basename ${file} .mat).xfm ]]; then
            echo itk_convert_xfm ${file} $(dirname ${file})/$(basename ${file} .mat).xfm
        fi
    done | parallel
    echo nlin,$(basename ${dir}),$(calc $(xfm2det ${dir}/transforms/*xfm | cut -d "," -f 2 | tail -n +2 | paste -sd+ | bc) / $(ls -1q  ${dir}/transforms/*xfm | wc -l) )
done | sort -h --field-separator=',' --key=2
