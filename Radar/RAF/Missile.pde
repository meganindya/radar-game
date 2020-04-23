class Missile {
    static final float speed = 3, size = 2.5;
    private float angle, dist;
    private int posX, posY, detectableRange;

    Missile(int radius, int posX, int posY) {
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

    void render() {
        noStroke();
        fill(0, 0, 255);
        ellipse(posX, posY, size, size);
    }

    void updatePosition() {
        dist += speed;
        posX = radius + (int) (dist * cos(angle));
        posY = radius - (int) (dist * sin(angle));
    }

    boolean outOfBounds() {
        return dist >= detectableRange ? true : false;
    }

    float getAngle() {
        return angle;
    }

    int[] getPosition() {
        return new int[]{ posX, posY };
    }
}
