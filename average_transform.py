#!/usr/bin/env python

# Based on https://github.com/BIC-MNI/pyezminc/blob/develop/examples/xfmavg_scipy.py

import SimpleITK as sitk
import numpy as np
import argparse

# needed for matrix log and exp
import scipy.linalg


def itk_to_homogeneous_matrix(itk_transform):
    # Dump the matrix 4x3 matrix
    input_itk_transform_parameters = itk_transform.GetParameters()

    M = np.zeros((4, 4))
    M[0:3, 0:3] = np.asarray(input_itk_transform_parameters[0:9]).reshape((3, 3))
    M[0:3, 3] = input_itk_transform_parameters[9:]
    M[3, 3] = 1

    return M


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument(
        "-o",
        "--output",
        type=str,
        required=True,
        help="""
            Name of output average transform.
            """,
    )
    parser.add_argument(
        "--file_list",
        type=str,
        nargs="*",  # 0 or more values expected => creates a list
        required=True,
        help="""
            Specify a list of input files, space-separated (i.e. file1 file2 ...).
            """,
    )
    opts = parser.parse_args()

    average_matrix = np.zeros((4, 4), dtype=complex)

    for file in opts.file_list:
        # Input transform
        input_itk_transform = sitk.ReadTransform(file)
        average_matrix += scipy.linalg.logm(
            itk_to_homogeneous_matrix(input_itk_transform)
        )

    average_matrix /= len(opts.file_list)
    average_matrix = scipy.linalg.expm(average_matrix).real

    output_average_transform = sitk.AffineTransform(average_matrix[0:3, 0:3].flatten(), average_matrix[0:3, 3].flatten(), (0,0,0))

    print(output_average_transform)

    sitk.WriteTransform(output_average_transform, opts.output)
