### Image analysis

Mean intensity was measured per field of view on segmentations of the nuclei area as well as the cell area (excluding the nuclei) using a ImageJ/Fiji (*Schindelin, J., et al. (2012). Fiji: an open-source platform for biological-image analysis. Nature Methods, 9(7), 676–682. [doi:10.1038/nmeth.2019](https://doi.org/10.1038/nmeth.2019)*) batch macro. 

### Segmentation of nuclei area

The nuclei area per field of view was segmented based on a maximum intensity projection of the DAPI channel. The projection was then filtered using a median filter with a radius of 5 px. Background was subtracted using the rolling ball background subtraction method using a sliding paraboloid. An automatic intensity threshold based on the Huang algorithm was used for segmentation. Small segmentation fragments of less than 50 square micron was used to filter out smaller objects from the segmentation mask. 

### Segmentation of cell area

The cell area was segmented based on a maximum intensity projection of the measurement channel. A Guassian filter with a sigma of 10 px was applied to the projection. An empirically determined global background value was used for background subtraction. An automatic intensity based threshold was applied using the Triangle algorithm. Smaller objects of less than 50 square microns were filtered from the binary mask. For creating the final cell area mask for measurement the nuclei mask was subtracted from the cell mask. 

### Measurement

For the intensity measurement only an sub-stack was projected using an average projection. To automatically determine this sub-stack first the on average brightest slice was determined in the DAPI channel (approximation for the slice with the best focus). The average projection was performed 5 slices above to 5 slices below the brightest slice. Mean intensity was then measured in  the segmentation of the nuclei as well as the cell area. The entire cell area was also measured per field of view.
