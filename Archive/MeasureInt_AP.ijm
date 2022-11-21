run("Set Measurements...", "mean redirect=None decimal=3");

input = "/home/christopher.schmied/HT_Docs/Projects/MeasureInt_AP/testInput/";
output = "/home/christopher.schmied/HT_Docs/Projects/MeasureInt_AP/testOut/";
file = "MUT_CHD8_SINGLE0003.nd2";



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
run("Subtract...", "value=110");
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

close(cellCleanSeg);

// create average projection for measurement
run("Set Measurements...", "mean redirect=None decimal=3");

selectWindow("C1-" + imageTitle);
getDimensions(width, height, channels, slices, frames);
maxArraySize = parseInt(slices)

maxArray = newArray(maxArraySize);

for (n = 1; n <= slices; n++){
	
	selectWindow("C1-" + imageTitle);
	setSlice(n);
	run("Select All");
	run("Measure");
	meanValue = getResult("Mean", 0);
	maxArray[n] = meanValue;
	run("Clear Results");
}

rank = Array.rankPositions(maxArray);
brightestSlice = rank[slices]
// Array.show(maxArray);

print("Brightest slices is " + brightestSlice);

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
run("Select All");
run("Measure");

saveAs("Results", output + File.separator + saveName + "_MeasNuc.csv");
run("Clear Results");

selectImage(cellCleanSegNucSub);
run("Select All");
run("Measure");

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
