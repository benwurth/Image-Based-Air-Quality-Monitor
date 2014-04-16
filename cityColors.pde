import controlP5.*;

ControlP5 cp5;

DropdownList citiesDropDown;

color palette1 = #6DC6A8;
color palette2 = #EDD07D;
color palette3 = #E1AF46;
color palette4 = #DF812B;
color palette5 = #E55124;
color[] paletteArray = {palette1, palette2, palette3, palette4, palette5};

boolean debugColors = true;

int fsm = 1;

String picturesDirectory = "pictures";

//----------------------------  Main Functions  ------------------------------//

void setup() {
	size(1200, 700);
	
	// Check for directory existence
	createOutput(picturesDirectory);

	// Load city information
	

	if (fsm == 1) {
		drawCitiesDropDown();
	}
}

void draw() {
	if (fsm == 1) {
		drawSelectionScreen();
	}
	if (debugColors) {
		drawPalette();
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
	for (int i=0;i<40;i++) {
    	citiesDropDown.addItem("item "+i, i);
	}
	citiesDropDown.setItemHeight(24);
	citiesDropDown.setBarHeight(36);
	citiesDropDown.setWidth(350);
	citiesDropDown.setBackgroundColor(paletteArray[2]);
	citiesDropDown.setColorBackground(paletteArray[3]);
}

void drawMap() {
	int x1 = 450;
	int y1 = 50;
	int x2 = 1150;
	int y2 = 550;

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

//--------------------------------  Classes  ---------------------------------//

class City {
	// Initialize variables
	String name;
	float tlCoords, brCoords, centerCoords;

	// Constructor
	City (String n, float tlc, float brc) {
		name = n;
		tlCoords = tlc;
		brCoords = brc;
	}

}