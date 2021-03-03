/**
* A projectile class that travels linearly given the angles of which it is
* being fired and some linear speed.
* @params   loc     the location which the projectile is fired from 
* @params   p       the pan (angle of rotation about the y-axis) which 
*                   the player or the enemy is firing towards.
* @params   t       the tilt (angle or rotation about the x-axis).
* @params   speed   the linear speed of the projectile
* @params   origin  if true the projectile came from the player.
*/
public class Projectile {
  PVector start, current, velocity;
  
  // Euclidean distance (l2 norm)
  float s, distance;
  
  PShape projectile;
  boolean fromPlayer;
  
  Projectile(PVector loc, float p, float t, float speed, boolean origin) {
    start = new PVector(loc.x, loc.y, loc.z);
    current = new PVector(loc.x, loc.y, loc.z);
    s = speed;
    velocity = new PVector(cos(p), tan(t), sin(p));
    fromPlayer = origin;
    
    // Normalize vector to to unit length of 1, maintains
    // direction of vector. 
    velocity.normalize();
    
    // Move slightly ahead so projectile doesn't fill up entire screen when firing
    current.add(PVector.mult(velocity, 5));
    
    // Initializing the veloctity vector by multiplying
    // the normalized vector with the speed.
    velocity.mult(s);
    
    // Creating a projectile shape, primitive sphere
    projectile = createShape(SPHERE, 1);
    projectile.setStroke(color(255, 0, 0));
    projectile.setFill(color(255, 0, 0));
  }
  /**
  Update the position of the projectile
  */
  void update() {
    pushMatrix();
    current = current.add(velocity);
    translate(current.x, current.y, current.z);
    shape(projectile);
    popMatrix();
    
    // Make vector centered at the origin to properly measure distance
    // (can also think of it as moving the origin to the projectile's
    // starting point)
    PVector euclidean = PVector.sub(start, current);
    // SRSSR or L2 norm of the vector, essentially pythagorean
    // theorem generalized to R^n vector space.
    distance = euclidean.mag();
  }
}
