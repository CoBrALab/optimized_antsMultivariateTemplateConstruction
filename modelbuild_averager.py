#!/usr/bin/env python
import argparse
import os
import numpy as np
import SimpleITK as sitk


if __name__ == "__main__":
    parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument("-o", "--output", type=str,
                        help="""
                        Name of output average file.
                        """)
    parser.add_argument('--file_list', type=str,
                        nargs="*",  # 0 or more values expected => creates a list
                        required=True,
                        help="""
                        Specify a list of input files, space-separated (i.e. file1 file2 ...).
                        """)
    parser.add_argument("--image_type", default='image', type=str,
                        choices=['image', 'warp'],
                        help="""
                        Specify whether the type of image is a nifti structural image,
                        or a set of non-linear (warp) transforms.
                        """)
    parser.add_argument("--method", default='efficient_trimean', type=str,
                        choices=['mean', 'median', 'trimmed_mean', 'efficient_trimean', 'huber', 'sum', 'std', 'var'],
                        help="""
                        Specify the type of average to create from the image list.
                        """)
    parser.add_argument("--trim_percent", type=float, default=0.15,
                        help="""
                        Specify the fraction to trim off if using trimmed_mean.
                        """)
    parser.add_argument("--normalize", dest='normalize', action='store_true',
                        help="""
                        Whether to divide each image by its mean before computing average.
                        """)
    opts = parser.parse_args()

    if len(opts.file_list)==1:
        print("ONLY ONE INPUT PROVIDED TO --file_list. THE OUTPUT IS THE INPUT.")
        sitk.WriteImage(sitk.ReadImage(opts.file_list[0]), opts.output)
        import sys
        sys.exit()

    if opts.image_type == 'image':

        # Boundary detection stolen from
        # https://github.com/dave3d/dicom2stl/blob/main/utils/regularize.py
        mins = [1e32, 1e32, 1e32]
        maxes = [-1e32, -1e32, -1e32]
        spacings = [1e32, 1e32, 1e32]
        maxdim = -1
        for file in opts.file_list:
            if not os.path.isfile(file):
                raise ValueError("The provided file {file} does not exist.".format(file=file))
            # This is in efficent, but TransformContinuousIndexToPhysicalPoint is not available using reader
            img = sitk.ReadImage(file)
            # reader = sitk.ImageFileReader()
            # reader.SetFileName(file)
            # reader.ReadImageInformation()
            dims = img.GetSize()
            spcs = img.GetSpacing()
            # Corners in voxel space
            vcorners = [
                [0, 0, 0],
                [dims[0], 0, 0],
                [0, dims[1], 0],
                [dims[0], dims[1], 0],
                [0, 0, dims[2]],
                [dims[0], 0, dims[2]],
                [0, dims[1], dims[2]],
                [dims[0], dims[1], dims[2]],
            ]
            wcorners = []
            for c in vcorners:
                wcorners.append(img.TransformContinuousIndexToPhysicalPoint(c))
            # compute the bounding box of the volume
            for c in wcorners:
                for i in range(0, 3):
                    if c[i] < mins[i]:
                        mins[i] = c[i]
                    if c[i] > maxes[i]:
                        maxes[i] = c[i]
            for i,s in enumerate(spcs):
                if s < spacings[i]:
                    spacings[i] = s

        # compute the dimensions of the new volume
        newdims = []
        for i in range(0, 3):
            newdims.append(int((maxes[i] - mins[i]) / spacings[i] + 0.5))

        averageRef = sitk.Image(newdims, sitk.sitkFloat32)
        averageRef.SetSpacing(spacings)
        averageRef.SetOrigin(mins)
        averageRef.SetDirection([1, 0, 0, 0, 1, 0, 0, 0, 1])

        # Need to reverse the dimension order b/c numpy and ITK are backwards
        concat_array = np.empty(newdims[::-1])
        shape = concat_array.shape
        concat_array = concat_array.flatten()

        for file in opts.file_list:
            if not os.path.isfile(file):
                raise ValueError("The provided file {file} does not exist.".format(file=file))
            img = sitk.ReadImage(file)
            img = sitk.Resample(
                img,
                averageRef,
                sitk.Transform(),
                sitk.sitkLinear
            )
            array = sitk.GetArrayViewFromImage(img)
            if opts.normalize: # divide the image values by its mean
                #array /= array.mean()
                concat_array = np.vstack((concat_array, array.flatten()/array.mean()))
            else:
                concat_array = np.vstack((concat_array, array.flatten()))

    else:
        # Need to reverse the dimension order b/c numpy and ITK are backwards
        concat_array = np.empty(sitk.GetArrayViewFromImage(sitk.ReadImage(opts.file_list[0])).shape)
        shape = concat_array.shape
        concat_array = concat_array.flatten()
        for file in opts.file_list:
            print(file)
            if not os.path.isfile(file):
                raise ValueError("The provided file {file} does not exist.".format(file=file))
            img = sitk.ReadImage(file)
            array = sitk.GetArrayViewFromImage(img)
            if opts.normalize: # divide the image values by its mean
                concat_array = np.vstack((concat_array, array.flatten()/array.mean()))
            else:
                concat_array = np.vstack((concat_array, array.flatten()))

    if opts.method == 'mean':
        average = np.mean(concat_array, axis=0)
    elif opts.method == 'median':
        average = np.median(concat_array,axis=0)
    elif opts.method == 'trimmed_mean':
        from scipy import stats
        average = stats.trim_mean(concat_array, opts.trim_percent, axis=0)
    elif opts.method == 'efficient_trimean': 
        # computes the average from the 20th, 50th and 80th percentiles https://en.wikipedia.org/wiki/Trimean
        average = np.quantile(concat_array, (0.2,0.5,0.8),axis=0).mean(axis=0)
    elif opts.method == 'huber':
        import statsmodels.api as sm
        average = sm.robust.scale.huber(concat_array)[0]
    elif opts.method == 'sum':
        average = np.sum(concat_array, axis=0)
    elif opts.method == 'std':
        average = np.std(concat_array, axis=0)
    elif opts.method == 'var':
        average = np.var(concat_array, axis=0)

    average = average.reshape(shape)

    if opts.image_type=='image':
        average_img = sitk.GetImageFromArray(average, isVector=False)
        average_img.CopyInformation(averageRef)
        sitk.WriteImage(average_img, opts.output)
    elif opts.image_type=='warp':
        average_img = sitk.GetImageFromArray(average, isVector=True)
        average_img.CopyInformation(sitk.ReadImage(opts.file_list[0]))
        sitk.WriteImage(average_img, opts.output)
