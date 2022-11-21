saveSettings();
run("Set Measurements...", "mean redirect=None decimal=3");
run("Colors...", "foreground=white background=black selection=yellow");
run("Options...", "iterations=1 count=1 black");
setBatchMode(false);
/*
 * Macro template to process multiple images in a folder
 * NOTE: disabled the saving of detection results as too inaccurate at the moment
 * NOTE: just measure entire area
 * BUG: in measurements: measures on whole image not in mask
 * BUG FIX: need to go via ROI Manager and summarize
 */

#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".tif") suffix

// See also Process_Folder.py for a version of this code
// in the Python scripting language.

processFolder(input);

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], suffix))
			processFile(input, output, list[i]);
	}
}

function processFile(input, output, file) {
	
	// reset measurements
	run("Set Measurements...", "mean redirect=None decimal=3");
	// Do the processing here by adding your own code.
	// Leave the print statements until things work, then remove them.
	print("Processing: " + input + File.separator + file);
	print("Saving to: " + output);
	
	// TODO: Fix measurement bug
	// TODO: Parameterize
	// TODO: Maybe also save the projected channels
	run("Bio-Formats Importer", "open=" + input + File.separator + file + " autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	
	saveName = File.nameWithoutExtension;
	
	imageTitle = getTitle();
	run("Split Channels");
	
	// segment nuclei
	selectWindow("C1-" + imageTitle);
	run("Duplicate...", "duplicate");
	nucleusName = "Nuc-" + imageTitle;
	rename(nucleusName);
	
	// create segmentation based on duplicate
	run("Z Project...", "projection=[Max Intensity]");
	run("Median...", "radius=5");
	run("Subtract Background...", "rolling=50 sliding");
	run("Auto Threshold", "method=Huang white");
	nucleusSeg = "Nuc-Seg-" + imageTitle;
	rename(nucleusSeg);
	
	// clean up nucleus segmentation
	run("Analyze Particles...", "size=50-Infinity show=Masks");
	run("Invert LUT");
	nucleusCleanSeg = "Nuc-Seg-Clean" + imageTitle;
	rename(nucleusCleanSeg);
		
	// clean up
	close(nucleusSeg);
	
	// segment cell area
	selectWindow("C2-" + imageTitle);
	run("Duplicate...", "duplicate");
	cellName = "Cell-" + imageTitle;
	rename(cellName);
	
	run("Z Project...", "projection=[Max Intensity]");
	run("Gaussian Blur...", "sigma=10");
	run("Subtract...", "value=110"); // empirical value
	run("Auto Threshold", "method=Triangle white");
	cellSeg = "Cell-Seg-" + imageTitle;
	rename(cellSeg);
	
	// clean up cell segmentation
	run("Analyze Particles...", "size=50-Infinity show=Masks");
	run("Invert LUT");
	cellCleanSeg = "Cell-Seg-Clean" + imageTitle;
	rename(cellCleanSeg);
	
	close(cellSeg);
	
	imageCalculator("Subtract create", cellCleanSeg, nucleusCleanSeg);
	cellCleanSegNucSub = "Cell-Seg-Clean-NucSub" + imageTitle;
	rename(cellCleanSegNucSub);
	
	// measure cell area
	selectImage(cellCleanSeg);
	run("Analyze Particles...", "size=0-Infinity show=Nothing summarize add");
	Table.rename("Summary", "Results");
	totalArea = getResult("Total Area", 0);
	percentArea = getResult("%Area", 0);
	close(cellCleanSeg);
	run("Clear Results");
	
	// detect nuclei
	selectWindow("C1-" + imageTitle);
	run("Duplicate...", "duplicate");
	nucleusNameForDetect = "Nuc-ForDetect-" + imageTitle;
	rename(nucleusNameForDetect);
	run("Z Project...", "projection=[Max Intensity]");
	nucleusNameForDetectProj = "Nuc-ForDetect-Proj-" + imageTitle;
	rename(nucleusNameForDetectProj);
	run("Gaussian Blur...", "sigma=15");
	run("Find Maxima...", "prominence=5 exclude output=Count");
	count= getResult("Count", 0);
	run("Clear Results");
	
	close(nucleusNameForDetect);
	
	print("Area: " + totalArea + " Percent: " + percentArea);
	print("Count: " + count);
	
	Table.create("normalization");
	Table.set("Area", 0, totalArea);
	Table.set("Percent", 0, percentArea);
	// Table.set("Count", 0, count);
	
	Table.save(output + File.separator + saveName + "_Area.csv");
	close("normalization");

	// visualize detection and segmentation
	selectWindow("C1-" + imageTitle);
	run("Duplicate...", "duplicate");
	nucleusNameForDetectViz = "Nuc-ForDetect-Viz" + imageTitle;
	rename(nucleusNameForDetectViz);
	selectImage(nucleusNameForDetectViz);
	run("Z Project...", "projection=[Max Intensity]");
	nucleusNameForDetectProjViz = "Nuc-ForDetect-Proj-Viz-" + imageTitle;
	rename(nucleusNameForDetectProjViz);
	selectImage(nucleusNameForDetectProjViz);
	run("8-bit");
	run("Enhance Contrast...", "saturated=0.35");
	
	close(nucleusNameForDetectViz);
	
	// segment cell area
	selectWindow("C2-" + imageTitle);
	run("Duplicate...", "duplicate");
	cellNameViz = "Cell-Viz-" + imageTitle;
	rename(cellNameViz);
	selectImage(cellNameViz);
	run("Z Project...", "projection=[Max Intensity]");
	cellNameProjViz = "Cell-Proj-Viz-" + imageTitle;
	rename(cellNameProjViz);
	selectImage(cellNameProjViz);
	run("8-bit");
	run("Enhance Contrast...", "saturated=0.35");
	
	close(cellNameViz);
	
	run("Merge Channels...", "c2=" + nucleusNameForDetectProjViz + " c6=" + cellNameProjViz + " create ignore");
	projViz = "Viz-" + imageTitle;
	rename(projViz);
	selectImage(projViz);
	run("From ROI Manager");
	roiManager("reset");
	
	selectImage(nucleusNameForDetectProj);
	run("Find Maxima...", "prominence=10 output=[Point Selection]");
	
	run("Add Selection...");
	run("To ROI Manager");
	
	selectImage(projViz);
	run("From ROI Manager");
	roiManager("reset");
	
	selectImage(projViz);
	// saveAs("PNG", output + File.separator + saveName + "_detectRes.tif");
	// close(saveName + "_detectRes.png");
	close(projViz);
	
	close(nucleusNameForDetectProjViz);
	close(cellNameViz);
	close(nucleusNameForDetectProj);
	
	// determine brightest slice
	run("Set Measurements...", "mean redirect=None decimal=3");
	
	selectWindow("C1-" + imageTitle);
	getDimensions(width, height, channels, slices, frames);
	maxArraySize = parseInt(slices);
	
	maxArray = newArray(maxArraySize);
	
	for (n = 1; n <= slices; n++){
		
		selectWindow("C1-" + imageTitle);
		setSlice(n);
		run("Select All");
		run("Measure");
		meanValue = getResult("Mean", 0);
		maxArray[n] = meanValue;
		run("Clear Results");
		selectWindow("C1-" + imageTitle);
		run("Select None");
	}
	
	rank = Array.rankPositions(maxArray);
	brightestSlice = rank[slices];
	// Array.show(maxArray);
	
	print("Brightest slices is " + brightestSlice);
	
	// determine projection parameters
	projectionDepthUpDown = 5;
	
	topProject = brightestSlice - projectionDepthUpDown;
	bottomProject = brightestSlice + projectionDepthUpDown;
	
	if (topProject < 1) {
		
		print("Top slice is " + topProject);
		topProject = 1;
		print("Set to 1");
		
	} else {
		
		print("Top slice is " + topProject);
		
	}
	
	if (bottomProject > slices) {
		
		print("Bottom slice is " + bottomProject);
		bottomProject = slices;
		print("Set to 1");
		
	} else {
		
		print("Bottom slice is " + bottomProject);
		
	}
	
	// average projection for measurement
	selectWindow("C2-" + imageTitle);
	run("Z Project...", "start=" + topProject + " stop=" + bottomProject + " projection=[Average Intensity]");
	
	measureName = "measurement-" + imageTitle;
	rename(measureName);
	
	// measure
	run("Set Measurements...", "area mean standard modal min integrated median redirect=" + measureName + " decimal=3");
	
	close("C1-" + imageTitle);
	close("C2-" + imageTitle);
	
	selectImage(nucleusCleanSeg);
	run("Analyze Particles...", "summarize");
	Table.rename("Summary", "Results");
	saveAs("Results", output + File.separator + saveName + "_MeasNuc.csv");
	run("Clear Results");
	
	selectImage(cellCleanSegNucSub);
	run("Analyze Particles...", "summarize");
	Table.rename("Summary", "Results");
	saveAs("Results", output + File.separator + saveName + "_MeasCell.csv");
	run("Clear Results");
	
	// process for merge
	selectImage(nucleusCleanSeg);
	run("16-bit");
	selectImage(cellCleanSegNucSub);
	run("16-bit");
	
	// merge
	run("Merge Channels...", "c2=" + nucleusCleanSeg + " c4=" + measureName + " c6=" + cellCleanSegNucSub + " create keep ignore");
	mergeName = getTitle();
	selectImage(mergeName);
	
	saveAs("Tiff", output + File.separator + saveName + "_segRes.tif");
	
	// clean up
	close(saveName + "_segRes.tif");
	
	close(cellName);
	close(nucleusName);
	
	close(nucleusCleanSeg);
	close(cellCleanSegNucSub);
	close(measureName);
	
	// reset measurements
	run("Set Measurements...", "mean redirect=None decimal=3");

}

restoreSettings;
