import controlP5.*;
import java.io.*;

ControlP5 cp5;
DropdownList citiesDropDown;
Textarea mapTextArea;
Textarea pixelData;
Textarea infoText;
Button mapButton;
Slider progressBar;

// color debugGrey = new color(162);

JSONArray cityList;
JSONArray photoList;
JSONArray panoResponses;
JSONArray panoArray;
JSONObject panoramioResponse;

City city;

ArrayList<City> cities;

color palette1 = #6DC6A8;
color palette2 = #EDD07D;
color palette3 = #E1AF46;
color palette4 = #DF812B;
color palette5 = #E55124;
color[] paletteArray = {palette1, palette2, palette3, palette4, palette5};

PImage mapImage;
PImage currentlyLoadedImage = null;
PImage processedImage = null;
boolean mapImageLoaded = false;

boolean debugColors = false;
boolean debugPlaceholders = false;

int screenFSM = 1;
int mapFSM = -1;
int claudeFSM = 1;
int progressBarValue = 0;
int numberOfPicturesToDownload = 1024;
int downloadedImages;
int pictureRemainder;
int currentPhoto = 0;

String picturesDirectory = "/Users/feanor93/Documents/cityColors/data/pictures";

//----------------------------  Main Functions  ------------------------------//

void setup() {
	noSmooth();
	cp5 = new ControlP5(this);
	size(1200, 700);

	processedImage = createImage(floor(sqrt(numberOfPicturesToDownload)), 
		floor(sqrt(numberOfPicturesToDownload)), RGB);
	processedImage.loadPixels();
	for (int i = 0; i < processedImage.pixels.length; ++i) {
		processedImage.pixels[i] = color(162);
	}
	processedImage.updatePixels();

	panoResponses = new JSONArray();
	
	// Check for directory existence
	println(checkDirectoryExistence(picturesDirectory));

	// Load city information
	cities = new ArrayList<City>();

	cityList = loadJSONArray("cities.json");
	for (int i = 0; i < cityList.size(); ++i) {
		JSONObject city = cityList.getJSONObject(i);

		String name = city.getString("name");
		float[] topLeftCoordinate = 
			{city.getFloat("tlcLat"), city.getFloat("tlcLon")};
		float[] bottomRightCoordinate = 
			{city.getFloat("brcLat"), city.getFloat("brcLon")};

		cities.add(new City(name, topLeftCoordinate, bottomRightCoordinate));
	}


	setupMapText();
	setupCitiesDropDown();
	setupMapButton();

	setupProgressBar();
	setupPixelData();

	setupInformationText();
	setupSaveButton();
	setupRestartButton();
	
	// Sets the beginning window. Change for debugging.
	windowSwitcher(3);
}

void draw() {
	background(palette2);

	if (screenFSM == 1) {
		updateMap();
	}
	else if (screenFSM == 2) {
		digitalClaude();
		if (currentlyLoadedImage != null) {
			drawCurrentLoadedImage();
			drawPixelSwatch();
		}
		drawProcessedImage();
	}
	else if (screenFSM == 3) {
		drawFinalImage();
	}
	if (debugColors) {
		drawPalette();
	}
}

void controlEvent(ControlEvent theEvent) {
	if (theEvent.isGroup()) {
		if (theEvent.group().name()=="Select City") {
			mapImageLoaded = false;
			mapFSM = int(theEvent.getGroup().getValue());
		}
	}
	else {
		if (theEvent.controller().name()=="mapButton" && mapFSM >= 0) {
			// println(mapFSM);
			windowSwitcher(2);
		}
		else {
			// print("control event from : "+theEvent.controller().name());
   			// println(", value : "+theEvent.controller().value());
		}
		
	}
}

//---------------------------  Custom Functions  -----------------------------//

boolean checkDirectoryExistence(String directoryName) {
	File f = new File(dataPath(directoryName));
	if (f.exists()) {
		return true;
	}
	else {
		return f.mkdir();
	}
}

void windowSwitcher(int windowState) {
	if (windowState == 1) {
		screenFSM = 1;

		citiesDropDown.setVisible(true);
		mapButton.setVisible(true);
		mapTextArea.setVisible(true);

		progressBar.setVisible(false);
		pixelData.setVisible(false);
	}
	else if (windowState == 2) {
		screenFSM = 2;

		citiesDropDown.setVisible(false);
		mapButton.setVisible(false);
		mapTextArea.setVisible(false);

		progressBar.setVisible(true);
		pixelData.setVisible(true);
	}
	else if (windowState == 3) {
		screenFSM = 3;

		citiesDropDown.setVisible(false);
		mapButton.setVisible(false);
		mapTextArea.setVisible(false);

		progressBar.setVisible(false);
		pixelData.setVisible(false);
	}
}

void setupCitiesDropDown() {
	PFont p = createFont("Proxima Nova", 24);
	cp5.setControlFont(p);
	citiesDropDown = cp5.addDropdownList("Select City").setPosition(50,100);
	citiesDropDown.toUpperCase(false);
	for (int i=0;i<cities.size();i++) {
    	city = cities.get(i);

    	citiesDropDown.addItem(city.name, i);
	}
	citiesDropDown.setItemHeight(28);
	citiesDropDown.setBarHeight(36);
	citiesDropDown.setWidth(350);
	citiesDropDown.setBackgroundColor(paletteArray[2]);
	citiesDropDown.setColorBackground(paletteArray[3]);
	citiesDropDown.setColorActive(paletteArray[0]);
	citiesDropDown.setColorForeground(paletteArray[4]);
}

void updateMap() {
	int x1 = 450;
	int y1 = 50;
	int x2 = 1150;
	int y2 = 550;

	if (mapFSM == -1) {
		if (debugPlaceholders) {
			fill(162);
			rectMode(CORNERS);
			rect(x1, y1, x2, y2);
			line(x1, y1, x2, y2);
			line(x1, y2, x2, y1);

			fill(0);
			textSize(32);
			textAlign(CENTER, CENTER);
			text("MAP", averageInt(x1, x2), averageInt(y1, y2));
		}
		else {
			String url = "http://maps.googleapis.com/maps/api/staticmap"
			+ "?center=Atlantic+Ocean&zoom=1"
			+ "&size=" + str(x2-x1) +"x" + str(y2-y1)
			+ "&maptype=roadmap&sensor=false";

			if (!mapImageLoaded) {
				mapImage = loadImage(url, "png");
				mapImageLoaded = true;
			}
			imageMode(CORNERS);
			image(mapImage, x1, y1, x2, y2);
		}

		mapTextArea.setText("Please select a city");
	}
	else {
		String boxText;
		city = cities.get(mapFSM);

		String url = "http://maps.googleapis.com/maps/api/staticmap"
		+ "?center=" + str(city.getCenterLat()) + "," + str(city.getCenterLon())
		+ "&zoom=10"
		+ "&size=" + str(x2-x1) +"x" + str(y2-y1)
		+ "&maptype=roadmap"
		+ "&sensor=false"
		+ "&path=color:0x00000000|weight:5|fillcolor:0x" 
			+ hex(palette1, 6) + "|"
			+ str(city.tlCoords[0]) + ","
				+ str(city.tlCoords[1]) + "|"
			+ str(city.brCoords[0]) + ","
				+ str(city.tlCoords[1]) + "|"
			+ str(city.brCoords[0]) + ","
				+ str(city.brCoords[1]) + "|"
			+ str(city.tlCoords[0]) + ","
				+ str(city.brCoords[1])
		;

		if (!mapImageLoaded) {
			mapImage = loadImage(url, "png");
			mapImageLoaded = true;
		}
		imageMode(CORNERS);
		image(mapImage, x1, y1, x2, y2);
	
		boxText = city.name + ":" + "\n"
		+ "\n"
		+ "Latitude: " + str(city.getCenterLat()) + "\n"
		+ "Longitude: " + str(city.getCenterLon()) + "\n"
		+ "\n"
		+ "Top-Left Coordinates: " + str(city.tlCoords[0]) 
		+ ", " + str(city.tlCoords[1]) + "\n"
		+ "\n"
		+ "Bottom-Right Coordinates: " + str(city.brCoords[0])
		+ ", " + str(city.brCoords[1])
		;

		mapTextArea.setText(boxText);
	}
}

void setupMapText() {
	String boxText;

	if (mapFSM == -1) {
		boxText = "Please choose a city to begin.";
	}
	else {
		city = cities.get(mapFSM);

		boxText = city.name + ":\n\n"
		+ "Latitude: " + str(city.centerCoords[0])
		+ "Longitude: " + str(city.centerCoords[1])
		;
	}

	mapTextArea = cp5.addTextarea("mapText")
	.setPosition(50,125)
	.setSize(350,412)
	.setFont(createFont("Proxima Nova", 24))
	.setColor(255)
	.setColorBackground(paletteArray[2])
	.setColorForeground(paletteArray[1])
	;
}

void setupMapButton() {
	PFont p = createFont("Proxima Nova", 24);
	cp5.setControlFont(p);

	mapButton = cp5.addButton("mapButton")
	.setPosition(75,575)
	.setHeight(75)
	.setWidth(300)
	.setCaptionLabel("Generate Image")
	.setColorBackground(paletteArray[0])
	.setColorForeground(paletteArray[3])
	.setColorActive(paletteArray[4])
	.align(ControlP5.CENTER, ControlP5.CENTER, 
		ControlP5.CENTER, ControlP5.CENTER)
	;
}

void drawPalette() {
	for (int i = 0; i < paletteArray.length; ++i) {
		fill(paletteArray[i]);
		rectMode(CORNER);
		rect(10*i, 0, 10, 10);
	}
}

void drawProcessedImage() {
	int x1 = 50;
	int y1 = 50;
	int x2 = x1 + 512;
	int y2 = y1 + 512;
	rectMode(CORNERS);
	fill(162);
	// rect(x1, y1, x2, y2);
	imageMode(CORNER);
	image(processedImage, x1, y1, 512, 512);
}

void drawCurrentLoadedImage() {
	int x1 = 50 + 512 + 50;
	int y1 = 50;
	int x2 = x1 + 512;
	int y2 = y1 + 512;
	int xc = (x1 + x2) / 2;
	int yc = (y1 + y2) / 2;
	rectMode(CORNERS);
	fill(255);
	// rect(x1, y1, x2, y2);
	int imageHeight = currentlyLoadedImage.height;
	int imageWidth = currentlyLoadedImage.width;
	// println("imageHeight: "+imageHeight);
	// println("imageWidth: "+imageWidth);
	// if (imageWidth == imageHeight) {
	// 	if (imageWidth > 512) {
	// 		image(currentlyLoadedImage, x1, y1, 512, 512);
	// 	}
	// 	else {
	// 		image(currentlyLoadedImage, xc-(imageWidth/2), yc-(imageWidth/2), 0, 0);
	// 	}
	// }
	// else if (imageWidth > imageHeight) {
	// 	if () {
			
	// 	}
	// }
	
	imageMode(CENTER);

	if (imageWidth < 512 && imageHeight < 512) {
		// println("Small");
		image(currentlyLoadedImage, xc, yc);
	}
	else if (imageWidth == imageHeight) {
		// println("Square");
		image(currentlyLoadedImage, xc, yc);
	}
	else if (imageWidth > imageHeight) {
		// println("Long");
		int newHeight = 512 * imageHeight / imageWidth;
		image(currentlyLoadedImage, xc, yc);
	}
	else {
		// println("Tall");
		int newWidth = 512 * imageWidth / imageHeight;
		image(currentlyLoadedImage, xc, yc);
	}

	// getImageAverage(currentlyLoadedImage);

	float division = float(downloadedImages) / float(numberOfPicturesToDownload);
	progressBarValue = floor(division * 100);
	// println("currentPhoto: "+currentPhoto);
	// println("numberOfPicturesToDownload: "+numberOfPicturesToDownload);
	// println("division: "+division);
	progressBar.setValue(progressBarValue);
}

void drawFinalImage() {
	
}

void setupInformationText() {
	int x1 = 100;
	int y1 = 100;
	int areaWidth = 500;
	int areaHeight = 500;

	infoText = cp5.addTextarea("informationText")
		.setPosition(x1, y1)
		.setSize(areaWidth, areaHeight)
		.setFont(createFont("Proxima Nova", 24))
		.setColor(255)
		.setColorBackground(paletteArray[2])
		.setColorForeground(paletteArray[1])
		;
}
	
void setupSaveButton() {

}
	
void setupRestartButton() {

}

void setupProgressBar() {
	progressBar = cp5.addSlider("progressBarValue")
		.setPosition(50, 600)
		.setRange(0, 100)
		.setSize(512, 30)
		.setLabelVisible(false)
		;

	cp5.getController("progressBarValue").getValueLabel().hide();
}

void setupPixelData() {
	int margin = 10;

	String boxText = "Pixel Data Goes Here";

	pixelData = cp5.addTextarea("pixelData")
	.setPosition(50 + 512 + 50 + 100 + margin, 50 + 512 + 20)
	.setSize(512 - 100 - margin, 100)
	.setFont(createFont("Proxima Nova", 24))
	.setColor(255)
	.setColorBackground(paletteArray[2])
	.setColorForeground(paletteArray[1])
	.setText(boxText);
	;
}

void drawPixelSwatch() {
	int x1 = 50 + 512 + 50;
	int y1 = 50 + 512 + 20;
	int x2 = x1 + 100;
	int y2 = y1 + 100;
	color averageColor = getImageAverage(currentlyLoadedImage, true);
	fill(averageColor);
	rect(x1, y1, x2, y2);

	processedImage.loadPixels();
	if (downloadedImages < processedImage.pixels.length) {
		println("downloadedImages: "+downloadedImages);
		processedImage.pixels[downloadedImages - 1] = averageColor;
	}
	processedImage.updatePixels();
}

int checkFolderSize(City city) {
	File folder;
	int photoCount;
	String path = picturesDirectory + "/" + city.name;
	checkDirectoryExistence(path);
	folder = new File(dataPath(path));
	java.io.FilenameFilter jpgFilter = new java.io.FilenameFilter() {
 			public boolean accept(File dir, String name) {
   			return name.toLowerCase().endsWith(".jpg");
		}
	};

	String[] filenames = folder.list(jpgFilter);

	println(filenames.length + " '.jpg' files in directory.");

	// for (int i = 0; i < filenames.length; i++) {
	// 	println(filenames[i]);
	// }

	photoCount = filenames.length;
	downloadedImages = photoCount;
	return photoCount;
}

boolean checkPhotoExistence(int photoID) {
	String filename = str(photoID) + ".jpg";
	File folder;
	String path = picturesDirectory + "/" + city.name;
	folder = new File(dataPath(path));

	java.io.FilenameFilter jpgFilter = new java.io.FilenameFilter() {
 			public boolean accept(File dir, String name) {
   			return name.toLowerCase().endsWith(".jpg");
		}
	};

	String[] filenames = folder.list(jpgFilter);

	for (int i = 0; i < filenames.length; ++i) {
		if (filenames[i].equals(filename)) {
			print("We have a match!");
			return true;
		}
	}

	return false;
}

void digitalClaude() {
	if (claudeFSM == 1) {
		int totalPics = checkFolderSize(city);
		int remainingPhotos = numberOfPicturesToDownload - totalPics;
		pictureRemainder = remainingPhotos % 100;
		int photoWhole = remainingPhotos - pictureRemainder;

		panoArray = panoramioGetter(city, totalPics+ 100, totalPics);

		currentPhoto = 0;
		claudeFSM = 2;
	}
	else if (claudeFSM == 2) {
		int imageID = panoArray.getJSONObject(currentPhoto).getInt("photo_id");

		if (!checkPhotoExistence(imageID)) {
			String path = picturesDirectory + "/" + city.name;
			String imageUrl = panoArray.getJSONObject(currentPhoto)
				.getString("photo_file_url");
			PImage downloadedPhoto = loadImage(imageUrl);
			currentlyLoadedImage = downloadedPhoto;
			downloadedPhoto.save(path + "/" + str(imageID) + ".jpg");
			// println("Downloading Photo: " + str(imageID) + ", photo number " + str(currentPhoto+1) + "\r");
			currentPhoto++;
		}
		else {
			currentPhoto++;
		}

		if (checkFolderSize(city) == numberOfPicturesToDownload) {
			println("All done downloading!");
			claudeFSM = 3;
		}
		else if (currentPhoto == panoArray.size()) {
			claudeFSM = 1;
		}
	}
	else if (claudeFSM == 3) {
		
	}
}

JSONArray panoramioGetter(City city, int picMaxNumber, int picMinNumber) {
	String picSize = "medium";

	String url = "http://www.panoramio.com/map/get_panoramas.php"
		+ "?set=public"
		+ "&from=" + str(picMinNumber)
		+ "&to=" + str(picMaxNumber)
		+ "&minx=" + str(city.tlCoords[1])
		+ "&miny=" + str(city.brCoords[0])
		+ "&maxx=" + str(city.brCoords[1])
		+ "&maxy=" + str(city.tlCoords[0])
		+ "&size=" + picSize
		+ "&mapfilter=true"
		;

	// println(url);

	panoramioResponse = loadJSONObject(url);
	// println(panoramioResponse);
	photoList = panoramioResponse.getJSONArray("photos");

	return photoList;
}

color getImageAverage(PImage victimImage, boolean cropOffTop) {
	int dimension = victimImage.width * victimImage.height;
	if (cropOffTop) {
		dimension = dimension/3;
	}
	victimImage.loadPixels();

	color averageColor;

	int averageRed = 0;
	int averageGreen = 0;
	int averageBlue = 0;

	for (int i = 0; i < dimension; ++i) {
		averageRed += red(victimImage.pixels[i]);
		averageGreen += green(victimImage.pixels[i]);
		averageBlue += blue(victimImage.pixels[i]);
	}

	averageRed = averageRed / dimension;
	averageGreen = averageGreen / dimension;
	averageBlue = averageBlue / dimension;

	averageColor = color(averageRed, averageGreen, averageBlue);

	return averageColor;
}

int averageInt(int... numbers) {
	int total = 0;

	for (int i : numbers) {
		total += i;
	}

	return total/numbers.length;
}

float averageFloat(float... numbers) {
	float total = 0;

	for (float f : numbers) {
		total += f;
	}

	return total/numbers.length;
}

//--------------------------------  Classes  ---------------------------------//

class City {
	// Initialize variables
	String name;
	float [] tlCoords = new float[2];
	float [] brCoords = new float[2];
	float [] centerCoords = new float[2];

	// Constructor
	City (String n, float [] tlc, float [] brc) {
		name = n;
		tlCoords = tlc;
		brCoords = brc;
	}

	float getCenterLat() {
		return averageFloat(tlCoords[0], brCoords[0]);
	}

	float getCenterLon() {
		return averageFloat(tlCoords[1], brCoords[1]);
	}
}