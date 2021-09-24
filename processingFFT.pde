import oscP5.*;
import netP5.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import processing.serial.*;

OscP5 oscP5;
NetAddress dest, dest2, dest3;

Minim minim;
AudioInput in;
FFT         fft;
DFT dft;

float totalFFTValue, minFFTValue, maxFFTValue;
int fftSize = 8;
float[] fftResult = new float[fftSize];                                  

Serial myPort;  // Create object from Serial class
String arduinoData;      // Data received from the serial port
void setup() {
  size(640, 480, P2D);
  frameRate(15);
  
  // osc stuff
  oscP5 = new OscP5(this, 12000);
  dest = new NetAddress("127.0.0.1", 6449);
  dest2 = new NetAddress("127.0.0.1", 6448);
  dest3 = new NetAddress("127.0.0.1", 7001);
  
  // fft setup stuff
  minim = new Minim(this);
  in = minim.getLineIn();
  fft = new FFT( in.bufferSize(), fftSize );
  
  // Setup reading from the serial port
  String portName = Serial.list()[0];
  myPort = new Serial(this, portName, 9600);

  background(0);
  fill(255);
}

void draw() {
    totalFFTValue = 0;
    minFFTValue = 0;
    maxFFTValue = 0;
    if(frameCount % 2 == 0) {
      fft.forward( in.mix );
      for(int i = 0; i < fftSize; i++) {
        //fftResult[i] += fft.getBand(i)/2;
        fftResult[i] = fft.getBand(i);
        if(fftResult[i] > maxFFTValue)
          maxFFTValue = fftResult[i];
        if(fftResult[i] < minFFTValue)
          minFFTValue = fftResult[i];
        totalFFTValue += fftResult[i];
      }
      sendFFTOsc(maxFFTValue / totalFFTValue, maxFFTValue, totalFFTValue/fftSize, maxFFTValue/totalFFTValue-minFFTValue);
    }
    if ( myPort.available() > 0) {  // If data is available,
      arduinoData = myPort.readStringUntil(10);         // read it and store it in val
      if(arduinoData != null)
        sendArduinoOsc(arduinoData);
    }
}

void sendFFTOsc(float avg0, float max, float average, float avg2) {
  OscMessage msg = new OscMessage("/fftData");
  OscMessage msg2 = new OscMessage("/wek/inputs");
  
  //println(fftResult);
  msg.add(fftResult);
  //msg.add(fftResult);
  msg.add(max);
  msg.add(avg0);
  msg.add(average);
  msg.add(avg2);
  
  msg2.add(fftResult[0]);
  oscP5.send(msg, dest);
  oscP5.send(msg, dest2);
  oscP5.send(msg2, dest3); //<>//
  
  //msg2.add(fftResult);
  //msg2.add(fftResult);
}

void sendArduinoOsc(String arduinoData) {
  if(arduinoData.length() > 0) {
    OscMessage msg = new OscMessage("/arduinoData");

    msg.add(arduinoData);
    oscP5.send(msg, dest2);
  }
}
