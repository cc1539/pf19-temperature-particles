
public class Part
{
  final public static float radius = 3;
  public float x;
  public float y;
  public float px;
  public float py;
  public int index;
  public float heat;
  
  public Part(float x, float y, float vx, float vy)
  {
    this.x = x;
    this.y = y;
    px = x - vx;
    py = y - vy;
  }
  
  public Part(float x, float y)
  {
    this(x,y,0,0);
  }
  
  public void move()
  {
    x += -px + (px=x);
    y += -py + (py=y) + 1e-2;
  }
  
  public void draw()
  {
    /*
    final int length = 4;
    line(x,y-length,x,y+length);
    line(x-length,y,x+length,y);
    */
    float vx = x-px;
    float vy = y-py;
    float speed = (vx*vx+vy*vy);
    colorMode(HSB);
    //color rgb = color(160-sin(speed/60)*20,255-speed,255);
    color rgb = color(heat>0?0:127,abs(heat)*255,255);
    /*
    if(abs(x-px)>1||abs(y-py)>1) {
      stroke(rgb);
      line(x,y,px,py);
    } else {
      noStroke();
      fill(rgb);
      rect(x,y,1,1);
    }
    */
    noStroke();
    fill(rgb);
    rectMode(CENTER);
    //float length = radius*2;
    float length = 2;
    rect(x,y,length,length);
    colorMode(RGB);
  }
  
  public void interact(Part part)
  {
    float dx = x - part.x;
    float dy = y - part.y;
    if(!(dx==0 && dy==0)) {
      float dot = dx*dx+dy*dy;
      if(dot<radius*radius*4) {
        float liquid_range = .3;
        float trans_range = 1;
        float lo_str = .005;
        float hi_str = .5;
        float em_str = 0;
        if(abs(heat)<trans_range) {
          if(abs(heat)<liquid_range) {
            em_str = lo_str;
          } else {
            float l = (abs(heat)-liquid_range)/(trans_range-liquid_range);
            em_str = lo_str*(1-l)+hi_str*l;
          }
        } else {
          em_str = hi_str;
        }
        float force = min(max((1-(radius*2+max(-radius/3,heat))/sqrt(dot)) * em_str,-.2),.1);
        dx *= force;
        dy *= force;
        x -= dx;
        y -= dy;
        part.x += dx;
        part.y += dy;
        
        float dh = heat - part.heat;
        float rate = .5;
        heat -= dh*rate;
        part.heat += dh*rate;
        
      }
    }
  }
  
}