import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import java.util.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class RadarGame extends PApplet {



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
final int missileMax = 5;
boolean baseDestroyed;

boolean started = false;

int score, hiscore = 0, penalty;
HashMap<Missile, Integer> missileScoreMap;


// Methods
// -------

public void setup() {
    
    frameRate(fps);

    reset();
}

public void reset() {
    swipeAngle = 0;
    swipeSpeed = 0.01f;

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
    penalty = 0;
    missileScoreMap = new HashMap<Missile, Integer>();
}

public void draw() {
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
            if (score > 0) {
                score--;
                penalty--;
            }
            continue;
        }
        missile.render();
        missile.updatePosition();
    }
    for (Missile missile : missileRemoveList)
        missiles.remove(missile);
}

// redraws the canvas
public void refreshCanvas() {
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
        drawRadarLine(swipeAngle - i * 0.05f * PI / 180, (float) i / 100);
    swipeAngle = (swipeAngle + swipeSpeed) % TWO_PI;

    // base
    noStroke();
    fill(0, 255, 255);
    ellipse(baseX, baseY, 10, 10);
}

// draws the swipe effect
public void drawRadarLine(float angle, float alpha) {
    int endX = baseX + (int) (radius * cos(angle));
    int endY = baseY + (int) (radius * sin(angle));

    alpha = 1 - alpha;
    stroke(0, 255 * alpha, 255 * alpha);
    line(baseX, baseY, endX, endY);
}

// check if game is running, won, or over
public int getGameState() {
    if (threats.isEmpty())
        return 1;
    if (baseDestroyed)
        return -1;
    return 0;
}

// checks and removes missile-threat collisions
public void checkMissileCollisions() {
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
            if (dist <= ((Missile.size + Threat.size) / 1.5f)) {
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
        if (penalty > 0) {
            if (score < penalty) {
                score = 0;
                penalty -= score;
            } else {
                score -= penalty;
                penalty = 0;
            }
        }
        missileScoreMap.remove(missile);
    }
}

// game over condition
public void gameOver(int state) {
    fill(255);
    rect(baseX - 140, baseY - 50, 280, 100, 10);

    textAlign(CENTER);
    textSize(32);
    if (state == 1) {
        fill(0, 63, 191);
        text("You win!", baseX, baseY + 12);
    } else if (state == -1) {
        if (penalty > 0)
            score = score > penalty ? score - penalty : 0;
        fill(255, 0, 127);
        text("You lose!", baseX, baseY + 12);
    } else {
        fill(0, 127, 63);
        text("Click to start", baseX, baseY + 12);
    }

    if (state == 1 || state == -1) {
        hiscore = max(hiscore, score);
        displayScores();
    }
}

// mouse press event
public void mousePressed() {
    int state = getGameState();
    if (!started)
        started = true;
    else {
        if (state == 0) {
            if (missiles.size() < missileMax) {
                Missile missile =
                    new Missile(radius, mouseX, mouseY);
                missiles.add(missile);
                int missileScore = getScore(missile);
                missileScoreMap.put(missile, missileScore);
                if (missileScore == 0)
                    penalty++;
            }
        }
        else
            reset();
    }
}

// calculates score to be added when missile eliminates a threat
public int getScore(Missile missile) {
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
        if (dist <= ((Missile.size + Threat.size) / 1.5f))
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

public void displayScores() {
    noStroke();
    fill(0);
    rect(0,0,120,60);
    textAlign(LEFT);
    textSize(16);
    fill(255, 255, 255);
    text("Hi-score: " + str(hiscore), 10, 25);
    text("Score: " + str(score), 10, 50);
}
class Missile {
    static final float speed = 3, size = 3;
    private float angle, dist;
    private int launchX, launchY, posX, posY, detectableRange, id;

    Missile(int radius, int posX, int posY) {
        launchX = posX;
        launchY = posY;

        posX -= radius;
        posY -= radius;
        angle = atan((float) -posY / (float) posX);
        if (posX < 0)
            angle += PI;
        else if (posX > 0 && -posY < 0)
            angle += TWO_PI;

        dist = 0;
        this.posX = 0;
        this.posY = 0;
        detectableRange = radius;
    }

    public void render() {
        stroke(255, 255, 0);
        fill(0, 255, 63);
        ellipse(posX, posY, size, size);
    }

    public void updatePosition() {
        dist += speed;
        posX = radius + (int) (dist * cos(angle));
        posY = radius - (int) (dist * sin(angle));
    }

    public boolean outOfBounds() {
        return dist >= detectableRange ? true : false;
    }

    public float getAngle() {
        return angle;
    }

    public int[] getPosition() {
        return new int[]{ posX, posY };
    }

    public int[] getLaunchPosition() {
        return new int[]{ launchX, launchY };
    }
}
class Threat {
    static final float minSpeed = 0.3f, maxSpeed = 0.6f, size = 6;
    private float angle, speed, dist;
    private int posX, posY;

    Threat(int radius) {
        angle = random(0, TWO_PI);
        speed = random(minSpeed, maxSpeed);
        dist  = random(radius - 50, radius - 5);

        posX = radius + (int) (dist * cos(angle));
        posY = radius - (int) (dist * sin(angle));
    }

    public void render() {
        noStroke();
        fill(255, 0, 0);
        ellipse(posX, posY, size, size);
    }

    public void updatePosition() {
        dist -= speed;
        posX = radius + (int) (dist * cos(angle));
        posY = radius - (int) (dist * sin(angle));
    }

    public boolean reachedBase() {
        return (dist - size / 2) < 5 ? true : false;
    }

    public float getAngle() {
        return angle;
    }

    public int[] getPosition() {
        return new int[]{ posX, posY };
    }

    public float getDistance() {
        return dist;
    }

    public float getSpeed() {
        return speed;
    }
}
  public void settings() {  size(600, 600); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "RadarGame" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
