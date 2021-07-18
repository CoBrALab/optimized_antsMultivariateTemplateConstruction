#!/usr/bin/env python
from argparse import ArgumentParser
import os
import numpy as np
import SimpleITK as sitk


def get_average_from_arrays(array_list,normalize = False, method='mean'): # creates a average (i.e.mean, median, trimmed mean or huber estimator) out of a list of arrays
    shape = array_list[0].shape
    concat_array = array_list[0].flatten()[np.newaxis,:]
    for array in array_list[1:]:
        array = array.flatten()[np.newaxis,:]
        if normalize: # divide the image values by its mean
            array /= array.mean()
        concat_array = np.concatenate((concat_array,array),axis=0)

    if method == 'mean':
        average = np.mean(concat_array, axis=0)
    elif method == 'median':
        average = np.median(concat_array,axis=0)
    elif method == 'trimmed_mean':
        from scipy import stats
        # takes off 15% of values at both end
        average = stats.trim_mean(concat_array, 0.15, axis=0)
    elif method == 'huber':
        import statsmodels.api as sm
        average = sm.robust.scale.huber(concat_array)
    return average.reshape(shape)


if __name__ == "__main__":
    parser = ArgumentParser()
    parser.add_argument("-o", "--output", type=str,
                        help="""
                        Name of output average file.
                        """)
    parser.add_argument('--file_list', type=str,
                        nargs="*",  # 0 or more values expected => creates a list
                        help="""
                        Specify a list of input files, space-seperated (i.e. file1 file2 ...).
                        """)
    parser.add_argument("--image_type", default='image',
                        choices=['image', 'affine', 'warp'],
                        help="""
                        Specify whether the type of image is a nifti structural image,
                        or a set of affine or non-linear (warp) transforms.
                        """)
    parser.add_argument("--method", default='mean',
                        choices=['mean', 'median', 'trimmed_mean', 'huber'],
                        help="""
                        Specify of average method to create from the image list.
                        """)
    parser.add_argument("--normalize", dest='normalize', action='store_true',
                        help="""
                        Whether to divide each image by its mean before computing average.
                        """)
    opts = parser.parse_args()
    output = os.path.abspath(opts.output)


    # takes a average out of the array values from a list of Niftis
    array_list = []
    for file in opts.file_list:
        if (opts.image_type=='warp' or opts.image_type=='image') and '.nii' in file:
            array_list.append(sitk.GetArrayFromImage(sitk.ReadImage(file)))
        elif opts.image_type=='affine' and '.mat' in file:
            transform = sitk.ReadTransform(file)
            array_list.append(np.array(transform.GetParameters()))
        else:
            continue
    average = get_average_from_arrays(array_list, normalize=opts.normalize, method=opts.method)

    if opts.image_type=='image':
        average_img = sitk.GetImageFromArray(average, isVector=False)
        average_img.CopyInformation(sitk.ReadImage(opts.file_list[0]))
        sitk.WriteImage(average_img, output)
    elif opts.image_type=='warp':
        average_img = sitk.GetImageFromArray(average, isVector=True)
        average_img.CopyInformation(sitk.ReadImage(opts.file_list[0]))
        sitk.WriteImage(average_img, output)
    elif opts.image_type=='affine':
        transform.SetParameters(average)
        sitk.WriteTransform(transform, output)
