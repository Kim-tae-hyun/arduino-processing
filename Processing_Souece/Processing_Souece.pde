import processing.serial.*;
import processing.opengl.*;
import toxi.geom.*;
import toxi.processing.*;
import java.io.IOException;
import java.awt.event.KeyEvent;
 
ToxiclibsSupport gfx;
Serial myPort;                         // The serial port
 
 PImage i,j;
 
String s="";
int[] num = new int[7];
int count=0;
/*--------------------------Radar------------------------*/
//Radar 에 관한 변수
String noObject;
float pixsDistance;
int iAngle, iDistance;

/*--------------------------Radar------------------------*/

/*---------------------------Airplane-------------------------*/
//Airplane 에 관한 변수
char[] teapotPacket = new char[14];  // InvenSense Teapot packet
int serialCount = 0;                 // current packet byte position
int aligned = 0;
int interval = 0;
float[] q = new float[4];
Quaternion quat = new Quaternion(1, 0, 0, 0);
float[] gravity = new float[3];
float[] euler = new float[3];
float[] ypr = new float[3];
/*---------------------------Airplane-------------------------*/ 

/*---------------------------sensor-------------------------*/
//sensor 에 관한 변수
long now,pre;
int sensor1_val;
int[] sensor1_vals;
int Twidth;
/*---------------------------sensor-------------------------*/
/*---------------------------Joystick-------------------------*/
//Joystick 에 관한 변수
int SW1,X1,Y1;
int triSize=20;
boolean shoot = false;
int posX=30;
int posY;
int ballSize = 30;
int laserLimit = 80;  
/*---------------------------Joystick-------------------------*/

void setup() {
    size(1200, 800, OPENGL);
    gfx = new ToxiclibsSupport(this);
 
    lights();
    smooth();
    String portName = "COM4";
    myPort = new Serial(this, portName, 115200);
    myPort.write('r');
    sensor1_vals = new int[500]; //조도센서값을 저장할 배열
    smooth();
    background(0);
}

 
void draw() {
  
/*---------------------------Airplane-------------------------*/
//Airplane draw
pushMatrix();
translate(-100,500);
scale(0.4);
AirPlane();
scale(1.0);
popMatrix();  
/*---------------------------Airplane-------------------------*/

/*--------------------------Radar------------------------*/
//Radar draw
pushMatrix();
fill(18,4);
rect(0,0,843,430);
translate(0,0);
scale(0.7,0.6);
Radar();
scale(1.0);
popMatrix();
/*--------------------------Radar------------------------*/

/*---------------------------sensor-------------------------*/
//sensor draw
pushMatrix();
translate(280,400);
sensor();
popMatrix();
/*---------------------------sensor-------------------------*/

/*--------------------------line----------------------------*/
//각 출력을 구분짖기 위한 라인
stroke(255,100);
strokeWeight(5);
line(843,0,843,800);
line(0,480,845,480);
line(270,480,270,height);
noStroke();
/*--------------------------line----------------------------*/

/*---------------------------Joystick-------------------------*/
//Joystick draw
i = loadImage("prodo.png");
j = loadImage("lion.png");
pushMatrix();
translate(845,0);
joystick();
popMatrix();
/*---------------------------Joystick-------------------------*/
}
 
void AirPlane(){
 if (millis() - interval > 1000) {
        // resend single character to trigger DMP init/start
        // in case the MPU is halted/reset while applet is running
        myPort.write('r');
        interval = millis();
    }
    
 
 

      //3차원 평면을 vertex 로 그렷다.
     fill(0);
     beginShape();
     vertex(100,-50,-100);
     vertex(900,-50,-100);
     vertex(900,830,-100);
     vertex(0,830,-100);
     endShape();

    
    // translate everything to the middle of the viewport
    pushMatrix();
    translate(width / 2, height / 2);

 
    // toxiclibs direct angle/axis rotation from quaternion (NO gimbal lock!)
    // (axis order [1, 3, 2] and inversion [-1, +1, +1] is a consequence of
    // different coordinate system orientation assumptions between Processing
    // and InvenSense DMP)
    float[] axis = quat.toAxisAngle();
    rotate(axis[0], -axis[1], axis[3], axis[2]);
 
    // draw main body in red
    fill(255, 0, 0, 200);
    box(10, 10, 200);
    
    // draw front-facing tip in blue
    fill(0, 0, 255, 200);
    pushMatrix();
    translate(0, 0, -120);
    rotateX(PI/2);
    drawCylinder(0, 20, 20, 8);
    popMatrix();
    
    // draw wings and tail fin in green
    fill(0, 255, 0, 200);
    beginShape(TRIANGLE);
    vertex(-130,  2, 30);; vertex(0,2,-80) ;vertex(135,  2, 30);  // wing top layer
    vertex(-130, -2, 30); vertex(0,  2, -80); vertex(130, -2, 30);  // wing bottom layer
    
    vertex(-2, 0, 98); vertex(-2, -30, 98); vertex(-2, 0, 70);  // tail left layer
    vertex( 2, 0, 98); vertex( 2, -30, 98); vertex( 2, 0, 70);  // tail right layer
    endShape();
    beginShape(QUADS);
    vertex(-100, 2, 30); vertex(-100, -2, 30); vertex(  0, -2, -80); vertex(  0, 2, -80);
    vertex( 100, 2, 30); vertex( 100, -2, 30); vertex(  0, -2, -80); vertex(  0, 2, -80);
    vertex(-100, 2, 30); vertex(-100, -2, 30); vertex(100, -2,  30); vertex(100, 2,  30);
    vertex(-2,   0, 98); vertex(2,   0, 98); vertex(2, -30, 98); vertex(-2, -30, 98);
    vertex(-2,   0, 98); vertex(2,   0, 98); vertex(2,   0, 70); vertex(-2,   0, 70);
    vertex(-2, -30, 98); vertex(2, -30, 98); vertex(2,   0, 70); vertex(-2,   0, 70);
    endShape();
    popMatrix();
    
}
 
/*--------------------------Radar------------------------*/
//원래 초음파 센서의 프로세싱 값을 가지고 와서 scale 만 변화주어 비율을 이용해 화면에 출력하였다.
void Radar(){
  fill(98,245,31);
  noStroke();
  
  fill(98,245,31);
  drawRadar();
  drawLine();
  drawObject();
  drawText();
  
  
}

void drawRadar(){
 pushMatrix();

translate(width/2,height*0.8);

noFill();
strokeWeight(5*width/960*height/700);
stroke(98,245,31);
arc(0,0,width*0.9375,height*1.285714285714286,PI,TWO_PI);
arc(0,0,width*0.72916666666666667,height*1,PI,TWO_PI);
arc(0,0,width*0.5208333333333,height*0.7142857142857143,PI,TWO_PI);
arc(0,0,width*0.3125,height*0.4285714285714286,PI,TWO_PI);
line(-width/2,0,width/2,0);
line(0,0,-width/2*cos(radians(30)),-width/2*sin(radians(30)));
line(0,0,-width/2*cos(radians(60)),-width/2*sin(radians(60)));
line(0,0,-width/2*cos(radians(90)),-width/2*sin(radians(90)));
line(0,0,-width/2*cos(radians(120)),-width/2*sin(radians(120)));
line(0,0,-width/2*cos(radians(150)),-width/2*sin(radians(150)));
line(-width/2*cos(radians(30)),0,width/2,0);
popMatrix();
}


void drawObject(){
pushMatrix();
translate(width/2,height*0.8);
strokeWeight(5*width/960*height/700);
stroke(255,10,10);
pixsDistance = iDistance*22.5;
if(iDistance<20){
line(pixsDistance*cos(radians(iAngle)),-pixsDistance*sin(radians(iAngle)),width/2*cos(radians(iAngle)),-width/2*sin(radians(iAngle)));
}
popMatrix();
}

void drawLine(){

pushMatrix();
strokeWeight(5*width/960*height/700);
stroke(30,250,60);
translate(width/2,height*0.8);
line(0,0,width/2*cos(radians(iAngle)),-width/2*sin(radians(iAngle)));
popMatrix();
}


void drawText(){
pushMatrix();
if(iDistance>20){
noObject = "Out of Range";
}
else{
noObject = "In Range";
}

scale(1.0);
fill(0,0,0);
noStroke();
rect(0,640,width,150);
fill(98,245,31);
textSize(25 * width/960 * height/700);
text("10cm",width*0.6145833333333333333,height*0.8357142857142857);
text("20cm",width*0.71875,height*0.8357142857142857);
text("30cm",width*0.8229166666667,height*0.8357142857142857);
text("40cm",width*0.927083333333333,height*0.8357142857142857);
textSize(30 * width/960 * height/700);
text("Object :" + noObject,width*0.1041666666667,height*0.9285714285714286);
text("Angle :" +iAngle + " °",width*0.625,height*0.9285714285714286);
/*if(iDistance<40){
text(" " + iDistance+ " cm",1450,1050);
}*/
textSize(25 * width/960 * height/700);
fill(98,245,60);
pushMatrix();
translate(width/2+width/2*cos(radians(30)),height*0.7714285714285714-width/2*sin(radians(30)));
rotate(-radians(-60));
text("30°",0,0);
popMatrix();
pushMatrix();
translate(width*0.4895833333333+width/2*cos(radians(60)),height*0.7714285714285714-width/2*sin(radians(60)));
rotate(-radians(-30));
text("60°",0,0);
popMatrix();
pushMatrix();
translate(width*0.48125+width/2*cos(radians(90)),height*0.7857142857142857-width/2*sin(radians(90)));
rotate(radians(0));
text("90°",0,0);
popMatrix();
pushMatrix();
translate(width*0.4666666666667+width/2*cos(radians(120)),height*0.8-width/2*sin(radians(120)));
rotate(radians(-30));
text("120°",0,0);
popMatrix();
pushMatrix();
translate(width*0.479166666666667+width/2*cos(radians(150)),height*0.8142857142857143-width/2*sin(radians(150)));
rotate(radians(-60));
text("150°",0,0);
scale(0.7,0.6);
popMatrix();
popMatrix();
}
/*--------------------------Radar------------------------*/

/*---------------------------sensor-------------------------*/

void sensor(){
  fill(0,0,0);
noStroke();
rect(-10,60,width,350);
    strokeWeight(3);
    stroke(255, 255, 255);
    fill(255,255, 255);
    textSize(15);
    line(60,80,60,350);
    text("bright",10,200);
    line(60,350,570,350);
    int time = millis()/1000;
    text("time  ",250,375);
    
    
    text("bright : " + sensor1_val,450,100);
    text("time : " + time,450,120);
    

    for (int i=0; i<500-1; i++) 
      sensor1_vals[i] = sensor1_vals[i+1];
    sensor1_vals[500-1] = sensor1_val;
    
    for (int x=1; x<500; x++) {
      line(560-x,   350-1-getY(sensor1_vals[x-1]),560-1-x, 350-1-getY(sensor1_vals[x]));
    }
     noStroke();
   
  }
  

int getY(int val) {
  return (int)(val / 1023.0f * height) - 1;
}


/*---------------------------sensor-------------------------*/
 /*----------------------Airplane------------------------------*/
 //원래 자이로 센서 프로세싱소스를 이용하여 값을 아두이노의 값을 받아왔다.
void serialEvent(Serial myPort) {
  
   
    interval = millis();
    while (myPort.available() > 0) {
        int ch = myPort.read(); // serial print 에서 값을 받아온다 아스키 코드 값이다.
       // print((char)ch);
        
         if((char)ch ==','){ //받은 문자가 , 인지를 확인   serial print 는 ,1,500,200,33,24,24,$.. 이런식으로 받아온다.
        //아두이노에서 프로세싱으로 값을 전달할 때 조이스틱 조도센서 초음파 센서에는 ,로 표시하고 자이로센서는 $ 로 표시해서 구별하였다.
        //첫번째는 조이스틱값 두번째는 조도센서 세번 째는 초음파센서 값 마지막은 자이로 센서값이다 아두이노에서 값을 다 합쳤다.
        //print( "count : " + count + " \n");
        // print("String : " + s + " \n");
     if(count==0){ // serial print 로 받은 값이 num 배열에 저장된다. count 는 num 배열의 index 이다.
                   // 숫자들을 아스키 코드로 받앗는데 자이로센서값에서도 숫자가 나올 수 있다. 자이로센서에서 나온 값은 필요없기때문에 num[0]에 저장하지 않는다.     
     }
     else{
       if(count == 1){ //num[1] 에서부터 필요한 값을 저장한다 num[1] ~ num[3] 까지는 조이스틱 num[4] 조도센서 num[5]~num[6] 은 초음파센서 이다.
           if((s.equals("0")) || (s.equals("1"))){ //맨 처음값은 조이스틱이 눌렀는지 안눌렀는지 (0,1) 로 표시되기 때문에 0과 1로 걸럿다.
            // print("if \n");
             num[count]=Integer.parseInt(s);// string 을 int 형으로 변환한다.
           }
           else{
            // print("else \n"); 
             count--; //만약 0이나 1이 아닐경우 count 값을 낮춰 다시 num[1] 에 값이 쓰여지게 하였다.
           }
       }
       else{
         num[count]=Integer.parseInt(s); //num[1] 이 아닌것은 여기서 string 이 int 로 형 변환 된다.
       }
       
     }
      s=""; //string s 초기화
     if(count==6){
      // print("count in  = " + count + " \n");
     // print("num1 : "+ num[1]+" \n");
      SW1=num[1];
     // print("num2 : "+ num[2]+" \n");
      X1=num[2];
     // print("num3 : "+ num[3]+" \n");
      Y1=num[3];
     // print("num4 : "+ num[4]+" \n");
      sensor1_val=num[4];
     // print("num5 : "+ num[5]+" \n");
      iAngle=num[5];
      //print("num6 : "+ num[6]+" \n");
      iDistance=num[6];
      count=0; //count 초기화
/*--------------------JoyStick---------------------*/
//JoyStick 에 대한 소스로 SW1 은 push X1 Y1 는 x 축과 y 축이다.
      if(SW1 == 1){
  shoot = false;
  }
  else{
  shoot = true;
}
  X1 = X1/3;
  if(X1 > width){
  X1 = width;
  }
  if(Y1 > height){
  Y1 = height;
  }
/*--------------------JoyStick---------------------*/
      }
      else{
     count++; //count==6 이 아닐때만 증가
      }
    }
        
    if(( (int)48 <= ch)&( (int)57 >= ch) ){ // 아스키 코드로 숫자만 받았다.
     String a="";
    a= String.valueOf((char)ch); //문자형을 문자열로 변환시킨것을 a 라는 string 에 넣었다.
    s = s + a; //string s 에 추가시켰다.
 
  }
if (ch == '$') {serialCount = 0;} // 문자 $ 가 오면 자이로센서 값이다.
        if (aligned < 4) {
            // make sure we are properly aligned on a 14-byte packet
            if (serialCount == 0) {
                if (ch == '$') aligned++; else aligned = 0;
            } else if (serialCount == 1) {
                if (ch == 2) aligned++; else aligned = 0;
            } else if (serialCount == 12) {
                if (ch == '\r') aligned++; else aligned = 0;
            } else if (serialCount == 13) {
                if (ch == '\n') aligned++; else aligned = 0;
            }
            //println(ch + " " + aligned + " " + serialCount);
            serialCount++;
            if (serialCount == 14) serialCount = 0;
        } else {
            if (serialCount > 0 || ch == '$') {
                teapotPacket[serialCount++] = (char)ch;
                if (serialCount == 14) {
                    serialCount = 0; // restart packet byte position
                    
                    // get quaternion from data packet
                    q[0] = ((teapotPacket[2] << 8) | teapotPacket[3]) / 16384.0f;
                    q[1] = ((teapotPacket[4] << 8) | teapotPacket[5]) / 16384.0f;
                    q[2] = ((teapotPacket[6] << 8) | teapotPacket[7]) / 16384.0f;
                    q[3] = ((teapotPacket[8] << 8) | teapotPacket[9]) / 16384.0f;
                    for (int i = 0; i < 4; i++) if (q[i] >= 2) q[i] = -4 + q[i];
                    
                    // set our toxilibs quaternion to new data
                    quat.set(q[0], q[1], q[2], q[3]);
 
                }
            }
        }
        //자이로 센서의 값을 받아오는 과정
}
}
  
 

void drawCylinder(float topRadius, float bottomRadius, float tall, int sides) {
    float angle = 0;
    float angleIncrement = TWO_PI / sides;
    beginShape(QUAD_STRIP);
    for (int i = 0; i < sides + 1; ++i) {
        vertex(topRadius*cos(angle), 0, topRadius*sin(angle));
        vertex(bottomRadius*cos(angle), tall, bottomRadius*sin(angle));
        angle += angleIncrement;
    }
    endShape();
    
    // If it is not a cone, draw the circular top cap
    if (topRadius != 0) {
        angle = 0;
        beginShape(TRIANGLE_FAN);
        
        // Center point
        vertex(0, 0, 0);
        for (int i = 0; i < sides + 1; i++) {
            vertex(topRadius * cos(angle), 0, topRadius * sin(angle));
            angle += angleIncrement;
        }
        endShape();
    }
  
    // If it is not a cone, draw the circular bottom cap
    if (bottomRadius != 0) {
        angle = 0;
        beginShape(TRIANGLE_FAN);
    
        // Center point
        vertex(0, tall, 0);
        for (int i = 0; i < sides + 1; i++) {
            vertex(bottomRadius * cos(angle), tall, bottomRadius * sin(angle));
            angle += angleIncrement;
        }
        endShape();
    }
}
 /*----------------------Airplane------------------------------*/
 /*---------------------------Joystick-------------------------*/
 void initGame(){
    posY=0;
      posX = int(random(360));
     while(posX < 30){
       posX = int(random(360));
     }
}
void joystick(){
  fill(0);
  rect(-10,0,width,height);
  fill(255);
  ellipse(X1,Y1,30,30);
  fill(255,10);
  rect(0,0, width,height-laserLimit);
  fill(255,255,255);
  rect(0, height-laserLimit, width, height);
  ballDropper();
  triLaser();
  if(shoot==true){
  ballKiller(X1);
  shoot=false;
  }
  gameEndChk();
  
}

void triLaser(){
  if(Y1>height-laserLimit){
  fill(0,255,0);
  stroke(0,255,0);
  triangle(X1-triSize, Y1, X1+triSize, Y1, X1, Y1-triSize);
  noStroke();
  }
}

void ballDropper(){
  fill(255,10);
  stroke(255);
     image(i,posX,posY++,ballSize,ballSize);
  noStroke();
 
}


void gameEndChk(){
  if(posY==height-laserLimit){
  fill(255,0,0);
  initGame();
  }
}

void ballKiller(int x){
  boolean hit = false;
  stroke(255,0,0);
  fill(255,0,0);
  if((x>=posX-ballSize/2) && (x<=posX+ballSize)){
  hit=true;
  line(X1, Y1, X1, posY);
  ellipse(posX,posY,ballSize+25, ballSize+25);
  initGame();
  }
  if(hit==false){
  line(X1, Y1, X1, 0);
  }
  noStroke();
}



void KeyPressed(){
  initGame();
  loop();
}


 /*---------------------------Joystick-------------------------*/