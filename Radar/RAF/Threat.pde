class Threat {
    static final float minSpeed = 0.3, maxSpeed = 0.6, size = 5;
    private float angle, speed, dist;
    private int posX, posY;

    Threat(int radius) {
        angle = random(0, TWO_PI);
        speed = random(minSpeed, maxSpeed);
        dist  = random(radius - 50, radius - 5);

        posX = radius + (int) (dist * cos(angle));
        posY = radius + (int) (dist * sin(angle));
    }

    void render() {
        noStroke();
        fill(255, 0, 0);
        ellipse(posX, posY, size, size);
    }

    void updatePosition() {
        dist -= speed;
        posX = radius + (int) (dist * cos(angle));
        posY = radius + (int) (dist * sin(angle));
    }

    boolean reachedBase() {
        return (dist - size / 2) < 5 ? true : false;
    }

    float getAngle() {
        return angle;
    }

    int[] getPosition() {
        return new int[]{ posX, posY };
    }
}
