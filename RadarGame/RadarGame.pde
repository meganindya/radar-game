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

boolean started = false;

int score, hiscore = 0;
HashMap<Missile, Integer> missileScoreMap;


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

    score = 0;
    missileScoreMap = new HashMap<Missile, Integer>();
}

void draw() {
    int state = getGameState();
    if (started && state != 0) {
        gameOver(state);
        return;
    }

    refreshCanvas();

    if (!started) {
        gameOver(2);
        return;
    }

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

    displayScores();

    // radar circles
    stroke(0, 255, 255);
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
    fill(0, 255, 255);
    ellipse(baseX, baseY, 10, 10);
}

// draws the swipe effect
void drawRadarLine(float angle, float alpha) {
    int endX = baseX + (int) (radius * cos(angle));
    int endY = baseY + (int) (radius * sin(angle));

    alpha = 1 - alpha;
    stroke(0, 255 * alpha, 255 * alpha);
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

// checks and removes missile-threat collisions
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
            if (dist <= ((Missile.size + Threat.size) / 1.5)) {
                threats.remove(threat);
                missileRemoveList.add(missile);
                break;
            }
        }
    }

    for (Missile missile : missileRemoveList) {
        missiles.remove(missile);

        if (!missileScoreMap.containsKey(missile))
            continue;
        score += missileScoreMap.get(missile);
        if (score > hiscore)
            hiscore = score;
        missileScoreMap.remove(missile);
    }
}

// game over condition
void gameOver(int state) {
    fill(255);
    rect(baseX - 140, baseY - 50, 280, 100, 10);

    textAlign(CENTER);
    textSize(32);
    if (state == 1) {
        fill(0, 63, 191);
        text("You win!", baseX, baseY + 12);
    } else if (state == -1) {
        fill(255, 0, 127);
        text("You lose!", baseX, baseY + 12);
    } else {
        fill(0, 127, 63);
        text("Click to start", baseX, baseY + 12);
    }
}

// mouse press event
void mousePressed() {
    int state = getGameState();
    if (!started)
        started = true;
    else {
        if (state == 0) {
            Missile missile =
                new Missile(radius, mouseX, mouseY);
            missiles.add(missile);
            int missileScore = getScore(missile);
            if (missileScore != 0)
                missileScoreMap.put(missile, missileScore);
        }
        else
            reset();
    }
}

// calculates score to be added when missile eliminates a threat
int getScore(Missile missile) {
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
        return 0;

    float slope = tan(missile.getAngle());
    ArrayList<Threat> possibleThreats = new ArrayList<Threat>();
    for (Threat threat : threatList) {
        int threatPos[] = threat.getPosition();
        threatPos[0] -= baseX;
        threatPos[1] -= baseY;
        float dist = abs(threatPos[1] + slope * threatPos[0]);
        if (dist <= ((Missile.size + Threat.size) / 1.5))
            possibleThreats.add(threat);
    }

    if (possibleThreats.isEmpty())
        return 0;

    Threat nearestThreat = possibleThreats.get(0);
    for (Threat threat : possibleThreats) {
        if (threat == nearestThreat)
            continue;

        if (
            threat.getDistance() / threat.getSpeed() <
            nearestThreat.getDistance() / nearestThreat.getSpeed()
        )
            nearestThreat = threat;
    }

    int missilePos[] = missile.getLaunchPosition();
    int threatPos[] = nearestThreat.getPosition();
    float aimDistance =
        dist(missilePos[0], missilePos[1], threatPos[0], threatPos[1]);

    return 1 + (int) (aimDistance / 25);
}

void displayScores() {
    textAlign(LEFT);
    textSize(16);
    fill(255, 255, 255);
    text("Hi-score: " + str(hiscore), 10, 25);
    text("Score: " + str(score), 10, 50);
}
