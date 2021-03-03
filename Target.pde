/**
* Target class which implements an "enemy" entity that the player
* must hit in order to progress through the rounds. Drawn as a 
* cylinder object, hence the class name Target.
* @params   position       center of the cylinder
* @params   radius         radius of the cylinder
* @params   h              height of the cylinder
* @params   img            image to be drawn on the target
* @params   enemyAgression time between each shot fired from target
* @params   deathSound     sound file played when target is hit
* @params   gunSound       sound file player when target fires projectile
*/
public class Target {
  int angle = 360;
  float[] x1 = new float[angle];
  float[] z1 = new float[angle];
  
  PVector pos;
  int r;
  int targetH;
  PImage targetImg;
  int aggression;
  SoundFile death;
  SoundFile enemyGun;
  
  boolean hit;
  PShape target;
  float rotation;
  PVector[] hitbox;
  float scale;
  int prevTime;

  Target(PVector position, int radius, int h, PImage img, int enemyAggression, SoundFile deathSound, SoundFile gunSound) {
    pos = position;
    r = radius;
    targetH = h;
    targetImg = img;
    aggression = enemyAggression;
    death = deathSound;
    enemyGun = gunSound;
    
    hit = false; 
    noStroke();
    noFill();
    
    // Group of shapes to store the geometric
    // data of multiple components
    target = createShape(GROUP);

    // Initializing coordinates of the cylinder's circle
    for (int i=0; i < angle; i++) {
      float rad = radians(i);
      float x = radius * sin(rad);
      float z = radius * cos(rad);
      x1[i] = x;
      z1[i] = z;
    }
    // Rotation about the y-axis, give variation
    // to the spawning of targets
    rotation = random(0, TWO_PI);
    hitbox = new PVector[4];

    scale = 0.1;
    
    // Initialize time of last fired shot
    prevTime = millis();
  }
  /**
  * Creates cylinder shape by sequentially setting coordinates of the top &
  * bottom circles as well as the middle quadrilateral.
  */
  void createTarget() {
    // Top of cylinder, texture allows the mapping
    // of images to the vertices of a shape.
    PShape top = createShape();
    top.beginShape();
    top.textureMode(IMAGE);
    top.texture(targetImg);
    for (int i=0; i < x1.length; i++) {
      // Figure out why adding 100 centers the image in the circle
      top.vertex(x1[i], 0, z1[i], x1[i]+100, z1[i]+100);
    }
    top.endShape(CLOSE);
    target.addChild(top);
  
    // Bottom of cylinder, separated by a value of targetH
    // in the y-axis.
    PShape bottom = createShape();
    bottom.beginShape();
    bottom.textureMode(IMAGE);
    bottom.texture(targetImg);
    for (int i=0; i < x1.length; i++) {
      bottom.vertex(x1[i], targetH, z1[i], x1[i]+100, z1[i]+100);
    }
    bottom.endShape(CLOSE);
    target.addChild(bottom);
  
    // Middle of cylinder, using the quadstrip mode
    // to create the illusion of a rectangular prism
    // wrapped around the middle of the cylinder.
    PShape middle = createShape();
    middle.beginShape(QUAD_STRIP);
    middle.textureMode(IMAGE);
    middle.texture(targetImg);
    // Connect the top and bottom circles
    for (int i=0; i < x1.length; i++) {
      stroke(255);
      middle.vertex(x1[i], 0, z1[i], x1[i]+100, z1[i]+100);
      middle.vertex(x1[i], targetH, z1[i], x1[i]+100, z1[i]+100);
    }
    middle.endShape(CLOSE);
    target.addChild(middle);
    
    // Create the hitbox of the target
    makeHitbox();
  }
  /** 
  * Create a 2D square hitbox of the target for hit detection.
  */
  void makeHitbox() {
    // Initializing a hitbox centered at the origin, orthogonal to x-axis (upright)
    float[][] topLeft = {{r}, {r}, {0}};
    float[][] topRight = {{-r}, {r}, {0}};
    float[][] bottomLeft = {{-r}, {-r}, {0}};
    float[][] bottomRight = {{+r}, {-r}, {0}};
    
    // Rotation matrix for rotation about the y-axis using the randomly
    // generated rotation angles
    float[][] rotY = {
    {cos(rotation), 0, sin(rotation)}, 
    {0, 1, 0}, 
    {-sin(rotation), 0, cos(rotation)}
    };
    
    // Rotating the vectors about the y-axis (centered at world origin) using matrix multiplication
    topLeft = matmul(rotY, topLeft);
    topRight = matmul(rotY, topRight);
    bottomLeft = matmul(rotY, bottomLeft);
    bottomRight = matmul(rotY, bottomRight);
    
    // Translating rotated vectors back to original position, the order
    // of operations is very important here. If the translation was done
    // first, the target's orbit would be too large and the rotation would
    // be overpronounced.
    PVector tL = new PVector(topLeft[0][0]*scale+pos.x, topLeft[1][0]*scale+pos.y, topLeft[2][0]*scale+pos.z);
    PVector tR = new PVector(topRight[0][0]*scale+pos.x, topRight[1][0]*scale+pos.y, topRight[2][0]*scale+pos.z);
    PVector bL = new PVector(bottomLeft[0][0]*scale+pos.x, bottomLeft[1][0]*scale+pos.y, bottomLeft[2][0]*scale+pos.z);
    PVector bR = new PVector(bottomRight[0][0]*scale+pos.x, bottomRight[1][0]*scale+pos.y, bottomRight[2][0]*scale+pos.z);
    
    // Adding each corner to the hitbox array
    hitbox[0] = tL;
    hitbox[1] = tR;
    hitbox[2] = bL;
    hitbox[3] = bR;
  
  }
  /** 
  * Drawing the target to the canvas.
  */
  void drawTarget() {
    // Only draw the target if not hit
    if (!hit) {
      pushMatrix();
      translate(pos.x, pos.y, pos.z);
      rotateX(-PI/2);
      rotateZ(rotation);
      scale(scale, scale, scale);
      shape(target);
      popMatrix();
    }

    // Draw the hitbox for testing purposes
    // beginShape();
    // for (int i=0; i < hitbox.length; i++) {
    //   vertex(hitbox[i].x, hitbox[i].y, hitbox[i].z);
    // }
    // endShape(CLOSE);
  }
  /** 
  * Hit detection of player originated projectiles using the coordinates
  * of the square hitbox. Similar to the Player class' implementation
  * of hit detection.
  */
  void checkHit(Projectile projectile) {
    PVector tL = hitbox[0];
    PVector tR = hitbox[1];
    PVector bR = hitbox[2];
    PVector bL = hitbox[3];
    
    // Current position and distance of the projectile relative to origin
    PVector bulletPos = projectile.current;
    float bulletDist = projectile.distance;
    
    // Target distance relative to starting point of projectile
    float targetDist = PVector.sub(projectile.start, pos).mag();
    
    // Found empirically  that a small allowance value for 
    // the dimensions of the hitbox were required as
    // the position updates of the projectiles tended to be imprecise
    float allowance = 5;
    
    if (abs(bulletDist - targetDist) < projectile.s+allowance
        && bulletPos.x <= max(tL.x, tR.x)+allowance 
        && bulletPos.x >= min(tL.x, tR.x)-allowance 
        && bulletPos.y <= max(tL.y, bL.y)+allowance 
        && bulletPos.y >= min(tL.y, bL.y)-allowance 
        &&  bulletPos.z <= max(tL.z, tR.z)+allowance 
        && bulletPos.z >= min(tL.z, tR.z)-allowance)  {
          hit = true;
          if (!death.isPlaying()) {
            death.play();
          }
    }
  }
  
  /** 
  * Helper method meant to return whether or not the target
  * can shoot or not.
  */
  boolean checkShoot() {
    if (millis() - prevTime > aggression) {
      prevTime = millis();
      return true;
    } else {
      return false;
    }
  }
  
  /** 
  * Returns a projectile shot from the target
  */
  Projectile shoot() {
    // Returns an angle from a point to the origin
    // Only concerned about the pan which would only involve
    // the x and z axes, not too much vertical movement so tilt
    // was not implemented. Subtracting the coordinates of the 
    // player position from the target position essnetially
    // made the player position the origin. Add PI to reverse
    // the direction that the target is shoot (would shoot away
    // from the player otherwise).
    float pan = atan2(pos.z-player.position.z, pos.x-player.position.x) + PI;
    Projectile bullet = new Projectile(pos, pan, 0, 10, false);
    if (!enemyGun.isPlaying()) {
      enemyGun.play();
    }
    return bullet;
  }
}
