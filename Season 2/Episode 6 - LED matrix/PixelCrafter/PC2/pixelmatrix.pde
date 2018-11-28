class PIXEL_MATRIX {
  // vars
  int rows = 16;    // width of the design box
  int columns = 16; // height of the design box
  int x = 0, y = 0; // coordinates
  int s = 25;       // width and height of pixels
  boolean borderOn = false; // turn on or off the border of pixels

  public PIXEL[] pix = new PIXEL[rows*columns];  // array of pixels

  // constructor
  PIXEL_MATRIX () {
    initPixelMatrix();
  }

  PIXEL_MATRIX (int _x, int _y) {
    x = _x;
    y = _y;
    initPixelMatrix();
  }

  PIXEL_MATRIX (int _x, int _y, int _s) {
    x = _x;
    y = _y;
    s = _s;
    initPixelMatrix();
  }

  PIXEL_MATRIX (int _x, int _y, int _s, boolean _borderOn) {
    x = _x;
    y = _y;
    s = _s;
    borderOn = _borderOn;
    initPixelMatrix();
  }

  // methods
  void initPixelMatrix() {
    for (int i = 0; i < rows; i++)
      for (int j = 0; j < columns; j++) {
        pix[i*columns+j] = new PIXEL(0, 0, 0, j*s + x, i*s + y, s, borderOn);  // pixels by default are dark grey
        pix[i*columns+j].px = j;
        pix[i*columns+j].py = i;
      }
  }

  void update() {
    for (int i = 0; i < rows; i++)
      for (int j = 0; j < columns; j++)
        pix[i*columns+j].update();
  }

  public boolean hover() {
    boolean val = false;
    for (int i = 0; i < rows; i++)
      for (int j = 0; j < columns; j++)
        if (pix[i*columns+j].hover()) val = true;
    return val;
  }

  // return the number of the pixel being on
  public int pixelOn() {
    int val = -1;
    for (int i = 0; i < rows; i++)
      for (int j = 0; j < columns; j++)
        if (pix[i*columns+j].hover()) val = i*columns+j;
    return val;
  }

  // cc indicates current color, needed for recursion
  void fillColor(int _x, int _y, int _c, int cc) {
    // get the color of the pixel
    int pc = pix[_y*columns+_x].c;
    for (int i = -1; i <= 1; i++) {
      for (int j = -1; j <= 1; j++) {
        if (_x+i >= 0 && _x+i < columns && _y+j >= 0 && -y+j < rows) {
          if (i != 0 && j != 0) {
            fillColor(_x+i, _y+j, _c, pc);
          } else {
            if (cc == pc) {
              pix[_y*columns+_x].c = _c;
            }
          }
        }
      }
    }
  }

  // method returning the code generated by the drawing
  String generateCode(int oM) {
    String code = "";
    if (oM == 1) 
      println("inverting every other line at output");

    code = "byte red[] = {\n";
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < columns; j++) {
        if (i%2 == 1 && oM == 1)
          code += int(map(red(pix[i*columns + columns -1 - j].c), 0, 255, 0, 100));
        else
          code += int(map(red(pix[i*columns+j].c), 0, 255, 0, 100));
        if (i*rows + j == columns*rows - 1) 
          code += "};\n";
        else
          if ((i*rows + j)%columns == 0 && i > 0)
            code += ",\n";
          else
            code += ", ";
      }
    }

    code += "byte green[] = {\n";
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < columns; j++) {
        if (i%2 == 1 && oM == 1)
          code += int(map(green(pix[i*columns + columns  -1 - j].c), 0, 255, 0, 100));
        else
          code += int(map(green(pix[i*columns+j].c), 0, 255, 0, 100));
        if (i*rows + j == columns*rows - 1) 
          code += "};\n";
        else
          if ((i*rows + j)%columns == 0 && i > 0)
            code += ",\n";
          else
            code += ", ";
      }
    }

    code += "byte blue[] = {\n";
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < columns; j++) {
        if (i%2 == 1 && oM == 1)
          code += int(map(blue(pix[i*columns + columns -1 - j].c), 0, 255, 0, 100));
        else
          code += int(map(blue(pix[i*columns+j].c), 0, 255, 0, 100));
        if (i*rows + j == columns*rows - 1) 
          code += "};\n";
        else
          if ((i*rows + j)%columns == 0 && i > 0)
            code += ",\n";
          else
            code += ", ";
      }
    }
    return code;
  }

  // send to Arduino
  void sendToArduino(int oM) {
    if (oM == 1) 
      println("inverting every other line at output for serial");

    // send initial marker
    sendMarker(255);

    // wait for Arduino to send an answer
    while (myPort.available() <= 0) {
    };

    // loop until getting the final marker from Arduino
    int inByte = myPort.read();
    getMarker(inByte);
    
    while (inByte != 254) {
      // wait for Arduino to send an answer
      while (myPort.available() <= 0) {
      };
      inByte = myPort.read();
      getMarker(inByte);

      // send red when requested
      if (inByte == 253) {
        // send marker
        sendMarker(253);

        // send red
        for (int i = 0; i < rows; i++) {
          for (int j = 0; j < columns; j++) {
            byte d = 0;
            if (i%2 == 1 && oM == 1)
              d = byte(map(red(pix[i*columns + columns -1 - j].c), 0, 255, 0, 100));
            else
              d = byte(map(red(pix[i*columns + j].c), 0, 255, 0, 100));
            myPort.write(d);
          }
        }
      }

      // send green when requested
      if (inByte == 252) {
        // send marker
        sendMarker(252);

        // send green
        for (int i = 0; i < rows; i++) {
          for (int j = 0; j < columns; j++) {
            byte d = 0;
            if (i%2 == 1 && oM == 1)
              d = byte(map(green(pix[i*columns + columns -1 - j].c), 0, 255, 0, 100));
            else
              d = byte(map(green(pix[i*columns + j].c), 0, 255, 0, 100));
            myPort.write(d);
          }
        }
      }    

      // send blue when requested
      if (inByte == 251) {
        // send marker
        sendMarker(251);

        // send blue
        for (int i = 0; i < rows; i++) {
          for (int j = 0; j < columns; j++) {
            byte d = 0;
            if (i%2 == 1 && oM == 1)
              d = byte(map(blue(pix[i*columns + columns -1 - j].c), 0, 255, 0, 100));
            else
              d = byte(map(blue(pix[i*columns + j].c), 0, 255, 0, 100));
            myPort.write(d);
          }
        }
      }
    }
    // send closing marker
    sendMarker(254);
  }
}

class PIXEL {
  // vars
  int r = 200, g = 200, b = 200;  // color
  color c = color(r, g, b);
  int s = 20;  // size
  int x = 0, y = 0;  // coordinates
  int px = 0, py = 0; // coordinates in the matrix (not pixels)
  boolean borderOn = false; // border to the pixels

  // constructor
  PIXEL () {
  }

  PIXEL (int _r, int _g, int _b) {
    r = _r;
    g = _g;
    b = _b;
    c = color(r, g, b);
  }

  PIXEL (int _r, int _g, int _b, int _x, int _y) {
    r = _r;
    g = _g;
    b = _b;
    c = color(r, g, b);
    x = _x;
    y = _y;
  }

  PIXEL (int _r, int _g, int _b, int _x, int _y, int _s) {
    r = _r;
    g = _g;
    b = _b;
    c = color(r, g, b);
    x = _x;
    y = _y;
    s = _s;
  }

  PIXEL (int _r, int _g, int _b, int _x, int _y, int _s, boolean _borderOn) {
    r = _r;
    g = _g;
    b = _b;
    c = color(r, g, b);
    x = _x;
    y = _y;
    s = _s;
    borderOn = _borderOn;
  }

  // methods
  void update() {
    if (borderOn)
      stroke(200);
    else
      noStroke();
    fill(c);
    if (hover())
      rect(x-2, y-2, s, s);
    else
      rect(x, y, s, s);
  }

  // interaction
  public boolean hover() {
    if (mouseX > x && mouseX < x + s && mouseY > y && mouseY < y + s) 
      return true;
    return false;
  }

  // color setter
  public void setColor (int _c) {
    c = _c;
  }
}
