import ddf.minim.*;

public PartSystem ps;
public float stickiness = .1;
public boolean sticky = true;
public float viscosity = 3;

public Minim minim;
public PShader shader;

public void setup()
{
  size(640,480,P3D);
  background(0);
  noSmooth();
  surface.setResizable(true);
  
  minim = new Minim(this);
  shader = loadShader("frag.glsl","vert.glsl");
  
  //surface.setIcon(createImage(1,1,ARGB));
  ps = new PartSystem(Part.radius*2+1,3);
  for(int i=0;i<5000;i++) {
    ps.add(new Part(random(0,width),random(0,height)));
  }
}

public void keyPressed()
{
  switch(key) {
    case 'c':
      //ps.clear();
    break;
    case 's':
      for(Part part : ps) {
        part.px = part.x;
        part.py = part.y;
      }
    break;
    case 'f':
      for(Part part : ps) {
        part.heat += -.1;
      }
      //sticky = !sticky;
    break;
    case 'b':
      for(Part part : ps) {
        part.heat += .1;
      }
    break;
    case 'n':
      for(Part part : ps) {
        part.heat = 0;
      }
    break;
    case ' ':
      ps.toggleTime();
    break;
    case 'j':
      ps.jojomode = true;
      ps.toggleTime();
      ps.jojomode = false;
    break;
  }
}

public void draw()
{
  stickiness += (.3*(sticky?1:-1)-stickiness)*.001;
  background(0);
  try {
    ps.handle();
  } catch(Exception e) {}
  if(mousePressed) {
    if(mouseButton==CENTER) {
      float vx = (mouseX - pmouseX)*.2;
      float vy = (mouseY - pmouseY)*.2;
      for(int i=0;i<20;i++) {
        float angle = random(0,TWO_PI);
        float range = sqrt(random(0,1))*50;
        Part part = new Part(
          mouseX+sin(angle)*range,
          mouseY+cos(angle)*range,
          vx,vy
        );
        ps.add(part);
      }
    } else {
      float dh = (mouseButton==LEFT?1:-1)*(
        (keyPressed && key=='e')?1:
        (keyPressed && key=='r')?1e3:1e-1);
      for(Part part : ps) {
        float dx = part.x - mouseX;
        float dy = part.y - mouseY;
        if(dx*dx+dy*dy<1600) {
          part.heat += dh;
        }
      }
    }
  }
  fill(255);
  textAlign(LEFT,TOP);
  text("Particles: "+ps.size(),4,4);
  surface.setTitle("FPS: "+frameRate);
}
