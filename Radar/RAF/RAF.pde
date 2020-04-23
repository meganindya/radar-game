import java.util.*;

// Environment Variables
// ---------------------

// canvas
final int
  width  = 600,             // window width
  height = 600,             // window height
  baseX  = width / 2,       // x-coord of base
  baseY  = height / 2,      // y-coord of base
  fps    = 30;              // frame-rate

// swipe
final int radius = width / 2;
float swipeAngle, swipeSpeed;

// action bodies
HashMap<Integer, ArrayList<Threat>> angleMap;
ArrayList<Threat> threats;
final int threatCount = 5;
ArrayList<Missile> missiles;
boolean baseDestroyed;


// Methods
// -------

void setup() {
    size(600, 600);
    frameRate(fps);

    reset();
}

void reset() {
    swipeAngle = 0;
    swipeSpeed = 0.01;

    angleMap = new HashMap<Integer, ArrayList<Threat>>();

    threats = new ArrayList<Threat>();
    for (int i = 0; i < threatCount; i++) {
        Threat threat = new Threat(radius);
        threats.add(threat);

        int sectorNumber = (int) (threat.getAngle() / (15 * PI / 180));
        ArrayList<Threat> threatList;
        if (angleMap.containsKey(sectorNumber))
            threatList = angleMap.get(sectorNumber);
        else
            threatList = new ArrayList<Threat>();
        threatList.add(threat);
        angleMap.put(sectorNumber, threatList);
    }

    missiles = new ArrayList<Missile>();
    baseDestroyed = false;
}

void draw() {
    int state = getGameState();
    if (state != 0) {
        gameOver(state);
        return;
    }

    refreshCanvas();

    checkMissileCollisions();

    for (Threat threat : threats) {
        threat.render();
        threat.updatePosition();
        if (threat.reachedBase())
            baseDestroyed = true;
    }

    if (baseDestroyed)
        return;

    ArrayList<Missile> missileRemoveList = new ArrayList<Missile>();
    for (Missile missile : missiles) {
        if (missile.outOfBounds()) {
            missileRemoveList.add(missile);
            continue;
        }
        missile.render();
        missile.updatePosition();
    }
    for (Missile missile : missileRemoveList)
        missiles.remove(missile);
}

// redraws the canvas
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
        drawRadarLine(swipeAngle - i * 0.05 * PI / 180, (float) i / 100);
    swipeAngle = (swipeAngle + swipeSpeed) % TWO_PI;

    // base
    noStroke();
    fill(0, 255, 0);
    ellipse(baseX, baseY, 10, 10);
}

// draws the swipe effect
void drawRadarLine(float angle, float alpha) {
    int endX = baseX + (int) (radius * cos(angle));
    int endY = baseY + (int) (radius * sin(angle));

    stroke(0, 255 * (1 - alpha), 0);
    line(baseX, baseY, endX, endY);
}

// check if game is running, won, or over
int getGameState() {
    if (threats.isEmpty())
        return 1;
    if (baseDestroyed)
        return -1;
    return 0;
}

void checkMissileCollisions() {
    ArrayList<Missile> missileRemoveList = new ArrayList<Missile>();
    for (Missile missile : missiles) {
        int sectorNumber = (int) (missile.getAngle() / (15 * PI / 180));
        ArrayList<Threat> threatList = new ArrayList<Threat>();

        for (int i = -1; i <= 1; i++) {
            int secNum = sectorNumber + i;
            if (secNum < 0)
                secNum += 24;
            if (!angleMap.containsKey(secNum))
                continue;
            threatList.addAll(angleMap.get(secNum));
        }

        if (threatList.isEmpty())
            continue;

        for (Threat threat : threatList) {
            int threatPos[] = threat.getPosition();
            int missilePos[] = missile.getPosition();
            float dist =
                sqrt(
                    pow(missilePos[0] - threatPos[0], 2) +
                    pow(missilePos[1] - threatPos[1], 2)
                );
            if (dist <= (Missile.size + Threat.size)) {
                threats.remove(threat);
                missileRemoveList.add(missile);
                break;
            }
        }
    }

    for (Missile missile : missileRemoveList)
        missiles.remove(missile);
}

void gameOver(int state) {

}

void mousePressed() {
    missiles.add(new Missile(radius, mouseX, mouseY));
}
