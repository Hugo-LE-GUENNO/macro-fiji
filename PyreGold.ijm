/*
 * PyreGold - Automated Analysis of Gold Particle Density in Cellular Compartments
 * 
 * This ImageJ macro performs quantitative analysis of gold particle distribution
 * in cells, distinguishing between pyrenoid and cytoplasm regions.
 * 
 * Prerequisites:
 * - TIFF images with corresponding segmentation files (_seg.tif)
 * - Trainable Weka Segmentation plugin installed
 * 
 * Author: Hugo-LE-GUENNO  
 * Date: 2025
 * Version: 2.0
 */

// ============================================================================
// INITIAL CONFIGURATION
// ============================================================================

// Configure measurements: area only, with 3 decimal precision
// This ensures reproducibility of quantitative measurements
run("Set Measurements...", "area display redirect=None decimal=3");

// Select folder containing images to analyze
folderPath = getDirectory("Select image folder");
list = getFileList(folderPath);this

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

/**
 * Extracts the base name of a file by removing the extension
 * @param fileName: complete filename with extension
 * @return: base name without extension
 */
function getBaseName(fileName) {
    dotIndex = indexOf(fileName, ".");
    if (dotIndex > 0) {
        return substring(fileName, 0, dotIndex);
    }
    return fileName;
}

// ============================================================================
// MAIN IMAGE PROCESSING LOOP
// ============================================================================

// Process each TIFF file in the selected folder
for (i = 0; i < list.length; i++) {
    
    // Only process TIFF files
    if (list[i].endsWith(".tif")) {
        
        fileName = list[i];
        baseName = getBaseName(fileName);
        
        // Construct segmentation filename (expected naming convention: basename_seg.tif)
        segFileName = baseName + "_seg.tif";
        segFilePath = folderPath + File.separator + segFileName;
        
        // Verify that corresponding segmentation file exists
        if (File.exists(segFilePath)) {
            
            // ================================================================
            // IMAGE LOADING AND DISPLAY
            // ================================================================
            
            // Open original image
            open(folderPath + File.separator + fileName);
            titreImageBase = getTitle();
            
            // Open corresponding segmentation image
            open(segFilePath);
            titreImageSeg = getTitle();
            
            // Arrange images side-by-side for manual ROI selection
            run("Tile");
            
            // ================================================================
            // REGION OF INTEREST (ROI) DEFINITION
            // ================================================================
            
            // Initialize ROI Manager for region selection
            roiManager("reset");
            
            // Manual selection of pyrenoid region
            setTool("freehand");
            waitForUser("Select the pyrenoid");
            roiManager("Add");
            roiManager("Select", 0);
            roiManager("Rename", "pyre");  // Label: pyrenoid
            
            // Manual selection of entire cell
            setTool("freehand");
            roiManager("Show All");  // Display existing ROIs for reference
            waitForUser("Select the whole cell");
            roiManager("Add");
            
            // Create cytoplasm region by subtracting pyrenoid from whole cell
            // This generates the "cell minus pyrenoid" region
            roiManager("Select", newArray(0, 1));  // Select both pyrenoid and cell ROIs
            roiManager("XOR");  // Perform exclusive OR operation (subtraction)
            roiManager("Add");
            roiManager("Select", 2);
            roiManager("Rename", "cell-noPyr");  // Label: cell without pyrenoid
            
            // ================================================================
            // ROI PRESERVATION
            // ================================================================
            
            // Save ROI set for reproducibility and future reference
            saveRoiPath = folderPath + baseName + "_rois.zip";
            roiManager("Save", saveRoiPath);
            
            // ================================================================
            // QUANTITATIVE MEASUREMENTS
            // ================================================================
            
            // Measure cytoplasm region (cell-noPyr)
            selectImage(titreImageSeg);
            roiManager("Select", 2);  // Select cytoplasm ROI
            run("Measure");  // Measure area
            run("Analyze Particles...", "summarize");  // Count and analyze gold particles
            
            // Measure pyrenoid region
            selectImage(titreImageSeg);
            roiManager("Select", 0);  // Select pyrenoid ROI
            run("Measure");  // Measure area
            run("Analyze Particles...", "summarize");  // Count and analyze gold particles
            
            // Clean up: close all images before processing next file
            close("*");
        }
    }
}

// ============================================================================
// DATA COLLECTION AND ANALYSIS
// ============================================================================

// Initialize arrays to store measurement results
nbGold = newArray();      // Number of gold particles per region
Area = newArray();        // Area of each measured region (square units)
Density = newArray();     // Calculated particle density (particles/area unit)
ImageRois = newArray();   // ROI identifiers for data organization

// Access the Summary window generated by "Analyze Particles"
selectWindow("Summary");

// Extract data from Summary table and calculate densities
for (i = 0; i < Table.size; i++) {
    
    // Extract ROI label/identifier
    ImageRois[i] = getResultString("Label", i);
    
    // Extract particle count for this ROI
    nbGold[i] = Table.get("Count", i);
    
    // Extract area measurement for this ROI
    Area[i] = getResult("Area", i);
    
    // Calculate particle density (particles per unit area)
    // This normalization allows comparison between regions of different sizes
    Density[i] = nbGold[i] / Area[i];
}

// ============================================================================
// RESULTS OUTPUT AND EXPORT
// ============================================================================

// Create comprehensive results table with all calculated parameters
Table.showArrays("GoldResult", ImageRois, nbGold, Area, Density);

// Export results to CSV format for statistical analysis
selectWindow("GoldResult");
saveAs("Results", folderPath + File.separator + "_GoldResults.csv");

// Terminate macro execution
exit();

/* 
 * END OF MACRO
 * 
 * OUTPUT FILES GENERATED:
 * - [basename]_rois.zip: ROI sets for each analyzed image
 * - _GoldResults.csv: Comprehensive quantitative results table
 * 
 * RESULTS TABLE COLUMNS:
 * - ImageRois: ROI identifier (pyre, cell-noPyr)
 * - nbGold: Absolute count of gold particles
 * - Area: Region area in square pixels/units
 * - Density: Normalized particle density (particles/unit area)
 */
