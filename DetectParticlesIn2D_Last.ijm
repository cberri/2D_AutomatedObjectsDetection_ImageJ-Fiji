/*
 * Developed by Dr. Carlo A. Beretta 
 * Department for Anatomy and Cell Biology @ Heidelberg University
 * CellNetworks Math-Clinic Core Facility @ Heidelberg University
 * Email: carlo.beretta@uni-heidelberg.de
 * Tel.: +49 (0) 6221 54 8682
 * 
 * Description: Seed detection + Watershed.
 * The script create the labled image using the ilstik PM and do measures on the raw data.
 * Two sigma values can be used to detect large and small objects in the input images!
 * 
 * Created: 2019-11-01
 * Last update: 2020-09-29
 */

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%% Functions %%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// # 1 General setting
function Setting() {
	
	// Set the Measurments parameters
	run("Set Measurements...", "area mean standard min perimeter integrated limit redirect=None decimal=8");

	// Set binary background to 0 
	run("Options...", "iterations=1 count=1 black");

	// General color setting
	run("Colors...", "foreground=white background=black selection=yellow");

}

// # 2
function CloseAllWindows() {
	
	while(nImages > 0) {
		
		selectImage(nImages);
		close();
		
	}
}

// # 3
// Check ilastik import export plugin installation
function CheckIlastikPluginInstallation() {

	List.setCommands;
				
	if (List.get("Export HDF5") == "") {
			
		print("Before to start to use this macro you need to install the ilastik Import Export plugin!");
		wait(3000); 	
    	print("1. Select Help >> Update... from the menu to start the updater");
		print("2. Click on Manage update sites. This brings up a dialog where you can activate additional update sites");
    	print("3. Activate ilastik Import Export update sites (http://sites.imagej.net/Ilastik/)");
    	print("4. Click Apply changes and restart ImageJ/Fiji");
    	print("5. After restarting ImageJ you should be able to run this macro");
    	print("6. Further information can be found: https://www.ilastik.org/documentation/fiji_export/plugin/");
    	wait(3000);
    	exec("open", "https://www.ilastik.org/documentation/fiji_export/plugin/");
    	exit(); 
       	
	} else {

		print("ilastik Import Export plugin is installed!");
		wait(1000);
		print("\\Clear");
   		
	}

}

// # 4
// Input user setting
function InputDialogValues() {
	
	sigmaLow = 1;
	sigmaHigh = 9;
	
	Dialog.create("User Input Setting");
	Dialog.addNumber("Low Sigma", sigmaLow);
	Dialog.addNumber("High Sigma", sigmaHigh);

	// Add Help button
	html = "<html>"
		+ "<h1> Help:  </h1>"
		+ "<h3> <section> " 
		+ "<b> Tips:</b>" 
			+ "<li> <b> Low sigma </b> values can be used to detect small objects in the images </li>"
			+ "<li> <b> High sigma </b> values can be used to detect large objects in the images </li>"
			+ "<li> Recommended starting sigma values <b> 5 </b> </li>"
		+ "</h3> </section>"

		+ "<p> <h1> How to cite: </h1>"
			+ "<h3> <i> TBD </i> </h3> </p>" 
		+ "</html>";

	Dialog.addHelp(html);
  	Dialog.show();

	sigmaLow = Dialog.getNumber();
	sigmaHigh = Dialog.getNumber();
	
	sigmaValues = newArray(sigmaLow, sigmaHigh);
	return sigmaValues;
		
}

// # 5
// Choose the input directories (Raw and PM)
function InputDirectoryRawPM() {

	dirInRaw = getDirectory("Please choose the RAW input root directory");
	dirInPM = getDirectory("Please choose the PM input root directory");

	// The macro check that you choose a directory and output the input path
	if (lengthOf(dirInRaw) == 0 || lengthOf(dirInPM) == 0) {
		
		exit("Exit");
			
	} else {

		// Output the path
		text = "Input RAW path:\t" + dirInRaw;
		print(text);
		text = "Input PM path:\t" + dirInPM;
		print(text);

		inputPath = newArray(dirInRaw, dirInPM);
		return inputPath;
			
	}
	
}

//  # 6
// Output directory
function OutputDirectory(outputPath, year, month, dayOfMonth, second) {

	// Use the dirIn path to create the output path directory
	dirOutRoot = outputPath;

	// Change the path 
	lastSeparator = lastIndexOf(dirOutRoot, File.separator);
	dirOutRoot = substring(dirOutRoot, 0, lastSeparator);
	
	// Split the string by file separtor
	splitString = split(dirOutRoot, File.separator); 
	
	for (i=0; i<splitString.length; i++) {

		lastString = splitString[i];
		
	} 

	// Remove the end part of the string
	indexLastSeparator = lastIndexOf(dirOutRoot, lastString);
	dirOutRoot = substring(dirOutRoot, 0, indexLastSeparator);

	// Use the new string as a path to create the OUTPUT directory.
	dirOutRoot = dirOutRoot + "MacroResults_" + year + "-" + month + "-" + dayOfMonth + "_0" + second + File.separator;
	return dirOutRoot;
	
}

// # 7
// Open the ROI Manager
function OpenROIsManager() {
	
	if (!isOpen("ROI Manager")) {
		
		run("ROI Manager...");
		
	} else {

		if (roiManager("count") == 0) {

			print("Warning! ROI Manager is already open and it is empty");

		} else {

			print("Warning! ROI Manager is already open and contains " + roiManager("count") + " ROIs");
			print("The ROIs will be deleted!");
			roiManager("reset");
			
		}
		
	}
	
}

// # 8
// Close the ROI Manager 
function CloseROIsManager() {
	
	if (isOpen("ROI Manager")) {
		
		selectWindow("ROI Manager");
     	run("Close");
     	
     } else {
     	
     	print("ROI Manager window has not been found");
     	
     }	
     
}

// # 9
// Save and close Log window
function CloseLogWindow(dirOutRoot) {
	
	if (isOpen("Log")) {
		
		selectWindow("Log");
		saveAs("Text", dirOutRoot + "Log.txt"); 
		run("Close");
		
	} else {

		print("Log window has not been found");
		
	}
	
}

// # 10
// Close Memory window
function CloseMemoryWindow() {
	
	if (isOpen("Memory")) {
		
		selectWindow("Memory");
		run("Close", "Memory");
		
	} else {
		
		print("Memory window has not been found!");
	
	}
	
}

// # 11
// User can choose 2 different sigma values for the gaussian filter to highlight small or large objects in the images
function DetectObjects(inputTitlePM, sigma) {

	// Select the ilastik PM
	selectImage(inputTitlePM);
	run("Duplicate...", "title=seedsDetection");
	run("Gaussian Blur...", "sigma=["+sigma+"]"); // 1 or 9
	seedsBlurredTitle = getTitle();
	run("Find Maxima...", "prominence=1000 output=[Single Points]"); // 1000
	rename("seeds");
	seedsTitle = getTitle();
			
	// Watershed 
	// The image_threshold should work on diffent type of images but in case it can be optimized)
	selectImage(inputTitlePM);
	run("Duplicate...", "title=watershedDetection");
	watershedTitle = getTitle();
	resetMinAndMax();
	run("8-bit");
	run("3D Watershed", "seeds_threshold=0 image_threshold=80 image=["+watershedTitle+"] seeds=["+seedsTitle+"] radius=1");
	rename("3D Watershed");
	run("glasbey inverted");
	labeledTitle = getTitle();

	// Close not usefull images
	selectImage(seedsBlurredTitle);
	close(seedsBlurredTitle);
	selectImage(seedsTitle);
	close(seedsTitle);
	selectImage(watershedTitle);
	close(watershedTitle);
	
	// Return label image
	return labeledTitle;
	
}

// # 12
// Print summary function (Modified from ImageJ/Fiji Macro Documentation)
function printResults(textResults) {

	titleResultsWindow = "Results Window";
	titleResultsOutput = "["+titleResultsWindow+"]";
	outputResultsText = titleResultsOutput;
	
	if (!isOpen(titleResultsWindow)) {

		// Create the results window
		run("Text Window...", "name="+titleResultsOutput+" width=90 height=20 menu");
		
		// Print the header and output the first line of text
		print(outputResultsText, "% Input File Name\t" + "% Objs. ID\t" + "% Objs. Area\t" + "% Objs. Mean Intensity\t" + "\n");
		print(outputResultsText, textResults +"\n");
	
	} else {

		print(outputResultsText, textResults +"\n");
		
	}

}

// # 13
function SaveResultsWindow(dirOutRoot) {

	// Save the SummaryWindow and close it
	selectWindow("Results Window");
	saveAs("Text",  dirOutRoot + "ResultsMeasurements"+ ".csv");
	run("Close");
	
}

// # 14
// Print summary function (Modified from ImageJ/Fiji Macro Documentation)
function printSummary(textSummary) {

	titleSummaryWindow = "Summary Window";
	titleSummaryOutput = "["+titleSummaryWindow+"]";
	outputSummaryText = titleSummaryOutput;
	
	if (!isOpen(titleSummaryWindow)) {

		// Create the results window
		run("Text Window...", "name="+titleSummaryOutput+" width=90 height=20 menu");
		
		// Print the header and output the first line of text 
		
		print(outputSummaryText, "% Input File Name\t" + "% Number of Detected Objs.\t" + "% Mean Objs. Area (Image)\t" + "% Mean Objs. Intensity (Image)\t" + "\n");
		print(outputSummaryText, textSummary +"\n");
	
	} else {

		print(outputSummaryText, textSummary +"\n");
		
	}

}

// # 15
function SaveStatisticWindow(dirOutRoot) {

	// Save the SummaryWindow and close it
	selectWindow("Summary Window");
	saveAs("Text",  dirOutRoot + "SummaryMeasurements"+ ".csv");
	run("Close");
	
}

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%% Macro %%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
macro DetectParticlesIn2D {

	// Start functions
	CloseAllWindows();
	Setting();
	CheckIlastikPluginInstallation();
	OpenROIsManager();

	// Display memory usage
	doCommand("Monitor Memory...");

	// Get the starting time
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);

	// Function choose the input root directory for RAW and PM
	inputPath = InputDirectoryRawPM();
	dirInRaw = inputPath[0]; dirInPM = inputPath[1];
	outputPath = dirInRaw;

	// Get the list of file in the input directories
	fileListRaw = getFileList(dirInRaw);
	fileListPM = getFileList(dirInPM);

	// Raw and PM directories must have the same number of images/files
	if (fileListRaw.length != fileListPM.length) {

		print("Number of RAW images:",  fileListRaw.length);
		print("Number of PM images:",  fileListPM.length);
		exit("Raw and PM directory must contain the same number of input images!");
		
	}

	// Create the output root directory in the input path
	dirOutRoot = OutputDirectory(outputPath, year, month, dayOfMonth, second);

	if (!File.exists(dirOutRoot)) {	
		
		File.makeDirectory(dirOutRoot);
		text = "Output path:\t" + dirOutRoot;
		print(text);
	
	}

	// Input user setting
	sigmaValues = InputDialogValues();

	// Do not display the images
	setBatchMode(true);

	// Loop through the file in the input directories
	for (i=0; i<fileListRaw.length; i++) {

		// Check the input file format (supported tiff / tif and h5)
		if (endsWith(fileListRaw[i], '.tiff') || endsWith(fileListRaw[i], '.tif') && endsWith(fileListPM[i], '.h5') || endsWith(fileListPM[i], '.tiff') || endsWith(fileListPM[i], '.tif')) {

			// ilastik PM file can be h5 or tiff
			if (endsWith(fileListPM[i], '.h5')) {

				run("Import HDF5", "select=["+ dirInPM + fileListPM[i] +"] axisorder=["+ axisDimentions +"]");

				// Work around to solve the problem with the Virtual Stack
				rename("database");
				inputTitleDatabase = getTitle();
				run("Duplicate...", "title=forInputPM");
				rename("forInputPM");
				inputTitlePM = getTitle();
				selectImage(inputTitleDatabase);
				close(inputTitleDatabase);

				// Get input image title
				print("0" + (i+1) + ". Processing:\t" + inputTitlePM);

			} else if (endsWith(fileListPM[i], '.tiff') || endsWith(fileListPM[i], '.tif')) {

				open(dirInPM + fileListPM[i]);

				// Get input image title
				inputTitlePM = getTitle();
				print("0" + (i+1) + ". Processing:\t" + inputTitlePM);

			}
			
			// Open the input RAW image
			open(dirInRaw + fileListRaw[i]);
			inputTitleRaw = getTitle();
			print("0" + (i+1) + ". Processing:\t" + inputTitleRaw);
			
			// Remove the file extension .tiff
			dotIndex = indexOf(inputTitleRaw, ".");
			title = substring(inputTitleRaw, 0, dotIndex);

			// Check if the output directory already exist
			if (File.exists(dirOutRoot)) {
						
				// Create the image output directory inside the output root directory
				dirOut = dirOutRoot + title + File.separator;
				File.makeDirectory(dirOut);
	
			}

			// Create the syntetic image
			selectImage(inputTitlePM);
			getDimensions(width, height, channels, slices, frames);
			newImage("SynteticImage", "16-bit black", width, height, 1);
			syntTitle = getTitle();

			// Detetect large objects in the image
			sigma = sigmaValues[1];
			labeledTitle = DetectObjects(inputTitlePM, sigma);
			rename("largeObj");
			labeledTitleLarge = getTitle();

			// Detetect small objects in the image
			sigma = sigmaValues[0];
			labeledTitle = DetectObjects(inputTitlePM, sigma);
			rename("smallObj");
			labeledTitleSmall = getTitle();

			// .................................................................
			// Measures (high sigma)
			// Loop through the labled objects and measure intensity and area
			selectImage(labeledTitleLarge);
			getMinAndMax(min, max);
			meanIntensity = newArray(max);
			objArea = newArray(max);
			objNum = 0;
			sumAreaImage = 0;
			sumIntensityImage = 0;

			for (k=min; k<=max; k++) {

				// Select the labeled object image
				selectImage(labeledTitleLarge);

				// Interective threshold limits
				lowerValue = k+1;
				upperValue = k+1;
									
				// Use the threshold to select each object in the image
				setThreshold(lowerValue, upperValue);

				// Select the threshold object
				run("Create Selection");
													
				// Measure object properties only if selection exist
				selectionExist = selectionType();

				// Draw the selection only if the threshold is true
				if (selectionExist != -1) {

					// Count number of obj detected
					objNum += 1;
					
					// Select raw data
					selectImage(inputTitleRaw);
					run("Restore Selection");

					// Object area
					objArea[k] = getValue("Area");
					sumAreaImage += objArea[k]; 

					// Object intensity
					meanIntensity[k] = getValue("Mean");
					sumIntensityImage += meanIntensity[k];

					// Output the values
					text = title + "Results\t" + "0" + (k+1) + "\t" + objArea[k] + "\t" + meanIntensity[k] + "\t";
					printResults(text);

					// Remove the large object to detect only the samll objects
					selectImage(labeledTitleSmall);
					run("Restore Selection");
					run("Set...", "value=0");
					run("Select None");

					// Create a synthetic image of the object detected using the objID
					selectImage(syntTitle);
					run("Restore Selection");
					run("Fit Circle");
					run("Set...", "value=["+(k+1)+"]");
					run("Select None");
					
				}

			}

			// Output the statistic
			text = title + "_Summary_LargeSigma\t" + objNum + "\t" + sumAreaImage /objNum + "\t" + sumIntensityImage /objNum + "\t";
			printSummary(text);
			
			// .................................................................
			// Measures (low sigma) after removing the large objects in the image
			selectImage(labeledTitleSmall);

			// Remove noise pixels
			run("Median...", "radius=2");

			// Get the max number of objects detected for high sigma value
			addObjNum = objNum;
			
			// Loop through the labled objects and measure intensity and area
			getMinAndMax(min, max);
			meanIntensity = newArray(max);
			objArea = newArray(max);
			objNum = 0;
			sumAreaImage = 0;
			sumIntensityImage = 0;

			for (k=min; k<=max; k++) {

				// Select the labeled object image
				selectImage(labeledTitleSmall);

				// Interective threshold limits
				lowerValue = k+1;
				upperValue = k+1;
									
				// Use the threshold to select each object in the image
				setThreshold(lowerValue, upperValue);

				// Select the threshold object
				run("Create Selection");
													
				// Measure object properties only if selection exist
				selectionExist = selectionType();

				// Draw the selection only if the threshold is true
				if (selectionExist != -1) {

					// Count number of obj detected
					objNum += 1;
					
					// Select raw data
					selectImage(inputTitleRaw);
					run("Restore Selection");

					// Object area
					objArea[k] = getValue("Area");
					sumAreaImage += objArea[k]; 

					// Object intensity
					meanIntensity[k] = getValue("Mean");
					sumIntensityImage += meanIntensity[k];

					// Output the values
					text = title + "Results\t" + "0" + (k+1) + "\t" + objArea[k] + "\t" + meanIntensity[k] + "\t";
					printResults(text);

					// Create a synthetic image of the object detected using the objID
					selectImage(syntTitle);
					run("Restore Selection");
					run("Fit Circle");
					run("Set...", "value=["+(k+addObjNum)+"]");
					run("Select None");
					
				}

			}
			
			// Output the statistic
			text = title + "_Summary_SmallSigma\t" + objNum + "\t" + sumAreaImage /objNum + "\t" + sumIntensityImage /objNum + "\t";
			printSummary(text);

			// .................................................................

			// Close all the open images
			selectImage(inputTitleRaw);
			close(inputTitleRaw);
			selectImage(inputTitlePM);
			close(inputTitlePM);
			selectImage(labeledTitleLarge);
			saveAs("tiff", dirOut + "Processed_LargeObj" + title + "_labeled");
			labeledTitleLarge = getTitle();
			close(labeledTitleLarge);
			selectImage(labeledTitleSmall);
			saveAs("tiff", dirOut + "Processed_SmallObj" + title + "_labeled");
			labeledTitleSmall = getTitle();
			close(labeledTitleSmall);
			selectImage(syntTitle);
			run("glasbey inverted");
			saveAs("tiff", dirOut + "Processed_" + title + "_synthetic");
			syntTitle = getTitle();
			close(syntTitle);
			
		} else {

			// Update the user
			print("Skypped: Input file format not supported: " + fileListRaw[i] + " - " + fileListPM[i]);

		}

	}

	// Update the user 
	text = "\nNumber of file processed:\t\t" + ((fileListRaw.length + fileListPM.length) /2);
	print(text);
	text = "\n%%% Congratulation your file have been successfully processed %%%";
	print(text);
	
	// End functions
	SaveStatisticWindow(dirOutRoot);
	SaveResultsWindow(dirOutRoot);
	CloseROIsManager();
	CloseLogWindow(dirOutRoot);
	CloseMemoryWindow();
	
	// Display the images
	setBatchMode(false);
	showStatus("Completed");
	
}