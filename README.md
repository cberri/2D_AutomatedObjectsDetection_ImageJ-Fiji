# 2D_AutomatedObjectsDetection_ImageJ-Fiji
Project Mathias Diehl (Heidelberg University)

The ImageJ/Fiji macro computes the local maxima of each object on the smooth probability map (PM) images generated by ilastik pixel classification. The ilastik pixel classification workflow is used to reduce the background in the images and enhance the foreground pixels. To segment each object the local maxima are used as a seed for the 3D watershed plugin. This approach allows to separate close objects and create masks that are used to measure size and intensity on the raw images. To detect small and large objects in the same image two sigma values can be chosen by the user to smooth the PM images. The output of the ImageJ/Fiji macro are the segmented images and two table files containing the measurements of each single object in the image and the mean measurements for all the objects in each image.

I) Ilastik pixel classification workflow to classify foreground and background pixels 
-	Download and install ilastik software (current stable version ilastik 1.3.3post3)
-	Chose the Pixel Classification workflow. You will need to create a project and save it on your local machine (project file format “.ilp”)
-	Upload 5-10 sample pictures using the “input data” tab. The training data should consist of representative images (i.e. high background and low background). Raw images were acquired in 16 bits
-	In the “Feature Selection” tab, we choose all the feature with sigma values between 0.3 and 10.
-	Add sparse labels to classify foreground (label 1) and background (label 2) pixels
-	Live Update and check the ilastik prediction for the foreground label
-	Continue with the training until the prediction satisfy your expectations. Tip: choose a new image, not previously trained, to verify the strength of your training.
-	Proceed to export the PM as 16 bits renormalized image
-	Apply the classification to the whole images by selecting the raw data in the “Batch processing” tab
Please visit the ilastik software webpage for additional information on how to use the pixel classification workflow.

II) ImageJ/Fiji macro to measure intensity and size
-	Drag and drop the ImageJ/Fiji macro to the Fiji main window to open the .ijm file. The ilastik import export plugin and the 3D ImageJ/Fiji Suite has to be installed before to run the macro. Please refer to ImageJ/Fiji documentation on how to do this.
-	Press “Run”, it will prompt a window to choose the raw and PM input directories. NB: the raw and the PM images must be saved in two separated folders.
-	Choose the sigma values to blur the PM input images (suggested range 1-9). High sigma allows to segment large objects, lower sigma small objects. A recommended starting sigma value is 5. You can use two sigma factors at the same time to analyse data with different objects sizes (i.e. with small and large objects).
-	All the images in the input folders are processed. The output folder is created automatically inside the input path and contains subfolders with the summary of the measurements of the objects for each individual sigma factor as well as a summary of the data and image masks of the detected objects.
