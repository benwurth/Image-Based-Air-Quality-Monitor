import g4p_controls.*;

color palette1 = #6DC6A8;
color palette2 = #EDD07D;
color palette3 = #E1AF46;
color palette4 = #DF812B;
color palette5 = #E55124;

int fsm = 1;

//----------------------------  Main Functions  ------------------------------//
void setup() {
	size(1200, 700);
	
	// Check for directory existence
	createOutput("folder");

	// Load city information
	
}

void draw() {
	if (fsm == 1) {
		drawSelectionScreen();
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