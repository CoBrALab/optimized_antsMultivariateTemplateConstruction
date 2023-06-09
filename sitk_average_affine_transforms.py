#!/usr/bin/env python

# Based on https://github.com/BIC-MNI/pyezminc/blob/develop/examples/xfmavg_scipy.py
# and https://caff.de/posts/4X4-matrix-decomposition/decomposition.pdf

import SimpleITK as sitk
import numpy as np
import argparse

# needed for matrix log and exp and inv
import scipy.linalg


def itk_to_homogeneous_matrix(itk_transform):
    # Dump the matrix 4x4 matrix
    input_itk_transform_parameters = itk_transform.GetParameters()
    M = np.zeros((4, 4))
    # Extract the 3x3 matrix and place into the larger 4x4
    M[0:3, 0:3] = np.asarray(input_itk_transform_parameters[0:9]).reshape((3, 3))
    # Append the translation
    M[0:3, 3] = input_itk_transform_parameters[9:]
    M[3, 3] = 1

    return M

def homogenous_matrix_to_itk(M):
    return sitk.AffineTransform(
            M[0:3, 0:3].flatten(),
            M[0:3, 3].flatten(),
            (0, 0, 0),
        )

def homogenous_matrix_to_rotation_scaleshear(M):
    # Decompose M transform in R*D transform, return both
    C = np.zeros((3,3))
    C = M[0:3, 0:3]

    Cprime = np.matmul(np.transpose(C), C)

    D = np.zeros((3,3))
    if np.linalg.det(C) > 0:
        D[0,0] = +np.sqrt(Cprime[0,0])
        D[0,1] = Cprime[0,1]/D[0,0]
        D[0,2] = Cprime[0,2]/D[0,0]
        D[1,1] = +np.sqrt(Cprime[1,1] - np.square(D[0,1]))
        D[1,2] = (Cprime[1,2] - D[0,1]*D[0,2])/D[1,1]
        D[2,2] = +np.sqrt(Cprime[2,2] - np.square(D[0,2]) - np.square(D[1,2]))
    else:
        D[0,0] = -np.sqrt(Cprime[0,0])
        D[0,1] = Cprime[0,1]/D[0,0]
        D[0,2] = Cprime[0,2]/D[0,0]
        D[1,1] = -np.sqrt(Cprime[1,1] - np.square(D[0,1]))
        D[1,2] = (Cprime[1,2] - D[0,1]*D[0,2])/D[1,1]
        D[2,2] = -np.sqrt(Cprime[2,2] - np.square(D[0,2]) - np.square(D[1,2]))

    R = np.matmul(C,np.linalg.inv(D))

    return R, D

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
        "--file-list",
        type=str,
        nargs="*",  # 0 or more values expected => creates a list
        required=True,
        help="""
            Specify a list of input files, space-separated (i.e. file1 file2 ...).
            """,
    )
    parser.add_argument(
        "--no-translation",
        action="store_true",
        help="""
            Zero-out translation of average transformation.
            """,
    )
    parser.add_argument(
        "--no-rotation",
        action="store_true",
        help="""
            Zero-out rotation of average transformation.
            """,
    )
    parser.add_argument(
        "--no-rigid",
        action="store_true",
        help="""
            Zero-out rotation and translation of average transformation.
            """,
    )
    opts = parser.parse_args()

    average_matrix = np.zeros((4, 4), dtype=complex)

    for file in opts.file_list:
        input_itk_transform = sitk.ReadTransform(file)
        # Sum the log of all matrices
        average_matrix += scipy.linalg.logm(
            itk_to_homogeneous_matrix(input_itk_transform)
        )

    # Divide by the total number of input matrices
    average_matrix /= len(opts.file_list)
    # Exponentiate the matrices to undo the log
    average_matrix = scipy.linalg.expm(average_matrix).real

    if opts.no_rotation or opts.no_rigid:
        # Get the D matrix which has no rotation
        _, D = homogenous_matrix_to_rotation_scaleshear(average_matrix)
        average_matrix[0:3, 0:3] = D

    if opts.no_translation or opts.no_rigid:
        # Zero out the translation components
        average_matrix[0:3, 3] = (0,0,0)

    output_average_transform = homogenous_matrix_to_itk(average_matrix)
    output_average_transform.SetFixedParameters(sitk.ReadTransform(opts.file_list[0]).GetFixedParameters())

    sitk.WriteTransform(output_average_transform, opts.output)
