/**
* A player class that inherits from the QueasyCam class. Implements attributes
* and mechanics that fit the use case of the game. Modified to constantly have
* gravity acting upon it, as well as having dimensions to allow for hitbox
* detection and object collision with Blocks.
* @params   applet        the Processing PApplet which to attach this camera instance to.
* @params   playerHealth  amount of health the player has
* @params   player
*/
class Player extends QueasyCam {
  PVector dimensions;
  PVector velocity;
  PVector gravity;
  PVector[] hitbox;
  PVector pos;
  
  SoundFile hitSound;
  
  // Orthogonal distance from center of the hitbox to its perimeter
  int r = 15;
  int scale = 1;
  boolean grounded;

  int iFrames;
  int hitTime;
  int health;
  
  Player(PApplet applet, int playerHealth, SoundFile playerHit){
    super(applet);
    speed = 0.3;
    dimensions = new PVector(5, 30, 5);
    velocity = new PVector(0, 0, 0); 
    // Positive y-value means down
    gravity = new PVector(0, 0.01, 0);
    grounded = false;
    hitbox = new PVector[4];
    // Invincibility frames, time before player can take another hit
    iFrames = 2000;
    health = playerHealth;
    hitSound = playerHit;
  }
  /**
  * Updates the player's state
  */
  void update(){
    // Update the velocity and position of the player
    velocity.add(gravity);
    position.add(velocity);
    
    // Allow for the player to jump if on a platform
    if (grounded && keyPressed && key == ' '){
      grounded = false;
      velocity.y = -0.5;
      position.y -= 0.1;
    }
    // Kills the player if they fall off the platform
    if (position.y > 1500) {
      health = 0;
    }
    makeHitbox();
  }
  /**
  * Creates the player's hitbox to detect hits from enemy projectiles
  */
  void makeHitbox() {
    // Initializing a hitbox centered at the origin, orthogonal to x-axis (upright)
    float[][] topLeft = {{r}, {r}, {0}};
    float[][] topRight = {{-r}, {r}, {0}};
    float[][] bottomLeft = {{-r}, {-r}, {0}};
    float[][] bottomRight = {{+r}, {-r}, {0}};
    
    // Rotation matrix for rotation about the y-axis
    float[][] rotY = {
    {cos(pan), 0, sin(pan)}, 
    {0, 1, 0}, 
    {-sin(pan), 0, cos(pan)}
    };
    
    // Rotating vectors about the y-axis (centered at world origin) using matrix multiplication
    topLeft = matmul(rotY, topLeft);
    topRight = matmul(rotY, topRight);
    bottomLeft = matmul(rotY, bottomLeft);
    bottomRight = matmul(rotY, bottomRight);
    
    // Translating rotated vectors back to original position
    PVector tL = new PVector(topLeft[0][0]*scale+position.x, topLeft[1][0]*scale+position.y, topLeft[2][0]*scale+position.z);
    PVector tR = new PVector(topRight[0][0]*scale+position.x, topRight[1][0]*scale+position.y, topRight[2][0]*scale+position.z);
    PVector bL = new PVector(bottomLeft[0][0]*scale+position.x, bottomLeft[1][0]*scale+position.y, bottomLeft[2][0]*scale+position.z);
    PVector bR = new PVector(bottomRight[0][0]*scale+position.x, bottomRight[1][0]*scale+position.y, bottomRight[2][0]*scale+position.z);
    
    // Adding each corner to the hitbox array
    hitbox[0] = tL;
    hitbox[1] = tR;
    hitbox[2] = bL;
    hitbox[3] = bR;
  }
  /**
  * Check if player is hit by enemy projectile. Originally wanted to implement this
  * method in a base hittable object class or interface but Java doesn't allow for
  * multiple inheritance or inheritance from both an interface and a superclass.
  */
  void checkHit(Projectile projectile) {
    // Coordinates if the hitbox's vertices
    PVector tL = hitbox[0];
    PVector tR = hitbox[1];
    PVector bR = hitbox[2];
    PVector bL = hitbox[3];
    
    // Current position and distance of the projectile relative to its starting point
    PVector bulletPos = projectile.current;
    float bulletDist = projectile.distance;
    
    // Target distance relative to starting point of projectile
    float targetDist = PVector.sub(projectile.start, position).mag();
    
    // Player is large enough and enemies shoot slow enough that
    // an allowance value is not needed to allow more leeway with
    // the player's hitdetection.
    float allowance = 0;
    
    // Checking if the distance between the target and the projectile is less than some
    // threshold (the bullet's rate of change plus the allowance) as well as if its
    // coordinates lies between the intervals defined by the corners of the hitbox.
    // Also a hit will only be registered once the iFrames period has passed (so the
    // player doesn't die too quickly).
    if (abs(bulletDist - targetDist) < projectile.s+allowance
        && bulletPos.x <= max(tL.x, tR.x)+allowance 
        && bulletPos.x >= min(tL.x, tR.x)-allowance 
        && bulletPos.y <= max(tL.y, bL.y)+allowance 
        && bulletPos.y >= min(tL.y, bL.y)-allowance 
        && bulletPos.z <= max(tL.z, tR.z)+allowance 
        && bulletPos.z >= min(tL.z, tR.z)-allowance
        && hitTime + iFrames < millis())  {
          hitTime = millis();
          // Would allow for extending to different damage values (default to 10 for now)
          health = max(0, health-10);
          if (!hitSound.isPlaying()) {
            hitSound.play();
          }
    }
  }
}
