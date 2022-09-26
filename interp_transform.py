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

    print(opts)

    # Input transform
    input_itk_transform = sitk.ReadTransform(opts.input_transform)
    output_itk_transform = sitk.AffineTransform(3)

    # Grab the 4x3 matrix
    input_itk_transform_parameters = input_itk_transform.GetParameters()

    # Create VTK input/output transform, and an identity for the interpolation
    input_vtk_transform = vtk.vtkTransform()
    identity_vtk_transform = vtk.vtkTransform()
    output_vtk_transform = vtk.vtkTransform()

    # Setup the VTK transform by reconstructing from the ITK matrix parameters
    input_vtk_transform.SetMatrix(
        input_itk_transform_parameters[0:3]
        + input_itk_transform_parameters[9:10]
        + input_itk_transform_parameters[3:6]
        + input_itk_transform_parameters[10:11]
        + input_itk_transform_parameters[6:9]
        + input_itk_transform_parameters[11:12]
        + (0, 0, 0, 1)
    )

    # Create an interpolator
    vtk_transform_interpolator = vtk.vtkTransformInterpolator()

    # Build an interpolation stack, identity transform and the input transform
    vtk_transform_interpolator.AddTransform(0, identity_vtk_transform)
    vtk_transform_interpolator.AddTransform(1, input_vtk_transform)

    # Generate a transform a fractional step between identity and the input transform
    vtk_transform_interpolator.InterpolateTransform(
        opts.scale_factor, output_vtk_transform
    )

    # Remap VTK parameters to ITK
    output_itk_transform.SetParameters(
        (
            output_vtk_transform.GetMatrix().GetElement(0, 0),
            output_vtk_transform.GetMatrix().GetElement(0, 1),
            output_vtk_transform.GetMatrix().GetElement(0, 2),
            output_vtk_transform.GetMatrix().GetElement(1, 0),
            output_vtk_transform.GetMatrix().GetElement(1, 1),
            output_vtk_transform.GetMatrix().GetElement(1, 2),
            output_vtk_transform.GetMatrix().GetElement(2, 0),
            output_vtk_transform.GetMatrix().GetElement(2, 1),
            output_vtk_transform.GetMatrix().GetElement(2, 2),
            output_vtk_transform.GetMatrix().GetElement(0, 3),
            output_vtk_transform.GetMatrix().GetElement(1, 3),
            output_vtk_transform.GetMatrix().GetElement(2, 3),
        )
    )

    sitk.WriteTransform(output_itk_transform, opts.output_transform)
