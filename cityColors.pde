import controlP5.*;

ControlP5 cp5;
DropdownList citiesDropDown;

JSONArray cityList;

ArrayList<City> cities;

color palette1 = #6DC6A8;
color palette2 = #EDD07D;
color palette3 = #E1AF46;
color palette4 = #DF812B;
color palette5 = #E55124;
color[] paletteArray = {palette1, palette2, palette3, palette4, palette5};

PImage mapImage;
boolean mapImageLoaded = false;

boolean debugColors = true;
boolean debugPlaceholders = false;

int screenFSM = 1;
int mapFSM = -1;

String picturesDirectory = "pictures";

//----------------------------  Main Functions  ------------------------------//

void setup() {
	size(1200, 700);
	
	// Check for directory existence
	createOutput(picturesDirectory);

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

		println(name + ", " + topLeftCoordinate[0] + ", " + topLeftCoordinate[1] 
			+ ", " + bottomRightCoordinate[0] + ", " + bottomRightCoordinate[1]);

		cities.add(new City(name, topLeftCoordinate, bottomRightCoordinate));
	}

	if (screenFSM == 1) {
		drawCitiesDropDown();
	}
}

void draw() {
	if (screenFSM == 1) {
		drawSelectionScreen();
	}
	if (debugColors) {
		drawPalette();
	}
}

void controlEvent(ControlEvent theEvent) {
	if (theEvent.isGroup()) {
		mapImageLoaded = false;
		mapFSM = int(theEvent.getGroup().getValue());
		println("event from group : "+theEvent.getGroup().getValue()+" from "
			+theEvent.getGroup());
	}
	else {
		print("control event from : "+theEvent.controller().name());
   		println(", value : "+theEvent.controller().value());
	}
}

//---------------------------  Custom Functions  -----------------------------//

boolean checkDirectoryExistence(String directoryName) {
	File f = new File(dataPath(directoryName));
	if (f.exists()) {
		return true;
	}
	else {
		return false;
	}
}

void drawSelectionScreen() {
	background(palette2);
	drawMap();
}

void drawCitiesDropDown() {
	cp5 = new ControlP5(this);
	PFont p = createFont("Proxima Nova", 24);
	cp5.setControlFont(p);
	citiesDropDown = cp5.addDropdownList("Select City").setPosition(50,100);
	citiesDropDown.toUpperCase(false);
	for (int i=0;i<cities.size();i++) {
    	City city = cities.get(i);

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

void drawMap() {
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
	}
	else {
		City city = cities.get(mapFSM);

		String url = "http://maps.googleapis.com/maps/api/staticmap"
		+ "?center=" + str(city.getCenterLat()) + "," + str(city.getCenterLon())
		+ "&zoom=10"
		+ "&size=" + str(x2-x1) +"x" + str(y2-y1)
		+ "&maptype=roadmap"
		+ "&sensor=false";

		if (!mapImageLoaded) {
			mapImage = loadImage(url, "png");
			mapImageLoaded = true;
		}
		imageMode(CORNERS);
		image(mapImage, x1, y1, x2, y2);
	}
}

void drawPalette() {
	for (int i = 0; i < paletteArray.length; ++i) {
		fill(paletteArray[i]);
		rectMode(CORNER);
		rect(10*i, 0, 10, 10);
	}
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