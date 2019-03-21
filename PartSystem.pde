
public class PartSystem extends ArrayList<Part>
{
  private boolean time_running = true;
  private int[][] sd_data; // spatial division
  private float sd_cell_length;
  private float[][][] fluid_data;
  private float fluid_cell_length;
  
  private AudioPlayer timestop_sfx;
  private AudioPlayer timestart_sfx;
  private float timestop_timer;
  private boolean jojomode;
  
  public PartSystem(float sd_cell_length, float fluid_cell_length)
  {
    this.sd_cell_length = sd_cell_length;
    this.fluid_cell_length = fluid_cell_length;
    timestop_sfx = minim.loadFile("stop.mp3");
    timestart_sfx = minim.loadFile("resume.mp3");
  }
  
  public PartSystem(float sd_cell_length)
  {
    this(sd_cell_length,sd_cell_length/2);
  }
  
  public void toggleTime()
  {
    time_running = !time_running;
    if(!time_running && jojomode) {
      // time has stopped...
      timestop_sfx.play(0);
      timestop_timer = 100;
      shader.set("pointer",(float)mouseX,(float)mouseY);
      shader.set("image",g.get());
    } else if(jojomode) {
      timestart_sfx.play(0);
    }
  }
  
  private void updateDimensions(float width, float height)
  {
    {
      int grid_w = (int)(width/sd_cell_length)+1;
      int grid_h = (int)(height/sd_cell_length)+1;
      if(sd_data==null || sd_data.length!=grid_w || sd_data[0].length!=grid_h) {
        sd_data = new int[grid_w][grid_h];
      }
    }
    {
      int grid_w = (int)(width/fluid_cell_length)+3;
      int grid_h = (int)(height/fluid_cell_length)+3;
      if(fluid_data==null || fluid_data.length!=grid_w || fluid_data[0].length!=grid_h) {
        fluid_data = new float[grid_w][grid_h][3];
      }
    }
  }
  
  private void quickSortByIndex(int last, int next)
  {
    if(next-last>0) {
      int old_last = last;
      int old_next = next;
      int pivot = get((next+last)/2).index;
      while(next-last>0) {
        while(get(last).index<pivot) last++;
        while(get(next).index>pivot) next--;
        
        Part tmp = get(last);
        set(last,get(next));
        set(next,tmp);
        
        last++;
        next--;
      }
      quickSortByIndex(old_last,next);
      quickSortByIndex(last,old_next);
    }
  }
  
  private void sortByIndex()
  {
    for(Part part : this) {
      part.index = (int)(part.x/sd_cell_length)+((int)(part.y/sd_cell_length)*sd_data.length);
    }
    quickSortByIndex(0,size()-1);
  }
  
  public void updateSpatialDivisionData()
  {
    int last_index = -1;
    int section_head = 0;
    for(int x=0;x<sd_data.length;x++)
    for(int y=0;y<sd_data[0].length;y++)
    {
      sd_data[x][y] = -1;
    }
    for(int i=0;i<size();i++) {
      if(last_index!=(last_index=get(i).index)) {
        section_head = i;
        sd_data[last_index%sd_data.length][last_index/sd_data.length] = section_head;
      }
    }
  }
  
  public void moveParts()
  {
    for(Part part : this) {
      part.move();
    }
  }
  
  public void draw()
  {
    stroke(255);
    strokeWeight(1);
    for(Part part : this) {
      part.draw();
    }
    drawMesh();
    if(timestop_timer>0) {
      if(time_running) {
        timestop_timer = 0;
      } else {
        timestop_timer--;
        //shader.set("image",g.get());
        shader.set("res",(float)width,(float)height);
        shader.set("time",100-timestop_timer);
        shader(shader);
        rect(0,0,width*2,height*2);
        resetShader();
      }
    }
  }
  
  public void drawMesh()
  {
    stroke(31);
    final float threshold = .0625;
    for(int x=0;x<fluid_data.length-1;x++)
    for(int y=0;y<fluid_data[0].length-1;y++)
    {
      ArrayList<float[]> vertices = new ArrayList<float[]>();
      { float l=(threshold-fluid_data[x  ][y  ][2])/(fluid_data[x+1][y  ][2]-fluid_data[x  ][y  ][2]); if(l>=0&&l<=1) { vertices.add(new float[]{(x+l  )*fluid_cell_length, y     *fluid_cell_length}); }}
      { float l=(threshold-fluid_data[x+1][y  ][2])/(fluid_data[x+1][y+1][2]-fluid_data[x+1][y  ][2]); if(l>=0&&l<=1) { vertices.add(new float[]{(x+1  )*fluid_cell_length,(y+l  )*fluid_cell_length}); }}
      { float l=(threshold-fluid_data[x+1][y+1][2])/(fluid_data[x  ][y+1][2]-fluid_data[x+1][y+1][2]); if(l>=0&&l<=1) { vertices.add(new float[]{(x+1-l)*fluid_cell_length,(y+1  )*fluid_cell_length}); }}
      { float l=(threshold-fluid_data[x  ][y+1][2])/(fluid_data[x  ][y  ][2]-fluid_data[x  ][y+1][2]); if(l>=0&&l<=1) { vertices.add(new float[]{ x     *fluid_cell_length,(y+1-l)*fluid_cell_length}); }}
      if(vertices.size()%2==0) {
        for(int i=0;i<vertices.size();i+=2) {
          float[] p0 = vertices.get(i);
          float[] p1 = vertices.get(i+1);
          line(p0[0]-fluid_cell_length,p0[1]-fluid_cell_length,p1[0]-fluid_cell_length,p1[1]-fluid_cell_length);
        }
      }
    }
  }
  
  public void applyContactPhysics()
  {
    sortByIndex();
    updateSpatialDivisionData();
    for(Part part : this) {
      int grid_x = (int)(part.x/sd_cell_length);
      int grid_y = (int)(part.y/sd_cell_length);
      for(int i=-1;i<=1;i++)
      for(int j=-1;j<=1;j++)
      {
        int u = grid_x+i; if(u<0||u>=sd_data.length) continue;
        int v = grid_y+j; if(v<0||v>=sd_data[0].length) continue;
        int index = sd_data[u][v];
        if(index!=-1) {
          for(int k=index;k<size()&&get(k).index==get(sd_data[u][v]).index;k++) {
            part.interact(get(k));
          }
        }
      }
    }
    
    // the brute-force version
    /*
    for(int i=0;i<size();i++)
    for(int j=i+1;j<size();j++)
    {
      get(i).interact(get(j));
    }
    */
  }
  
  private void projectPartsToGrid()
  {
    for(int x=0;x<fluid_data.length;x++)
    for(int y=0;y<fluid_data[0].length;y++)
    {
      fluid_data[x][y][0] = 0; // x-velocity
      fluid_data[x][y][1] = 0; // y-velocity
      fluid_data[x][y][2] = 0; // pressure
    }
    for(Part part : this) {
      float lx=part.x/fluid_cell_length+1; int gx=(int)lx; lx-=gx;
      float ly=part.y/fluid_cell_length+1; int gy=(int)ly; ly-=gy;
      float x0y0 = (1-lx)*(1-ly);
      float x1y0 = lx*(1-ly);
      float x0y1 = (1-lx)*ly;
      float x1y1 = lx*ly;
      float[] properties = new float[]{part.x-part.px,part.y-part.py,1};
      for(int i=0;i<fluid_data[0][0].length;i++) {
        fluid_data[gx][gy][i] += x0y0*properties[i];
        fluid_data[gx+1][gy][i] += x1y0*properties[i];
        fluid_data[gx][gy+1][i] += x0y1*properties[i];
        fluid_data[gx+1][gy+1][i] += x1y1*properties[i];
      }
    }
  }
  
  private void blurPressure()
  {
    float[][] buffer = new float[fluid_data.length][fluid_data[0].length];
    for(int x=0;x<fluid_data.length;x++)
    for(int y=0;y<fluid_data[0].length;y++)
    {
      int neighbors = 0;
      for(int i=-1;i<=1;i++)
      for(int j=-1;j<=1;j++)
      {
        int u=x+i;if(u<0||u>=fluid_data.length) continue;
        int v=y+j;if(v<0||v>=fluid_data[0].length) continue;
        neighbors++;
        buffer[x][y] += fluid_data[u][v][2];
      }
      buffer[x][y]/=neighbors;
    }
    for(int x=0;x<fluid_data.length;x++)
    for(int y=0;y<fluid_data[0].length;y++)
    {
      fluid_data[x][y][2] = buffer[x][y];
    }
  }
  
  private void normalizeVelocities()
  {
    for(int x=0;x<fluid_data.length;x++)
    for(int y=0;y<fluid_data[0].length;y++)
    {
      if(fluid_data[x][y][2]!=0) {
        fluid_data[x][y][0] /= fluid_data[x][y][2];
        fluid_data[x][y][1] /= fluid_data[x][y][2];
      }
    }
  }
  
  private void applyPressureForce()
  {
    blurPressure();
    for(int x=0;x<fluid_data.length;x++)
    for(int y=0;y<fluid_data[0].length;y++)
    {
      float dx_1y0 = x-1>=0?fluid_data[x-1][y][2]:0;
      float dx0y_1 = y-1>=0?fluid_data[x][y-1][2]:0;
      float dx1y0 = x+1<fluid_data.length?fluid_data[x+1][y][2]:0;
      float dx0y1 = y+1<fluid_data[0].length?fluid_data[x][y+1][2]:0;
      fluid_data[x][y][0] += (dx_1y0-dx1y0)*(fluid_data[x][y][2]-.2);
      fluid_data[x][y][1] += (dx0y_1-dx0y1)*(fluid_data[x][y][2]-.2);
    }
  }
  
  private void projectGridToParts()
  {
    for(Part part : this) {
      if(abs(part.heat)<.3) {
        float lx=part.x/fluid_cell_length+1; int gx=(int)lx; lx-=gx;
        float ly=part.y/fluid_cell_length+1; int gy=(int)ly; ly-=gy;
        float x0y0 = (1-lx)*(1-ly);
        float x1y0 = lx*(1-ly);
        float x0y1 = (1-lx)*ly;
        float x1y1 = lx*ly;
        part.px = part.x-(
          fluid_data[gx][gy][0]*x0y0+
          fluid_data[gx+1][gy][0]*x1y0+
          fluid_data[gx][gy+1][0]*x0y1+
          fluid_data[gx+1][gy+1][0]*x1y1
        );
        part.py = part.y-(
          fluid_data[gx][gy][1]*x0y0+
          fluid_data[gx+1][gy][1]*x1y0+
          fluid_data[gx][gy+1][1]*x0y1+
          fluid_data[gx+1][gy+1][1]*x1y1
        );
      }
    }
  }
  
  public void applyFluidPhysics()
  {
    projectPartsToGrid();
    normalizeVelocities();
    applyPressureForce();
    projectGridToParts();
  }
  
  public void applyBoundaries()
  {
    for(Part part : this) {
      part.x = min(max(part.x,0),width);
      part.y = min(max(part.y,0),height);
    }
  }
  
  public void handle()
  {
    if(time_running) {
      updateDimensions(width,height);
      for(int i=0;i<10;i++) {
        applyBoundaries();
        applyFluidPhysics();
        applyBoundaries();
        applyContactPhysics();
        moveParts();
      }
    }
    draw();
  }
  
}
