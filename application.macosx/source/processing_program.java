import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import processing.opengl.*; 
import hypermedia.net.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class processing_program extends PApplet {


/*
 * Processing\u3092\u7528\u3044\u305fcsv\u30d5\u30a1\u30a4\u30eb\u306e\u53ef\u8996\u5316
 * \u30d7\u30ed\u30bb\u30b9\u3067\u306f\u306a\u304fIP\u30a2\u30c9\u30ec\u30b9\u3092\u901a\u4fe1\u5148\u3068\u3057\u3066\u6271\u3046
 * mbp\u3067\u306fframerate100\u304c\u9650\u754c\u306e\u6a21\u69d8
 * \u30b9\u30da\u30fc\u30b9\u30ad\u30fc\u3067\u4e00\u6642\u505c\u6b62\u53ef
 */
/*
 * \u6587\u5b57\u304b\u3076\u308a\u306e\u56de\u907f\u306b\u3064\u3044\u3066\u306e\u6848
 * \u6587\u5b57\u304c\u751f\u6210\u3055\u308c\u3066\u3044\u308b\u9593\u3001\u305d\u306e\u9818\u57df\u3092\u5909\u6570\u3068\u3057\u3066\u30a4\u30f3\u30b9\u30bf\u30f3\u30b9\u306b\u6301\u305f\u305b\u308b
 * \u6587\u5b57\u751f\u6210\u6642\u306b\u4ed6\u306e\u30a4\u30f3\u30b9\u30bf\u30f3\u30b9\u306e\u9818\u57df\u3068\u304b\u3076\u3089\u306a\u3044\u304b\u5224\u5b9a\u3092\u3057\u3001
 * \u88ab\u3063\u305f\u5834\u5408\u306f\u4e0a\u306b\u305a\u3089\u3059
 */
/* 
 * \u540c\u671f\u306e\u6848
 * \u30ad\u30e3\u30d7\u30c1\u30e3\u5074\u306fUDP\u3067\u5e38\u306b\u9001\u308a\u7d9a\u3051\u308b
 * \u53ef\u8996\u5316\u5074\u3067\u306fUDP\u3092\u30ad\u30e3\u30c3\u30c1\u3057\u305f\u3089\u30ad\u30e5\u30fc\u306e\u30ea\u30b9\u30c8\u306b\u8ffd\u52a0\u3059\u308b
 * \u30a4\u30f3\u30b9\u30bf\u30f3\u30b9\u751f\u6210\u3068\u53ef\u8996\u5316\u5b9f\u884c\u306e\u3057\u304a\u308a\u7684\u306a\u5909\u6570\u3092\u7528\u610f\u3059\u308b
 * 1\u3064\u76ee\u306e\u30d1\u30b1\u30c3\u30c8\u306e\u6301\u3064\u6642\u9593\u3068\u306e\u5dee\u3092\u57fa\u6e96\u306b\u8868\u793a\u3057\u3066\u3044\u304f
 * \u524d\u306e\u30d1\u30b1\u30c3\u30c8\u3068\u901a\u4fe1\u5148\u306eIP, port\u304c\u540c\u3058\u306710ms\u3044\u306a\u3044\u306e\u3082\u306e\u306f\u63cf\u753b\u3057\u306a\u3044
 */




int row_length;//\u914d\u5217\u306e\u9577\u3055
int max_time;//\u30ad\u30e3\u30d7\u30c1\u30e3\u7d4c\u904e\u6642\u9593\u306e\u6700\u5927\u5024
String [][] csv;//csv\u3092\u683c\u7d0d\u3059\u308b\u4e8c\u6b21\u5143\u914d\u5217
/* \u9001\u3089\u308c\u3066\u304f\u308b\u30d1\u30b1\u30c3\u30c8\u306b\u3064\u3044\u3066 */
/* 
 * 0:\u30ad\u30e3\u30d7\u30c1\u30e3\u6642\u306e\u901a\u3057\u756a\u53f7
 * 1:\u30d7\u30ed\u30c8\u30b3\u30eb
 * 2:\u30d0\u30a4\u30c8
 * 3:IP(\u30db\u30b9\u30c8)
 * 4:IP(\u901a\u4fe1\u5148)
 * 5:\u30dd\u30fc\u30c8(\u30db\u30b9\u30c8)
 * 6:\u30dd\u30fc\u30c8(\u901a\u4fe1\u5148)
 * 7:\u30ad\u30e3\u30d7\u30c1\u30e3\u958b\u59cb\u304b\u3089\u306e\u7d4c\u904e\u6642\u9593
 * 8:\u53d7\u4fe1\u304b\u9001\u4fe1\u304b(\u9001\u4fe1\u306a\u3089true)
 * 9:TCP\u30d5\u30e9\u30b0
 * \u4ee5\u4e0a\u306e\u8a089\u306e\u30ab\u30e9\u30e0\u3092\u6301\u3064
 */

Node user;
PFont myFont;
PFont myFont2;
Packets [] packets = new Packets[500000];
int packet_count = 0;
int last_count = 0;//\u6700\u5f8c\u306b\u8aad\u307f\u8fbc\u3093\u3060\u30d1\u30b1\u30c3\u30c8\u306e\u30ab\u30a6\u30f3\u30c8(csv[?][0])
int push_ms;//\u4e00\u6642\u505c\u6b62\u6642\u4fdd\u5b58\u7528
int pop_ms;//\u4e00\u6642\u505c\u6b62\u89e3\u9664\u6642
int tmp_ms;//\u4e00\u6642\u505c\u6b62\u6642\u8868\u793a\u7528
int ms;
int difference;
boolean stopflag = true;
float rot = 0;
int draw_size;
float cam_z;
int box_size;
UDP udp;
int first_passed_time, last_v_num;//\uff11\u3064\u76ee\u306e\u30d1\u30b1\u30c3\u30c8\u306e\u6301\u3064\u7d4c\u904e\u6642\u9593, \u30a4\u30f3\u30b9\u30bf\u30f3\u30b9\u751f\u6210\u306e\u30ab\u30a6\u30f3\u30c8, \u30f4\u30a3\u30b8\u30e5\u30a2\u30e9\u30a4\u30ba\u306e\u30ab\u30a6\u30f3\u30c8
String IP = "54.65.112.212";
//String IP = "192.168.33.56";
int PORT = 20000;
int mode = 1;
int total_count = 0;

public void setup(){
  size(1000, 750, OPENGL);
  colorMode(HSB, 360, 100, 10);
  background(0, 0, 0);
  frameRate(100);
  noStroke();
  smooth();
  rectMode(CENTER);
  int addr_num = 1;
  int count = 0;
  myFont = loadFont("HelveticaNeue-Italic-24.vlw");
  myFont2 = loadFont("Monaco-20.vlw");
  textFont(myFont);
  rot = 0;
  cam_z = 0;
  box_size = 400;

  udp = new UDP(this, 20000);
  udp.listen(true);

  first_passed_time = last_v_num = 0;

  user = new Node(0, 0, 0, box_size/10);
  if(udp.send("connect request",IP,PORT)){
    System.out.println("Start visualizing!");
  }else{
    println("cannot connect "+IP+":"+PORT);
    exit();
  }
}



public void draw(){

  background(245, 85, 1);
  camera(width/2.0f, height/2.0f, (height/2.0f) / tan(PI*60.0f / 360.0f) + cam_z, width/2.0f, height/2.0f, 0, 0, 1, 0);
  lights();
  boolean drawflag = true;
  PMatrix3D billboardMat;
  ms = millis() - difference;
  String sec = nf(ms/1000.0f, 1, 1);
  translate(height/2, height/2);
  rotateY(rot);
  noFill();
  strokeWeight(3.5f);
  stroke(235, 86, 10);
  if(mode != 5){
    box_size = 400;
    box(box_size);
  }else{
    box_size = 450;
    draw2D();
  }
  textFont(myFont);
  fill(360, 0, 10);
  textAlign(CENTER);
  hint(DISABLE_DEPTH_TEST);
  pushMatrix();
  if(mode >= 3){
    translate(-box_size/2, 0);
    billboardMat = (PMatrix3D)g.getMatrix();
    billboardMat.m00 = billboardMat.m11 = billboardMat.m22 = 1;
    billboardMat.m01 = billboardMat.m02 = billboardMat.m10 = billboardMat.m12 = billboardMat.m20 = billboardMat.m21 = 0;
    resetMatrix();
    applyMatrix(billboardMat);
    text("CLIENT IP", 0, 0);
    popMatrix();
    pushMatrix();
    translate(box_size/2, 0);
    billboardMat = (PMatrix3D)g.getMatrix();
    billboardMat.m00 = billboardMat.m11 = billboardMat.m22 = 1;
    billboardMat.m01 = billboardMat.m02 = billboardMat.m10 = billboardMat.m12 = billboardMat.m20 = billboardMat.m21 = 0;
    resetMatrix();
    applyMatrix(billboardMat);
    text("SERVER PORT", 0, 0);
    popMatrix();
    pushMatrix();
  }
  translate(0, -height/4, 0);
  billboardMat = (PMatrix3D)g.getMatrix();
  billboardMat.m00 = billboardMat.m11 = billboardMat.m22 = 1;
  billboardMat.m01 = billboardMat.m02 = billboardMat.m10 = billboardMat.m12 = billboardMat.m20 = billboardMat.m21 = 0;
  resetMatrix();
  applyMatrix(billboardMat);
  if(mode == 1) text("MODE1: IP, PROTOCOL", 0, -80);
  else if(mode == 2) text("MODE2: IP, PORT", 0, -80);
  else if(mode == 3) text("MODE3: IP, PORT(ver2)", 0, -80);
  else if(mode == 4) text("MODE4: IP, PORT(ver3)", 0, -80);
  else if(mode == 5) text("MODE5: IP, PORT(2d)", 0, -80);
  if(stopflag) text("Time:"+sec, 0, 0);
  else text("Time:"+nf(tmp_ms/1000.0f, 1, 1), 0, 0);
  textAlign(LEFT);
  if(mode == 1 || mode == 3){
    fill(300, 69, 9);
    text("TCP_SYN", height/2, 0);
    fill(30, 69, 9);
    text("TCP_SYN/ACK", height/2, 30);
    fill(180, 69, 9);
    text("TCP_ACK", height/2, 60);
    fill(0, 69, 9);
    text("TCP_RST", height/2, 90);
    fill(270, 69, 9);
    text("TCP_FIN", height/2, 120);
    fill(240, 69, 9);
    text("TCP_UNKNOWN", height/2, 150);
    fill(120, 69, 9);
    text("UDP", height/2, 210);
    fill(60, 69, 9);
    text("ICMP", height/2, 270);
    fill(0, 0, 10);
    text("OTHERS", height/2, 330);
  }else if(mode == 2 || mode == 4 || mode == 5){
    fill(300, 0, 10);
    text("http", height/2, 0);
    fill(300, 0, 10);
    text("https", height/2, 30);
    fill(0, 69, 9);
    text("O", height/2, 90);
    fill(60, 69, 9);
    text("T", height/2 + 20, 90);
    fill(120, 69, 9);
    text("H", height/2 + 40, 90);
    fill(180, 69, 9);
    text("E", height/2 + 60, 90);
    fill(240, 69, 9);
    text("R", height/2 + 80, 90);
    fill(300, 69, 9);
    text("S", height/2 + 100, 90);
    fill(0, 0, 10);
  }
  popMatrix();
  hint(ENABLE_DEPTH_TEST);
  /*
     if(stopflag){
     text("Time:"+sec, 0, -height/4);
     }else{
     text("Time:"+nf(tmp_ms/1000.0, 1, 1), 0, -height/4);
     }
   */




  if(keyPressed){
    if(keyCode == LEFT) rot = rot - 0.02f;
    else if(keyCode == RIGHT) rot = rot + 0.02f;
    else if(keyCode == DOWN) cam_z = cam_z + 5;
    else if(keyCode == UP) cam_z = cam_z - 5;
    else if(key == ENTER) exit();
    else if(key == '1') changeMode(1);
    else if(key == '2') changeMode(2);
    else if(key == '3') changeMode(3);
    else if(key == '4') changeMode(4);
    else if(key == '5') changeMode(5);
  }

  for(int i=last_v_num;i<packet_count;i++){
    if(packets[i] == null){
      break;
    }
    if(packets[i].checkSec()){
      if(packets[i].visualizePacketFlow() == false){
        if(last_v_num < i) last_v_num = i;
      }
    }
    else break;
  }
  if(mode == 1) user.drawNode();
  else if(mode == 2) user.drawNode();
}

public void receive(byte[] data, String ip, int port){
  String [] cap_data = new String[10]; 
  data = subset(data, 0, data.length);
  String message = new String(data);

  //println(message);

  cap_data = split(message, ',');
  if(cap_data[8].equals("true")){
    System.out.println("\""+cap_data[1]+" "+cap_data[9]+"\" "+cap_data[3]+"("+cap_data[5]+") > "+cap_data[4]+"("+cap_data[6]+")");
  }else{
    System.out.println("\""+cap_data[1]+" "+cap_data[9]+"\" "+cap_data[4]+"("+cap_data[6]+") > "+cap_data[3]+"("+cap_data[5]+")");
  }
  cap_data[0] = str(total_count);
  total_count++;

  if(packet_count != 0){
    //if(packets[packet_count - 1].checkPre(cap_data[4], cap_data[6], cap_data[7], cap_data[8])){
    packets[packet_count] = new Packets(cap_data, user, myFont);
    packet_count++;
    //}
  }else{
    first_passed_time = Integer.parseInt(cap_data[7]);
    packets[packet_count] = new Packets(cap_data, user, myFont);
    packet_count++;
    difference += millis();
  }
}

/*
   class Addr_IP {
   String name;//\u540d\u524d  
   int count;

   Addr_IP(String pname){
   name = pname;
   count = 0;
   }
   void addCount(){
   count++;
   }
   void resetCount(){
   count = 0;
   }
   }
 */

class Node {
  float x, y, z;
  float dia;

  Node(float xpos, float ypos, float zpos, float diameter){
    x = xpos;
    y = ypos;
    z = zpos;
    dia = diameter;
  }

  public void drawNode(){
    noFill();
    pushMatrix();
    translate(x, y, z);
    stroke(235, 86, 8);
    strokeWeight(0.5f);
    sphere(dia);
    popMatrix();
  }

}

class Packets {
  int count;
  String protocol;
  int bytes;
  String my_ip;
  String srv_ip;
  int my_port;
  int srv_port;
  int pass_time;
  String addr_name;
  boolean trans_flag;
  String tcp_flag;
  float x, y, z;
  float dst_x, dst_y, dst_z;//\u30d1\u30b1\u30c3\u30c8\u304c\u5411\u304b\u3046\u306e\u5ea7\u6a19
  float src_x, src_y, src_z;//\u30d1\u30b1\u30c3\u30c8\u304c\u51fa\u3066\u304f\u308b\u5ea7\u6a19
  float p_size;
  boolean alive_flag;
  float f_x, f_y, f_z;
  float ip_x, ip_y, ip_z;
  float node_x, node_y, node_z;
  float port_x, port_y, port_z;
  int life;//\u63cf\u753b\u6642\u9593
  int lo_state;
  int red, green;
  PFont p_font;
  float rotz, roty;
  int create_time;

  Packets(String packets[], Node node, PFont font){
    count = Integer.parseInt(packets[0]);
    protocol = packets[1];
    bytes = Integer.parseInt(packets[2]);
    my_ip = packets[3];
    srv_ip = packets[4];
    my_port = Integer.parseInt(packets[5]);
    srv_port = Integer.parseInt(packets[6]);
    pass_time = Integer.parseInt(packets[7]) - first_passed_time;//\u6700\u521d\u306b\u9001\u3089\u308c\u3066\u304d\u305f\u30d1\u30b1\u30c3\u30c8\u3068\u306e\u5dee
    //addr_name = packets[8];
    trans_flag = Boolean.valueOf(packets[8]);
    tcp_flag = packets[9];
    life = 70;
    node_x = node.x;
    node_y = node.y;
    node_z = node.z;
    if(mode == 1 || mode == 2) mode1();
    else if(mode == 3 || mode == 4) mode3();
    else if(mode == 5) mode3();
    p_size = box_size/50;
    alive_flag = true;
    create_time = millis();
    red = bytes ;
    if(red > 255){
      red = 255;
    }
    p_font = font;


  }

  /*
     private boolean checkPre(String ip, String port, String time, String flag){
     int time_now = Integer.parseInt(time) - first_passed_time;
     int time_pre = pass_time;
     boolean flag2 = Boolean.valueOf(flag); 
     if(ip.equals(srv_ip) && port.equals(srv_port) && trans_flag == flag2 &&  time_pre +50 > time_now){
     println("cut\n\n\n\n");
     return false;
     }else{
     return true;
     }
     }
   */

  private boolean checkSec(){
    int now_time;
    if(stopflag) now_time = ms;
    else now_time = tmp_ms;
    if(now_time >= pass_time){
      return true;
    }else{
      return false;
    }
  } 

  private boolean visualizePacketFlow(){
    if(alive_flag){
      if(mode == 1 || mode == 3){
        if(protocol.equals("TCP")){
          if(tcp_flag.equals("SYN")){
            fill(300, 69, 9, red);
            stroke(300, 69, 9);
          }else if(tcp_flag.equals("SYN/ACK")){
            fill(30, 69, 9, red);
            stroke(30, 69, 9);
          }else if(tcp_flag.equals("ACK")){
            fill(180, 69, 9, red);
            stroke(180, 69, 9);
          }else if(tcp_flag.equals("RST")){
            fill(0, 69, 9, red);
            stroke(0, 69, 9);
          }else if(tcp_flag.equals("FIN")){
            fill(270, 69, 9, red);
            stroke(270, 69, 9);
          }else{
            fill(240, 69, 9, red);
            stroke(240, 69, 9);
          }
        }else if(protocol.equals("UDP")){
          fill(120, 69, 9, red);
          stroke(120, 69, 9);
        }else if(protocol.equals("ICMP")){
          fill(60, 69, 9, red);
          stroke(60, 69, 9);
        }else{
          fill(360, 0, 10, red);
          stroke(360, 0, 10);
        }
      }else if(mode == 2 || mode == 4 || mode == 5){
        if(my_port == 80 || my_port == 443){
          //http
          fill(300, 0, 10, red);
          stroke(300, 0, 10);
        }else{
          int this_hue = 330 * my_port / 65535 + 30;
          fill(this_hue, 69, 9, red);
          stroke(this_hue, 69, 9);
        }
      }



      //line(0, 0, 0, ip_x, ip_y, ip_z);
      noFill();
      drawRule();
      drawPrism();

      if(stopflag){
        x = x + f_x;
        y = y + f_y;
        z = z + f_z;
        if(life <= 0){
          alive_flag = false;
        }
        life--;
      }else{
        //world\u5ea7\u6a19\u3092window\u5ea7\u6a19\u306b\u5909\u63db\u3057\u3001\u30de\u30a6\u30b9\u3068\u5f53\u305f\u308a\u5224\u5b9a\u3092\u884c\u3046
      }
      return true;
    }else{
      return false;
    }
  }

  private void killFlag(){
    if(alive_flag) alive_flag = false;
  }

  private void mode1(){
    port_x = port_y = port_z = 0;
    set_ip_xyz();
    if(trans_flag){
      src_x = node_x;
      src_y = node_y;
      src_z = node_z;
      dst_x = ip_x;
      dst_y = ip_y;
      dst_z = ip_z;
      x = src_x;
      y = src_y;
      z = src_z;
      if(dst_z == -box_size/2 || dst_z == box_size/2){
        rotz = atan2(dst_z, dst_y);
        if(dst_z > 0 && dst_x > 0){
          rotz = -rotz;
        }else if(dst_z < 0 && dst_x < 0){
          rotz = -rotz;
        }
      }else{
        rotz = -atan2(dst_x, dst_y);
      }
      if(dst_z < 0){
        roty = PI*3/2 + atan2(dst_x, dst_z);
        if(dst_x < 0){
          rotz = -rotz;
        }
      }else{
        roty = PI/2 + atan2(dst_x, dst_z);
        if(dst_x > 0){
          rotz = -rotz;
        }
      }
    }else{
      src_x = ip_x;
      src_y = ip_y;
      src_z = ip_z;
      x = src_x;
      y = src_y;
      z = src_z;
      dst_x = node_x;
      dst_y = node_y;
      dst_z = node_z;
      if(z == -box_size/2 || z == box_size/2){
        rotz = atan2(z, y);
        if(z > 0 && x > 0){
          rotz = -rotz;
        }else if(z < 0 && x < 0){
          rotz = -rotz;
        }
      }else{
        rotz = -atan2(x, y);
      }
      if(z < 0){
        roty = PI/2 + atan2(x, z);
        if(x > 0){
          rotz = -rotz;
        }
      }else{
        roty = -PI/2 + atan2(x, z);
        if(x < 0){
          rotz = -rotz;
        }
      }
    }
    f_x = (dst_x - x)/PApplet.parseFloat(life);
    f_y = (dst_y - y)/PApplet.parseFloat(life);
    f_z = (dst_z - z)/PApplet.parseFloat(life);
  }

  private void mode2(){
    mode1();
  }

  private void mode3(){
    set_ip_xyz();
    set_port_xyz();
    if(trans_flag){
      src_x = port_x;
      src_y = port_y;
      src_z = port_z;
      x = src_x;
      y = src_y;
      z = src_z;
      dst_x = ip_x;
      dst_y = ip_y;
      dst_z = ip_z;
      if(dst_y > y) rotz = -atan2(dst_x - x, dst_y - y);
      else rotz = atan2(dst_x - x, y - dst_y) + PI;
      if(dst_z < z) roty = -PI/2 - atan2(dst_x - x, z - dst_z);
      else roty = -PI*3/2 + atan2(dst_x - x, dst_z - z);
    }else{
      src_x = ip_x;
      src_y = ip_y;
      src_z = ip_z;
      x = src_x;
      y = src_y;
      z = src_z;
      dst_x = port_x;
      dst_y = port_y;
      dst_z = port_z;
      if(dst_y > y) rotz = -atan2(x - dst_x, dst_y - y) + PI;
      else rotz = atan2(x - dst_x, y - dst_y);
      if(z < dst_z) roty = PI/2 - atan2(x - dst_x, dst_z - z);
      else roty = PI*3/2 + atan2(x - dst_x, z - dst_z);
    }
    f_x = (dst_x - x)/PApplet.parseFloat(life);
    f_y = (dst_y - y)/PApplet.parseFloat(life);
    f_z = (dst_z - z)/PApplet.parseFloat(life);
  }


  private void set_ip_xyz(){
    int [] div_addr;
    div_addr = PApplet.parseInt(split(srv_ip, "."));
    if(mode == 1 || mode == 2){
      if(div_addr[0] <= 63){
        ip_x = -box_size/2 + (div_addr[0]%8)*box_size/8 + (div_addr[2])*box_size/2048;
        ip_y = -box_size/2 + (div_addr[0]%8)*box_size/8 + (div_addr[1])*box_size/2048;
        ip_z = -box_size/2;
        lo_state = 0;
      }else if(div_addr[0] <= 127){
        ip_x = -box_size/2 + (div_addr[0]%8)*box_size/8 + (div_addr[2])*box_size/2048;
        ip_y = -box_size/2 + (div_addr[0]%8)*box_size/8 + (div_addr[1])*box_size/2048;
        ip_z = box_size/2;
        lo_state = 1;
      }else if(div_addr[0] <= 191){
        ip_x = -box_size/2;
        ip_y = -box_size/2 + (div_addr[0]%8)*box_size/8 + (div_addr[1])*box_size/2048;
        ip_z = -box_size/2 + (div_addr[0]%8)*box_size/8 + (div_addr[2])*box_size/2048;
        lo_state = 2;
      }else{
        ip_x = box_size/2;
        ip_y = -box_size/2 + (div_addr[0]%8)*box_size/8 + (div_addr[1])*box_size/2048;
        ip_z = -box_size/2 + (div_addr[0]%8)*box_size/8 + (div_addr[2])*box_size/2048;
        lo_state = 3;
      }
    }else if(mode == 3 || mode == 4){
      ip_x = -box_size/2;
      ip_y = -box_size/2 + div_addr[0] * box_size / 256;
      ip_z = -box_size/2 + div_addr[1] * box_size / 256;
    }
    else if(mode == 5){
      ip_x = -box_size/2;
      ip_y = -box_size/2 + div_addr[0] * div_addr[1] * box_size / 65535;
      ip_z = 0;
    }
  }

  private void set_port_xyz(){
    if(mode == 3 || mode == 4){
      port_x = box_size/2;
      port_y = -box_size/2 + (my_port / 256) * box_size / 256;
      port_z = -box_size/2 + (my_port % 256) * box_size / 256;
    }else if(mode == 5){
      port_x = box_size/2;
      port_y = -box_size/2 + my_port * box_size / 65535;
      port_z = 0;
    }
  }

  private void drawRule(){
       strokeWeight(0.8f);
       line(src_x, src_y, src_z, dst_x, dst_y, dst_z);
  /*

    hint(DISABLE_DEPTH_TEST);
    pushMatrix();
    translate(ip_x, ip_y, ip_z);
    PMatrix3D billboardMat = (PMatrix3D)g.getMatrix();
    billboardMat.m00 = billboardMat.m11 = billboardMat.m22 = 1;
    billboardMat.m01 = billboardMat.m02 = billboardMat.m10 = billboardMat.m12 = billboardMat.m20 = billboardMat.m21 = 0;

    resetMatrix();
    applyMatrix(billboardMat);
    fill(360, 0, 10);
    textFont(p_font, 20);
    textAlign(CENTER);
    text(srv_ip, 0, 0, 0);
    popMatrix();
    hint(ENABLE_DEPTH_TEST);

    /*
       fill(255);
       textFont(p_font);
       textAlign(CENTER);
       text(srv_ip, ip_x, ip_y, ip_z);
     */
  }

  private boolean cmp_p(String s_ip, int m_port, int s_port){
    if(s_ip.equals(srv_ip) && s_port == srv_port && m_port == my_port){
      return true;
    }else return false;
  }

  private void drawPrism(){
    int status = 0;

    /*
    if(count != 0 && tcp_flag.equals("ACK")){
      if(packets[count - 1].cmp_p(srv_ip, my_port, srv_port)){
        if(packets[count - 1].alive_flag){
          if(packets[count - 1].tcp_flag.equals("ACK")){
            status = 1;
          }
        }
      }
    }
    */
    if(status == 1){
      strokeWeight(0.8f);
      line(x, y, z, packets[count -1].x, packets[count -1].y, packets[count -1].z);
    }else{
      strokeWeight(3);
      float size = p_size;
      if(trans_flag){
        size = -size;
      }
      pushMatrix();
      translate(x, y, z);
      rotateY(roty);
      rotateZ(rotz);
      beginShape();
      vertex(0, -size, 0);
      vertex(-size/2, size, -size/2);
      vertex(size/2, size, -size/2);
      endShape(CLOSE);

      beginShape();
      vertex(0, -size, 0);
      vertex(-size/2, size, -size/2);
      vertex(-size/2, size, size/2);
      endShape(CLOSE);

      beginShape();
      vertex(0, -size, 0);
      vertex(size/2, size, size/2);
      vertex(size/2, size, -size/2);
      endShape(CLOSE);

      beginShape();
      vertex(0, -size, 0);
      vertex(-size/2, size, size/2);
      vertex(size/2, size, size/2);
      endShape(CLOSE);
      popMatrix();
    }
  }
}

public void keyReleased(){
  if(key == ' '){
    if(stopflag){
      push_ms = millis();
      tmp_ms = ms;
      stopflag = false;
    }else{
      stopflag = true;
      pop_ms = millis();
      difference += pop_ms - push_ms;
    }
  }
}

public void draw2D(){
  strokeWeight(3.5f);
  stroke(235, 86, 10);
  line(-box_size/2, -box_size/2, 0, box_size/2, -box_size/2, 0);
  line(box_size/2, -box_size/2, 0, box_size/2, box_size/2, 0);
  line(box_size/2, box_size/2, 0, -box_size/2, box_size/2, 0);
  line(-box_size/2, box_size/2, 0, -box_size/2, -box_size/2, 0);
}

public void reSetup(){
  packet_count = 0;
  last_count = 0;
  difference = millis();
}

public void changeMode(int num){
  mode = num;
  for(int i=last_v_num;i<packet_count;i++){
    if(packets[i] == null) break;
    /*
    if(packets[i].checkSec()){
      packets[i].killFlag();
    }
    */
    if(packets[i].alive_flag){
      if(mode == 3 || mode == 4) packets[i].mode3();
      else if(mode == 1 || mode == 2) packets[i].mode1();
      else if(mode == 5) packets[i].mode3();
    }
  }
}
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "processing_program" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
