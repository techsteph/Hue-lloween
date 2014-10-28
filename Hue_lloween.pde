//HTML Stuff 
//put commons-logging-1.2.jar in \sketch\code
//put httpclient-4.3.5.jar in \sketch\code
// put httpcore-4.3.2.jar in \sketch\code
import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.impl.client.DefaultHttpClient;

//Hue Stuff
String url_light;
String url_group;
int numLamps = 3;         //number of Lamps
HueLamp[] hLight;         //HueLamp objects
int mainColor = 0;  
int keyFrameIncrement=40; //How much time between mainColor Group Hue change 2" with FPS=20
int keyFrameCount=0;

//Audio Stuff
import ddf.minim.*;
Minim minim;
AudioPlayer player;

//Setting Sensitivity, triggers and Timers for Strikes
float sVal=.4;                //Audio sensitivity (0 to 1) for Strike sound analysis, lower is more sensitive. 0.40 works fine.
boolean lTriggerSet=false;
boolean rTriggerSet=false;
boolean mTriggerSet=false;
int lTriggerResetTimer=0;
int rTriggerResetTimer=0;
int mTriggerResetTimer=0;
int triggerDuration=40;
boolean lStrikeStatus=false;
boolean rStrikeStatus=false;
boolean mStrikeStatus=false;
int incCounter=0;             //Counter to loop between sound samples
int clickVal=99;              //Button selector, 99 inactive - set to 1 to 4 to autostart strikes
int numSamples=24;            //Number of Sound Samples - files must be named xxx0 onwards
long nextStrike=65535;
long interStrikeWaitTimer=0;  //Values set by buttons - time between strikes
long interStrikeMultiplier=0; //Values set by buttons - multiplier
boolean buttonToggle=false;

//Setting Frames per Second
int fps=20;

//Other Control Stuff
PImage img;

void setup() {
  size(600, 400);
  textSize(18);
  frame.setTitle("Hue Storm Simulator");
  url_light = "http://*YOURBRIDGEIP*/api/*YOURUSERID*/lights/";          //provide your bridge IP Address and user
  url_group = "http://*YOURBRIDGEIP*/api/*YOURUSERID*/groups/0/action";  //provide your bridge IP Address and user
  frameRate(fps);
  hLight = new HueLamp[numLamps];                       //Create Lamps objects
  for (int i=0; i<numLamps; i++) {
    hLight[i] = new HueLamp(i+1, int(random(4, 40)));  //Set lamp number (Philips start from 1) and flickering timer
  }
  minim = new Minim(this);
  player= minim.loadFile("/data/TS0.mp3");             //pre-load a Strike sound sample
}

void draw() {
  background(0);
  fill(255);
  for (int i=0; i<4; i++) {
    String imgName="/data/strike"+(1+i)+".jpg";
    img = loadImage(imgName);
    image(img, 25+(150*i), 50);
  }
  if (frameCount>nextStrike & clickVal!=99) {
    buttonToggle=true;
  }
  buttonManagement();
  beatAnalysis();

  text("Frame "+frameCount+" Color change in "+keyFrameCount+", Current Hue: "+mainColor, 10, 300);
  text("ESC to Exit", 10, 350);

  if (clickVal!=99) {
    text("Next Strike at frame "+nextStrike, 150, 150);
  } else {
    text("              NO STORM           ", 150, 150);
  }
  if (keyFrameCount==0) {
    mainColor=int(random(1000, 8000));    
    changeLightGroup(mainColor, 254, 254, int(random(10, 40)));
    keyFrameCount=int(random(keyFrameIncrement, keyFrameIncrement*2));
  } 
  //assign lights to left, right or center channel
  keyFrameCount--;
  if (lStrikeStatus==true) {
    hLight[0].flash();
    lStrikeStatus=false;
  } else {
    hLight[0].update();
  }
  if (mStrikeStatus==true) {
    hLight[1].flash();
    mStrikeStatus=false;
  } else {
    hLight[1].update();
  }
  if (rStrikeStatus==true) {
    hLight[2].flash();
    rStrikeStatus=false;
  } else {
    hLight[2].update();
  }
}

void keyPressed() {
  if (key==ESC) {
    key=0;
    changeLightGroup(15258, 125, 254, 5);
    player.close();
    minim.stop();
    println("Closing");
    super.exit();
  }
} 
void buttonManagement() {
  if (buttonToggle==true) {
    player.close();
    incCounter++;
    String fileName="/data/TS"+(incCounter%numSamples)+".mp3";
    interStrikeWaitTimer=10+(40*clickVal);
    interStrikeMultiplier=1+(clickVal*2);
    println(fileName);
    player=minim.loadFile(fileName);
    player.play();   
    buttonToggle=false;
    nextStrike=frameCount+((player.length()/1000)*fps)+int(random(interStrikeWaitTimer, interStrikeWaitTimer*interStrikeMultiplier));
  }
}

void mousePressed() {
  for (int i=0; i<4; i++) {
    if (mouseX>25+(150*i) & mouseX<25+(150*i)+100 & mouseY>50 & mouseY<100) {
      if (clickVal==i) {
        player.close();     
        clickVal=99;
        buttonToggle=false;
      } else {
        clickVal=i;
        buttonToggle=true;
      }
    }
  }
}

class HueLamp { 
  int ID, nextFlickerFrame;   //ID and NextFlickerFrame
  int flickerFrameCount=0;
  boolean flickerTest=false;
  HueLamp (int id, int nextFlickerFrame) {
    ID=id;
    nextFlickerFrame=nextFlickerFrame;
  } 
  void flash() {
    changeLightUnit(ID, 34477, 228, 254, 0);
    flickerFrameCount=1;
    nextFlickerFrame=0;
  }
  void update() { 
    if (nextFlickerFrame>0) {
      nextFlickerFrame--;
    } else {
      if (flickerFrameCount==0) {
        flickerLightUnit(ID, mainColor, 254, int(random(1, 5)));
        flickerFrameCount=int(random(2, 6));
        flickerTest=false;
        nextFlickerFrame=int(random(4, 40));
      } else if (flickerTest==true) {
        flickerFrameCount--;
      } else {
        flickerLightUnit(ID, mainColor, int(random(64, 192)), int(random(3, 12)));
        flickerTest=true;
      }
    }
  }
} 
void beatAnalysis() {

  fill(255);
  float lSound=abs(player.left.get(0));
  float rSound=abs(player.right.get(0));
  float mSound=abs(player.mix.get(0));

  text(nf(lSound, 2, 2), 130, 250);
  text(nf(rSound, 2, 2), 270, 250);
  text(nf(mSound, 2, 2), 430, 250);

  if (lSound>sVal) {
    if (lTriggerSet==false) {
      lTriggerSet=true;
      lTriggerResetTimer=triggerDuration;
      lStrikeStatus=true;
    }
  }
  if (lTriggerSet==true) {
    if (lTriggerResetTimer>1) {
      lTriggerResetTimer--;
      fill(255/triggerDuration*lTriggerResetTimer);
      ellipse(150, 200, 40, 40);
    } else {
      lTriggerSet=false;
    }
  }
  fill(255);

  if (rSound>sVal) {
    if (rTriggerSet==false) {
      rTriggerSet=true;
      rTriggerResetTimer=triggerDuration;
      rStrikeStatus=true;
    }
  }
  if (rTriggerSet==true) {
    if (rTriggerResetTimer>1) {
      rTriggerResetTimer--;
      fill(255/triggerDuration*rTriggerResetTimer);
      ellipse(450, 200, 40, 40);
    } else {
      rTriggerSet=false;
    }
  }
  fill(255);
  if (mSound>sVal) {
    if (mTriggerSet==false) {
      mTriggerSet=true;
      mTriggerResetTimer=triggerDuration;
      mStrikeStatus=true;
    }
  }
  if (mTriggerSet==true) {
    if (mTriggerResetTimer>1) {
      mTriggerResetTimer--;
      fill(255/triggerDuration*mTriggerResetTimer);
      ellipse(300, 200, 40, 40);
    } else {
      mTriggerSet=false;
    }
  }
  fill(255);
}
//All Lamps full update Hue, Sat, Bri, TransitionTime
void changeLightGroup(int H, int S, int B, int T) {
  DefaultHttpClient httpClient = new DefaultHttpClient();
  try
  {   
    HttpPut httpPut = new HttpPut(url_group);
    String data = "{";
    data += "\"on\": true, ";
    data += "\"hue\":";
    data += H;
    data += ", \"sat\":";
    data += S;
    data += ", \"bri\":";
    data += B;
    data += ", \"transitiontime\":";
    data += T;
    data += "}";
    StringEntity se = new StringEntity(data);
    httpPut.setEntity(se);
    //    println("executing request:" + httpPut.getRequestLine() );
    HttpResponse response = httpClient.execute(httpPut);
    HttpEntity entity = response.getEntity();
    //    if (entity != null) entity.writeTo( System.out );
    if (entity != null) entity.consumeContent();
  } 
  catch( Exception e ) { 
    e.printStackTrace();
  }
  httpClient.getConnectionManager().shutdown();
}
//Full lamp update Id, Hue, Sat, Bri, TransitionTime
void changeLightUnit(int ID, int H, int S, int B, int T) {
  DefaultHttpClient httpClient = new DefaultHttpClient();
  try
  {
    String fullurl=url_light+ID+"/state";
    HttpPut httpPut = new HttpPut(fullurl);
    String data = "{";
    data += "\"on\":true, ";
    data += "\"hue\":";
    data += H;
    data += ", \"sat\":";
    data += S;
    data += ", \"bri\":";
    data += B;
    data += ", \"transitiontime\":";
    data += T;
    data += "}";
    StringEntity se = new StringEntity(data);
    httpPut.setEntity(se);
    //    println("executing request:" + httpPut.getRequestLine() );
    HttpResponse response = httpClient.execute(httpPut);
    HttpEntity entity = response.getEntity();
    // display response on screen
    //      if (entity != null) entity.writeTo( System.out );
    if (entity != null) entity.consumeContent();
    // when HttpClient instance is no longer needed, 
    // shut down the connection manager to ensure
    // immediate deallocation of all system resources
  } 
  catch( Exception e ) { 
    e.printStackTrace();
  }
  httpClient.getConnectionManager().shutdown();
}
//Limited lamp Id, Bri, TransitionTime (used for flickering)
void flickerLightUnit(int ID, int H, int B, int T) {
  DefaultHttpClient httpClient = new DefaultHttpClient();
  try
  {
    String fullurl=url_light+ID+"/state";
    HttpPut httpPut = new HttpPut(fullurl);
    String data = "{";
    data += "\"on\":true, ";
    data += "\"bri\":";
    data += B;
    data += ", \"transitiontime\":";
    data += T;
    data += ", \"hue\":";
    data += H;
    data += "}";
    StringEntity se = new StringEntity(data);
    httpPut.setEntity(se);
    //    println("executing request:" + httpPut.getRequestLine() );
    HttpResponse response = httpClient.execute(httpPut);
    HttpEntity entity = response.getEntity();
    // display response on screen
    //      if (entity != null) entity.writeTo( System.out );
    if (entity != null) entity.consumeContent();
    // when HttpClient instance is no longer needed, 
    // shut down the connection manager to ensure
    // immediate deallocation of all system resources
  } 
  catch( Exception e ) { 
    e.printStackTrace();
  }
  httpClient.getConnectionManager().shutdown();
}

