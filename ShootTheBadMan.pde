/** --Shoot The Bad Man--
   A 3D first person shooter inspired by the greatest game ever
   to grace the earth, Among Us. The game works through round
   based survival where enemies will randomly appear at the
   start of each round and the player must wipe them all out
   in order to progress. Be careful though, these enemies
   like to fight back any they get more numerous as the 
   round progress.
*/

import processing.sound.*;
import queasycam.*;

// First person camera
Player player;

// Sound files
SoundFile playerGun;
SoundFile enemyGun;
SoundFile badManDeath;
SoundFile startMenu;
SoundFile roundChange;
SoundFile playerHit;

// Image to display on the targets/enemies
PImage badManImg;

// Array to store targets on the screen
ArrayList<Target> enemies = new ArrayList<Target>();

// List to store player shot projectiles
ArrayList<Projectile> playerShots = new ArrayList<Projectile>();

// List to store enemy shot projectiles
ArrayList<Projectile> enemyShots = new ArrayList<Projectile>();

// Global configs
int maxBulletDist = 3000;
int round = 0;
int aggression = 3000;
int playerHealth = 100;
int score = 0;

// Whether game is ended or not
boolean end = false;

// Whether the application has been just started
boolean start = true;

// The time when a round ends
int roundEnd = millis();

// HUD elements
PImage redCross;

// Death screen image
PImage amogusDrip;

void setup() {
  size(displayWidth, displayHeight, P3D);
  // Change the second param to change the screen number
  //fullScreen(P3D, 1);
  frameRate(120);
  noCursor();
  
  // Load images
  badManImg = loadImage("whentheimposterissus.jpg");
  redCross = loadImage("red_cross.png");
  amogusDrip = loadImage("amogus_drip.jpeg");
  
  // Load soundfiles
  playerGun = new SoundFile(this, "ak47.wav");
  enemyGun = new SoundFile(this, "m4.wav");
  badManDeath = new SoundFile(this, "amogus.wav");
  startMenu = new SoundFile(this, "main_menu.wav");
  roundChange = new SoundFile(this, "round_change.wav");
  playerHit = new SoundFile(this, "player_hit.wav");
  
  // Initialize player camera and adjust settings
  player = new Player(this, playerHealth, playerHit);
  player.position = new PVector(0, 500, 0);
  player.sensitivity = 0.4;
  
  // Loop main game music
  startMenu.loop();
}

void draw() {
  background(0);
  
  // Starting/Help screen
  if (keyPressed && key == 'h' || start == true) {
    start = true;
    helpScreen();

  // End screen
  }else if (player.health == 0) {
    end = true;
    endScreen();

  // Main game
  } else if (!end) {
    Block arena = new Block(0, 520, 0, 1000, 20, 1000);
    arena.update();
    arena.display();
    player.update();
    playerCheckHit();
    checkRoundChange();
    updateEnemies();
    updateProjectiles(playerShots);
    updateProjectiles(enemyShots);
    drawHUD();
  }
}

/**
* Create and initialize enemies, appending them to the
* global enemies list. The number of enemies is determined
* by the round (round 1 there is 1 enemy, round 2 there are 2 etc.)
*/
void makeEnemies(int num) {
  for (int i=0; i < num; i++){
    float x = random(-500, 500);
    float z = random(-500, 500);
    PVector targetLoc = new PVector(x, 500, z);
    Target badMan = new Target(targetLoc, 100, 10, badManImg, aggression, badManDeath, enemyGun);
    badMan.createTarget();
    enemies.add(badMan); 
  }
}

/** 
* Update the state of projectiles according to their velocity
* and if they hit an object
*/
void updateProjectiles(ArrayList<Projectile> projectilesList) {
  for (int i=0; i < projectilesList.size(); i++) {
    Projectile bullet = projectilesList.get(i);
    bullet.update();
    float vec = bullet.distance;
    if (vec >= maxBulletDist) {
      projectilesList.remove(i);
    }
  }
}

/**
* Determines when to change rounds. 
*/
void checkRoundChange() {
  // Record the time which the round ended if all enemies are
  // hit and if a previous time has not yet been recorded
  if (enemies.size() == 0 && roundEnd == 0 || round == 0) {
    roundEnd = millis();
    round += 1;
    // Restore player health every 10 rounds
    if (round % 10 == 0) {
      player.health = 100;
    }
    // Round change music
    if (!roundChange.isPlaying()) {
      roundChange.play();
    }
  }
  // Create new wave of enemies if 5 seconds have passed
  // Reset the round end time
  if (enemies.size() == 0 && millis() - roundEnd > 5000) {
    makeEnemies(round);
    roundEnd = 0;
  }
}

/**
*Iterate through every enemy orginated projectile and check if
*player is hit 
*/
void playerCheckHit() {
  for (int i=0; i < enemyShots.size(); i++) {
    player.checkHit(enemyShots.get(i));
  }
}

/**
* Updates the state of enemy entities. Draws enemies, removes them if hit
* and enable them to shoot back at the player.   
*/
void updateEnemies() {  
  // Iterate through global list of enemy objects
  for (int i=0; i < enemies.size(); i++) {
    Target badMan = enemies.get(i);
    badMan.drawTarget();
    // Check if enemy can shoot (they have a cooldown), if so shoot at player
    if (badMan.checkShoot()) {
      Projectile enemyShot = badMan.shoot();
      enemyShots.add(enemyShot);
    }
    // Iterate through player originated projectiles and check if the 
    // enemy is hit
    for (int j=0; j < playerShots.size(); j++) {
      Projectile bullet = playerShots.get(j);
      badMan.checkHit(bullet);
      if (badMan.hit) {
        enemies.remove(i);
        playerShots.remove(j);
        score += 100;
        break;
      }
    }
  }
}

/** 
* A HUD (heads-up-display) containing various quality of life information
* or the player. Displays the health, current score, and current round. 
*/
void drawHUD() {  
  // Reset camera to origin
  camera();
  
  // DISABLE_DEPTH_TEST allows us to draw 2D sketches ontop of a 3D backdrop
  hint(DISABLE_DEPTH_TEST);
  
  // Creating crosshair
  fill(0, 255, 0);
  stroke(0, 255, 0);
  PShape cross = createShape(GROUP);
  PShape vertical = createShape(LINE, width/2, height/2+10, width/2, height/2-10);
  PShape horizontal = createShape(LINE, width/2-10, height/2, width/2+10, height/2);
  cross.addChild(vertical);
  cross.addChild(horizontal);
  shape(cross);
  
  // Displaying health and health icon
  pushMatrix();
  scale(0.15);
  image(redCross, (width - width/8)* 7, 100);
  popMatrix();
  String h = Integer.toString(player.health);
  text(h, width - width/20, 50);
  textSize(36);
  
  // Displaying round number
  String r = "Round " + Integer.toString(round);
  stroke(255);
  fill(255);
  textSize(36);
  text(r, width/2-75, 50);
  
  // Displaying score
  String s = "Score " + Integer.toString(score);
  textSize(36);
  text(s, 10, 50);

  // Revert back to 3D mode
  hint(ENABLE_DEPTH_TEST);
}

/** 
* Create an end screen for when the player dies   
*/
void endScreen() {
  // Reset the camera to the origin
  camera();
  
  // Make camera uncontrollable
  player.controllable = false;
  
  hint(DISABLE_DEPTH_TEST);
  
  // End screen backdrop
  fill(200);
  stroke(0);
  rectMode(CENTER);
  rect(width/2, height/2, 900, 1000);
  
  // Death card
  String youDied = "YOU DIED";
  stroke(255);
  fill(255);
  textSize(36);
  text(youDied, width/2-75, 100);
  
  // Score at time of death
  String s = "Score: " + Integer.toString(score);
  text(s, width/2-60, 200);
  
  // Rounds survived
  String r = "Rounds Survived: " + Integer.toString(round);
  text(r, width/2-150, 300);
  
  // Instructions to reset
  String restart = "Press 'r' to try again";
  text(restart, width/2-150, 400);
  
  // Instructions to exit
  String exitS = "Press 'q' to exit";
  text(exitS, width/2-120, 500);
  
  // Death screen image
  scale(0.6);
  image(amogusDrip, width/2+amogusDrip.width/2, 875);
  
  if (keyPressed && key == 'r') {
    restart();
  }
  if (keyPressed && key == 'q') {
    exit();
  }
  
  hint(ENABLE_DEPTH_TEST);
}

/**
* How to screen detailing the main premise of the game as well
* as the basic controls. Also acts as a pause/start menu.
*/
void helpScreen() {
  camera();
  hint(DISABLE_DEPTH_TEST);
  player.controllable = false;
  fill(200);
  stroke(0);
  rectMode(CENTER);
  rect(width/2, height/2, 1700, 1000);
  
  stroke(255);
  fill(255);
  textSize(36);
  
  // Basic instructions on how to play, objective of the game
  String gameTitle = "Shoot The Bad Man";
  text(gameTitle, width/2-125, 100);
  
  String title = "How To Play";
  text(title, width/2-75, 200);
  
  String movement = "WASD to move, press Space to jump, use mouse to look around";
  text(movement, width/2-500, height/2-100);
  
  String goal = "Left-click to shoot projectiles. Survive as long as you can. Your health will reset every 10 rounds";
  text(goal, width/2-820, height/2);
  
  String help = "Press 'h' at anytime to access this screen";
  text(help, width/2-300, height/2+100);
  
  String toStart = "Press enter to start";
  text(toStart, width/2-150, height/2+200);
  
  String toExit = "Press escape to exit";
  text(toExit, width/2-150, height/2+300);
  
  // Start/resume the game if player presses enter
  if (keyPressed && key == '\n') {
    start = false;
    player.controllable = true;
  }
  
  hint(ENABLE_DEPTH_TEST);
}

/** 
* Reset the state of the game. Revert global variables as well as clear all entities.
*/
void restart() {
  end = false;
  player.health = 100;
  round = 0;
  roundEnd = 0;
  score = 0;
  player.position = new PVector(0, 500, 0);
  player.controllable = true;
  
  for (int i=0; i < enemies.size(); i++) {
    enemies.remove(i);
  }
  
  for (int i=0; i < enemyShots.size(); i++) {
    enemyShots.remove(i);
  }
}

/**
* Returns a two dimensional matrix containing the product of two valid matrices.
* Handles errors regarding mismatched shapes of matrices. Implemented for usage
* of transforming objects in R3 vector space.
*
* @param  matA  the first matrix in the matrix multiplication
* @param  matB  the second matrix in the matrix multiplication
* @return       the product of the two matrices
*/
float[][] matmul(float[][] matA, float[][] matB) {
  int colA = matA[0].length;
  int rowA = matA.length;
  int colB = matB[0].length;
  int rowB = matB.length;
  
  // Error checking for mismmatched shapes
  try {
    assert rowB == colA;
  } catch (Exception e) {
    throw new AssertionError();
  }
  
  // The resulting matrix
  float[][] res = new float[rowA][colB];
  
  // Simple O(n^3) algorithm for calculating matrix multiplcation
  for (int i=0; i < rowA; i++) {
    for (int j=0; j < colB; j++) {
      int sum = 0;
      for (int k=0; k < colA; k++) {
        sum += matA[i][k] * matB[k][j];
      }
      res[i][j] = sum;
    }
  } 
  return res;
}

/** 
* Instantiates player originated projectiles when a mouse has been clicked.
*/
void mousePressed() {
  // Semi automatic
  PVector currentLocation = player.position;
  
  // Rotation along vertical axis
  float camPan = player.pan;
    
  // Rotation along horizontal axis
  float camTilt = player.tilt; 
  
  Projectile bullet = new Projectile(currentLocation, camPan, camTilt, 30, true);
  playerShots.add(bullet);
  
  // Gun FX
  if (!playerGun.isPlaying()){
    playerGun.play();
  }
}
