#!/usr/bin/env python

import SimpleITK as sitk
import argparse

if __name__ == "__main__":

    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument(
        "-s",
        "--scale-factor",
        type=float,
        help="""
            Scale inverted warp field by factor.
            """,
    )
    parser.add_argument(
        "input_warp_field",
        type=str,
        help="""
            Input warp field.
            """,
    )
    parser.add_argument(
        "output_warp_field",
        type=str,
        help="""
            Name to save inverted warp field.
            """,
    )

    opts = parser.parse_args()

    input_warp = sitk.ReadImage(opts.input_warp_field)

    # output_warp = sitk.IterativeInverseDisplacementField(input_warp)
    output_warp = sitk.InverseDisplacementField(input_warp)
    if opts.scale_factor:
        output_warp = sitk.Compose(
            [
                sitk.VectorIndexSelectionCast(output_warp, i) * opts.scale_factor
                for i in range(output_warp.GetNumberOfComponentsPerPixel())
            ]
        )

    sitk.WriteImage(output_warp, opts.output_warp_field)
