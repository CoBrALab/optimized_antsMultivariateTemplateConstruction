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
    parser.add_argument('--file-list', type=str,
                        nargs="*",  # 0 or more values expected => creates a list
                        required=True,
                        help="""
                        Specify a list of input files, space-separated (i.e. file1 file2 ...).
                        """)
    parser.add_argument("--method", default='mean', type=str,
                        choices=['mean', 'median', 'trimmed_mean', 'efficient_trimean', 'huber', 'sum', 'std', 'var', 'mad', 'or', 'and', 'nor'],
                        help="""
                        Specify the type of average to create from the image list.
                        """)
    parser.add_argument("--trim-proportion", type=float, default=0.05,
                        help="""
                        Specify the fraction to trim off if using trimmed_mean.
                        """)
    parser.add_argument("--normalize", dest='normalize', action='store_true',
                        help="""
                        Whether to divide each image by its mean before computing average.
                        """)
    parser.add_argument("-v", "--verbose", action='store_true',
                        help="""
                        Be verbose
                        """)
    opts = parser.parse_args()

    inputRefImage = sitk.ReadImage(opts.file_list[0])

    if inputRefImage.GetDimension() == 4:
        image_type = 'timeseries'
    elif inputRefImage.GetNumberOfComponentsPerPixel() == 3:
        image_type = 'warp'
    else:
        image_type = 'image'

    if (image_type == 'image' or image_type == 'warp') and len(opts.file_list) == 1:
        print("ONLY ONE INPUT PROVIDED TO --file_list. THE OUTPUT IS THE INPUT.")
        sitk.WriteImage(inputRefImage, opts.output)
        import sys
        sys.exit()

    if image_type == 'image':
        # Here we cheat to avoid loading all the images for metadata
        # make an tiny empty image, and fill in the metadata from the reader class
        img = sitk.Image([1,1,1], sitk.sitkUInt8)

        # Set the initial properties of the ref image
        img.SetSpacing(inputRefImage.GetSpacing())
        img.SetOrigin(inputRefImage.GetOrigin())
        img.SetDirection(inputRefImage.GetDirection())

        # Boundary detection stolen from
        # https://github.com/dave3d/dicom2stl/blob/main/utils/regularize.py
        mins = [1e32, 1e32, 1e32]
        maxes = [-1e32, -1e32, -1e32]
        spacings = [1e32, 1e32, 1e32]
        maxdim = -1
        outputdirection = [1, 0, 0, 0, 1, 0, 0, 0, 1]
        images_different = False
        for file in opts.file_list:
            if not os.path.isfile(file):
                raise ValueError("The provided file {file} does not exist.".format(file=file))
            reader = sitk.ImageFileReader()
            reader.SetFileName(file)
            reader.ReadImageInformation()

            if not (np.allclose(img.GetSpacing(), reader.GetSpacing(), atol=1e-6) and
                    np.allclose(img.GetOrigin(), reader.GetOrigin(), atol=1e-6) and
                    np.allclose(img.GetDirection(), reader.GetDirection())):
                images_different = True
                img.SetSpacing(reader.GetSpacing())
                img.SetOrigin(reader.GetOrigin())
                img.SetDirection(reader.GetDirection())
                dims = reader.GetSize()
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
                # Corners in world space
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

        if images_different:
            # compute the dimensions of the new volume
            newdims = []
            for i in range(0, 3):
                newdims.append(int((maxes[i] - mins[i]) / spacings[i] + 0.5))

            averageRef = sitk.Image(newdims, sitk.sitkFloat32)
            averageRef.SetSpacing(spacings)
            averageRef.SetOrigin(mins)
            averageRef.SetDirection([1, 0, 0, 0, 1, 0, 0, 0, 1])
        else:
            averageRef = inputRefImage

        # Create empty array to stick data in
        # Need to reverse the dimension order b/c numpy and ITK are backwards
        concat_array = np.empty(shape=[len(opts.file_list), np.prod(averageRef.GetSize())])
        shape = averageRef.GetSize()[::-1]

        for i,file in enumerate(opts.file_list):
            if not os.path.isfile(file):
                raise ValueError("The provided file {file} does not exist.".format(file=file))
            if opts.verbose:
                print(f"Reading image {file} {i+1}/{len(opts.file_list)}")
            img = sitk.ReadImage(file)
            if images_different:
                if opts.verbose:
                    print(f"Resampling image {file}")
                img = sitk.Resample(
                    img,
                    averageRef,
                    sitk.Transform(),
                    sitk.sitkLinear
                )
            array = sitk.GetArrayViewFromImage(img)
            if opts.normalize: # divide the image values by its mean
                concat_array[i,:] = array.flatten()/array.mean()
            else:
                concat_array[i,:] = array.flatten()

    elif image_type == 'timeseries':
        # Assume all timeseries inputs are in the same space
        concat_array = np.empty(shape=[len(opts.file_list), np.prod(sitk.GetArrayViewFromImage(inputRefImage).shape[1:])])
        shape = sitk.GetArrayViewFromImage(inputRefImage).shape[1:]
        for i,file in enumerate(opts.file_list):
            if not os.path.isfile(file):
                raise ValueError("The provided file {file} does not exist.".format(file=file))
            if opts.verbose:
                print(f"Reading image {file} {i+1}/{len(opts.file_list)}")
            img = sitk.ReadImage(file)
            array = sitk.GetArrayViewFromImage(img)
            if opts.normalize: # divide the image values by its mean
                concat_array[i,:] = array.reshape(array.shape[0], -1) / array.reshape(array.shape[0], -1).mean(axis = 1, keepdims=True)
            else:
                concat_array[i,:] = array.reshape(array.shape[0], -1)

    elif image_type == 'warp':
        # Assume all warp fields are in the same space
        concat_array = np.empty(shape=[len(opts.file_list), np.prod(inputRefImage.GetSize())*3])
        shape = sitk.GetArrayViewFromImage(inputRefImage).shape
        for i,file in enumerate(opts.file_list):
            if not os.path.isfile(file):
                raise ValueError("The provided file {file} does not exist.".format(file=file))
            if opts.verbose:
                print(f"Reading image {file}")
            img = sitk.ReadImage(file)
            array = sitk.GetArrayViewFromImage(img)
            if opts.normalize: # divide the image values by its mean
                concat_array[i,:] = array.flatten()/array.mean()
            else:
                concat_array[i,:] = array.flatten()

    if opts.verbose:
        print(f"Computing output {opts.method}")
    if opts.method == 'mean':
        average = np.mean(concat_array, axis=0)
    elif opts.method == 'median':
        average = np.median(concat_array, axis=0)
    elif opts.method == 'trimmed_mean':
        from scipy import stats
        average = stats.trim_mean(concat_array, opts.trim_proportion, axis=0)
    elif opts.method == 'efficient_trimean':
        # computes the average from the 20th, 50th and 80th percentiles https://en.wikipedia.org/wiki/Trimean
        average = np.quantile(concat_array, (0.2,0.5,0.8),axis=0).mean(axis=0)
    elif opts.method == 'huber':
        import statsmodels.api as sm
        average = sm.robust.scale.huber(concat_array)[0]
    elif opts.method == 'mad':
        import statsmodels.api as sm
        average = sm.robust.scale.mad(concat_array)
    elif opts.method == 'sum':
        average = np.sum(concat_array, axis=0)
    elif opts.method == 'std':
        average = np.std(concat_array, axis=0)
    elif opts.method == 'var':
        average = np.var(concat_array, axis=0)
    elif opts.method == 'and':
        average = np.all(concat_array, axis=0).astype(float)
    elif opts.method == 'or':
        average = np.any(concat_array, axis=0).astype(float)
    elif opts.method == 'nor':
        average = np.invert(np.any(concat_array, axis=0)).astype(float)

    average = average.reshape(shape)

    if image_type=='image':
        average_img = sitk.GetImageFromArray(average, isVector=False)
        average_img.CopyInformation(averageRef)
        sitk.WriteImage(average_img, opts.output)
    elif image_type=='warp':
        average_img = sitk.GetImageFromArray(average, isVector=True)
        average_img.CopyInformation(inputRefImage)
        sitk.WriteImage(average_img, opts.output)
    elif image_type=='timeseries':
        average_img = sitk.GetImageFromArray(average, isVector=False)
        # Copy the image metadata from an the first extracted slice of the first image
        average_img.CopyInformation(sitk.Extract(inputRefImage, inputRefImage.GetSize()[0:3] + tuple([0]), directionCollapseToStrategy=sitk.ExtractImageFilter.DIRECTIONCOLLAPSETOSUBMATRIX))
        sitk.WriteImage(average_img, opts.output)
