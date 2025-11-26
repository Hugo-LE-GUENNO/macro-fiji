// Définir la largeur de la zone centrale à couper
centerRadius = 2;
setLineWidth(6);

im0 = getImageID();
getDimensions(width, height, channels, slices, frames);
roiManager("Reset");
run("Rotate...", "  angle=90");
roiManager("Add");

// Récupérer l'image active
run("Select None");

// Récupérer la ROI active depuis le ROI Manager
roiManager("Select", 0); // Sélectionne la première ROI
getSelectionBounds(x, y, roiWidth, roiHeight);

// Calculer les nouvelles coordonnées pour centrer la ROI
newX = (width - roiWidth) / 2;
newY = (height - roiHeight) / 2;

// Déplacer la ROI
selectImage(im0);
roiManager("Select", 0);
run("Translate... ", "x=" + (newX - x) + " y=" + (newY - y));

// Ajouter la nouvelle ROI au ROI Manager
roiManager("Add");

// **Créer un cercle au centre de l'image**
centerX = width / 2;
centerY = height / 2;
setKeyDown("alt");makeOval(centerX - centerRadius, centerY - centerRadius, centerRadius * 2, centerRadius * 2);
roiManager("Add");

// Continuer avec la FFT
selectImage(im0);
run("Select None");
run("FFT");

imFFT = getImageID();
roiManager("Select", 2);
run("Clear", "slice");
run("Inverse FFT");

selectImage(imFFT);
close();
