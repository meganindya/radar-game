// Environment Variables
// ---------------------

final int
  width  = 600,             // window width
  height = 600,             // window height
  baseX  = width / 2,       // x-coord of base
  baseY  = height / 2,      // y-coord of base
  fps    = 30;              // frame-rate

final int radius = width / 2;
float
    swipeAngle = 0.0,
    swipeSpeed = 0.01;


// Methods
// -------

void setup() {
    size(600, 600);
    frameRate(fps);
}

void draw() {
    refreshCanvas();
}

void refreshCanvas() {
    background(0);

    // radar circles
    stroke(0, 255, 0);
    noFill();
    for (int i = 1; i <= 6; i++)
        ellipse(baseX, baseY, i * 100, i * 100);

    // radar lines
    line(0, baseY, width, baseY);
    line(baseX, 0, baseX, height);

    // swipe
    for (int i = 0; i < 100; i++)
        drawRadarLine(swipeAngle - i * 0.001, (float) i / 100);
    swipeAngle = (swipeAngle + 0.01) % TWO_PI;

    // base
    noStroke();
    fill(0, 255, 0);
    ellipse(baseX, baseY, 10, 10);
}

void drawRadarLine(float angle, float alpha) {
    int endX = baseX + (int) (radius * cos(angle));
    int endY = baseY + (int) (radius * sin(angle));

    stroke(0, 255 * (1 - alpha), 0);
    line(baseX, baseY, endX, endY);
}
