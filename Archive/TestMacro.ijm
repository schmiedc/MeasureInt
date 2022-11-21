run("Set Measurements...", "mean redirect=None decimal=3");
getDimensions(width, height, channels, slices, frames);
print(slices);
maxArraySize = parseInt(slices)

maxArray = newArray(maxArraySize);

for (n = 1; n <= slices; n++){
	
	selectWindow("C1-MUT_CHD8_SINGLE0003.nd2");
	run("Select All");
	run("Measure");
	setSlice(n);
	meanValue = getResult("Mean", 0);
	maxArray[n] = meanValue;
	run("Clear Results");
}

rank = Array.rankPositions(maxArray);
brightestSlice = rank[slices]

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
selectWindow("C2-MUT_CHD8_SINGLE0003.nd2");
run("Z Project...", "start=" + topProject + " stop=" + bottomProject + " projection=[Average Intensity]");

measureName = "measurement";
rename(measureName);