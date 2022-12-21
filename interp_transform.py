#!/usr/bin/env python

# https://vtk.org/doc/nightly/html/classvtkTransformInterpolator.html
# https://simpleitk.org/doxygen/latest/html/classitk_1_1simple_1_1Transform.html
# https://vtk.org/doc/nightly/html/classvtkMatrix4x4.html
# https://www.paraview.org/Bug/view.php?id=10102#c37133
# https://www.cs.cmu.edu/~kiranb/animation/p245-shoemake.pdf
# Scaling the affine transform by performing interpolation between identity and
# the input transform

import vtk
import SimpleITK as sitk
import argparse
import numpy as np

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

def vtk_to_homogenous_matrix(vtk_transform):
    M = np.eye(4)
    vtk_matrix = vtk_transform.GetMatrix()
    vtk_matrix.DeepCopy(M.ravel(), vtk_matrix)
    return M

if __name__ == "__main__":

    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument(
        "input_transform",
        type=str,
        help="""
            Name of output scaled transform.
            """,
    )
    parser.add_argument(
        "scale_factor",
        type=float,
        help="""
            Scaling factor.
            """,
    )
    parser.add_argument(
        "output_transform",
        type=str,
        help="""
            Name of output scaled transform.
            """,
    )

    opts = parser.parse_args()

    # Input transform
    input_itk_transform = sitk.ReadTransform(opts.input_transform)
    output_itk_transform = sitk.AffineTransform(3)

    input_itk_transform_matrix = itk_to_homogeneous_matrix(input_itk_transform)

    # Create VTK input/output transform, and an identity for the interpolation
    input_vtk_transform = vtk.vtkTransform()
    identity_vtk_transform = vtk.vtkTransform()
    output_vtk_transform = vtk.vtkTransform()

    # Setup the VTK transform by reconstructing from the ITK matrix parameters
    input_vtk_transform.SetMatrix(input_itk_transform_matrix.ravel())

    # Create an interpolator
    vtk_transform_interpolator = vtk.vtkTransformInterpolator()

    # Build an interpolation stack, identity transform and the input transform
    vtk_transform_interpolator.AddTransform(0, identity_vtk_transform)
    vtk_transform_interpolator.AddTransform(1, input_vtk_transform)

    # Generate a transform a fractional step between identity and the input transform
    vtk_transform_interpolator.InterpolateTransform(
        opts.scale_factor, output_vtk_transform
    )

    output_itk_transform = homogenous_matrix_to_itk(vtk_to_homogenous_matrix(output_vtk_transform))
    output_itk_transform.SetFixedParameters(input_itk_transform.GetFixedParameters())

    sitk.WriteTransform(output_itk_transform, opts.output_transform)
