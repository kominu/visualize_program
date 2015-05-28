/*
 * Processingを用いたcsvファイルの可視化
 * プロセスではなくIPアドレスを通信先として扱う
 * mbpではframerate100が限界の模様
 * スペースキーで一時停止可
 */
/*
 * 文字かぶりの回避についての案
 * 文字が生成されている間、その領域を変数としてインスタンスに持たせる
 * 文字生成時に他のインスタンスの領域とかぶらないか判定をし、
 * 被った場合は上にずらす
 */
/* 
 * 同期の案
 * キャプチャ側はUDPで常に送り続ける
 * 可視化側ではUDPをキャッチしたらキューのリストに追加する
 * インスタンス生成と可視化実行のしおり的な変数を用意する
 * 1つ目のパケットの持つ時間との差を基準に表示していく
 * 前のパケットと通信先のIP, portが同じで10msいないのものは描画しない
 */

import processing.opengl.*;
import hypermedia.net.*;

int row_length;//配列の長さ
int max_time;//キャプチャ経過時間の最大値
String [][] csv;//csvを格納する二次元配列
/* 送られてくるパケットについて */
/* 
 * 0:キャプチャ時の通し番号
 * 1:プロトコル
 * 2:バイト
 * 3:IP(ホスト)
 * 4:IP(通信先)
 * 5:ポート(ホスト)
 * 6:ポート(通信先)
 * 7:キャプチャ開始からの経過時間
 * 8:受信か送信か(送信ならtrue)
 * 9:TCPフラグ
 * 以上の計9のカラムを持つ
 */

Node user;
PFont myFont;
PFont myFont2;
Packets [] packets = new Packets[1000000];
int packet_count = 0;
int last_count = 0;//最後に読み込んだパケットのカウント(csv[?][0])
int push_ms;//一時停止時保存用
int pop_ms;//一時停止解除時
int tmp_ms;//一時停止時表示用
int ms;
int difference;
int now_v_count;
boolean stopflag = true;
float rot = 0;
int draw_size;
float cam_z;
int box_size;
UDP udp;
int first_passed_time, last_v_num;//１つ目のパケットの持つ経過時間, インスタンス生成のカウント, ヴィジュアライズのカウント
String IP = "54.65.112.212";//kominu
//String IP2 = "52.68.6.213";//proxy
//String IP = "192.168.33.56";
String IP2 = "133.27.67.89";
int PORT = 20000;
int mode = 3;
int total_count = 0;
boolean realtime = true;
boolean receive_flag = false;

void setup(){
  size(displayWidth*4/5, displayHeight*9/10, OPENGL);
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
  box_size = displayHeight/2;

  udp = new UDP(this, 30000);
  udp.listen(true);

  first_passed_time = last_v_num = difference = 0;

  user = new Node(0, 0, 0, box_size/10);
  if(udp.send("connect request",IP,PORT) && udp.send("connect request",IP2,PORT)){
    System.out.println("Start visualizing!");
  }else{
    println("cannot connect "+IP+":"+PORT);
    exit();
  }
}



void draw(){

  background(245, 85, 1);
  camera(width/2.0, height/2.0, (height/2.0) / tan(PI*60.0 / 360.0) + cam_z, width/2.0, height/2.0, 0, 0, 1, 0);
  lights();
  boolean drawflag = true;
  PMatrix3D billboardMat;
  ms = millis() - difference;
  String sec = nf(ms/1000.0, 1, 1);
  translate(height/2, height/2);
  rotateY(rot);
  noFill();
  strokeWeight(3.5);
  stroke(235, 86, 10);
  if(mode != 6){
    draw3D();
  }else{
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
  if(realtime) text("Realtime Visualization", 0, -110);
  else text("Log Visualization", 0, -110);
  if(mode == 1) text("MODE1: IP, PROTOCOL", 0, -80);
  else if(mode == 2) text("MODE2: IP, PORT", 0, -80);
  else if(mode == 3) text("MODE3: IP, PORT(ver2)", 0, -80);
  else if(mode == 4) text("MODE4: IP, PORT(ver2-2)", 0, -80);
  else if(mode == 5) text("MODE5: IP, PORT(ver3)", 0, -80);
  else if(mode == 6) text("MODE5: IP, PORT(2d)", 0, -80);
  if(stopflag) text("Time:"+sec, 0, 0);
  else text("Time:"+nf(tmp_ms/1000.0, 1, 1), 0, 0);
  textAlign(LEFT);
  if(mode == 1 || mode == 3 || mode == 4 || mode == 6){
    fill(0, 0, 10);
    text("PROTOCOL", height*0.45, -60);
    fill(300, 69, 9);
    text("TCP_SYN", height*0.45, 0);
    fill(30, 69, 9);
    text("TCP_SYN/ACK", height*0.45, 30);
    fill(180, 69, 9);
    text("TCP_ACK", height*0.45, 60);
    fill(0, 69, 9);
    text("TCP_RST", height*0.45, 90);
    fill(270, 69, 9);
    text("TCP_FIN", height*0.45, 120);
    fill(240, 69, 9);
    text("TCP_OTHER", height*0.45, 150);
    fill(120, 69, 9);
    text("UDP", height*0.45, 210);
    fill(60, 69, 9);
    text("ICMP", height*0.45, 270);
    fill(0, 0, 10);
    text("OTHERS", height*0.45, 330);
  }else if(mode == 2 || mode == 5){
    fill(0, 0, 10);
    text("PORT", height*0.45, -60);
    fill(300, 0, 10);
    text("http", height*0.45, 0);
    fill(300, 0, 10);
    text("https", height*0.45, 30);
    fill(0, 69, 9);
    text("O", height*0.45, 90);
    fill(60, 69, 9);
    text("T", height*0.45 + 20, 90);
    fill(120, 69, 9);
    text("H", height*0.45 + 40, 90);
    fill(180, 69, 9);
    text("E", height*0.45 + 60, 90);
    fill(240, 69, 9);
    text("R", height*0.45 + 80, 90);
    fill(300, 69, 9);
    text("S", height*0.45 + 100, 90);
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

  if(ms % 60000 > 0 && ms % 60000 < 60){
    if(udp.send("connect request",IP,PORT) && udp.send("connect request",IP2,PORT)){
      System.out.println("send udp");
    }
  }

  if(keyPressed){
    if(keyCode == LEFT) rot = rot - 0.02;
    else if(keyCode == RIGHT) rot = rot + 0.02;
    else if(keyCode == DOWN) cam_z = cam_z + 5;
    else if(keyCode == UP) cam_z = cam_z - 5;
    else if(key == ENTER) exit();
    else if(key == '1') changeMode(1);
    else if(key == '2') changeMode(2);
    else if(key == '3') changeMode(3);
    else if(key == '4') changeMode(4);
    else if(key == '5') changeMode(5);
    else if(key == '6') changeMode(6);
  }

  for(int i=last_v_num;i<packet_count;i++){
    if(packets[i] == null){
      break;
    }
    if(packets[i].checkSec()){
      if(packets[i].visualizePacketFlow() == false){
        if(last_v_num < i) last_v_num = i-1;
      }
    }else{
      if(!realtime && mode == 3 && i != 0){
        if(packets[i].retSec() - packets[i-1].retSec() > 10000){
          System.out.println("go next");
          difference = difference - packets[i].retSec() + packets[i-1].retSec();
          //ms += packets[i].retSec() - packets[i-1].retSec();
        }
      }
      break;
    }
  }
  if(mode == 1) user.drawNode();
  else if(mode == 2) user.drawNode();
  if(!receive_flag) receive_flag = true;
}

void receive(byte[] data, String ip, int port){
  if(receive_flag){
    String [] cap_data = new String[10]; 
    data = subset(data, 0, data.length);
    String message = new String(data);

    //println(message);
    if(message.equals("offline")) realtime = false;
    else{
      cap_data = split(message, ',');
      if(cap_data[8].equals("true")){
        //System.out.println("\""+cap_data[1]+" "+cap_data[9]+"\" "+cap_data[3]+"("+cap_data[5]+") > "+cap_data[4]+"("+cap_data[6]+")");
      }else{
        //System.out.println("\""+cap_data[1]+" "+cap_data[9]+"\" "+cap_data[4]+"("+cap_data[6]+") > "+cap_data[3]+"("+cap_data[5]+")");
      }
      cap_data[0] = str(total_count);
      total_count++;

      if(total_count >= 1000000){
        packet_count = 0;
        last_v_num = 0;
      }

      if(total_count > 1){
        //if(packets[packet_count - 1].checkPre(cap_data[4], cap_data[6], cap_data[7], cap_data[8])){
        packets[packet_count] = new Packets(cap_data, user, myFont);
        packet_count++;
        //}
      }else{
        first_passed_time = Integer.parseInt(cap_data[7]);
        packets[packet_count] = new Packets(cap_data, user, myFont);
        packet_count++;
        difference = millis();
      }
    }
  }
}

/*
   class Addr_IP {
   String name;//名前  
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

  void drawNode(){
    noFill();
    pushMatrix();
    translate(x, y, z);
    stroke(235, 86, 8);
    strokeWeight(0.5);
    sphere(dia);
    popMatrix();
  }

}

class Packets {
  int count;
  String protocol;
  int bytes;
  String my_ip;
  String src_ip;
  int my_port;
  int src_port;
  int pass_time;
  String addr_name;
  boolean trans_flag;
  String tcp_flag;
  float x, y, z;
  float dst_x, dst_y, dst_z;//パケットが向かうの座標
  float src_x, src_y, src_z;//パケットが出てくる座標
  float p_size;
  boolean alive_flag;
  float f_x, f_y, f_z;
  float ip_x, ip_y, ip_z;
  float node_x, node_y, node_z;
  float port_x, port_y, port_z;
  int life;//描画時間
  int lo_state;
  int red, green;
  PFont p_font;
  float rotz, roty;
  int create_time;
  boolean print_flag;

  Packets(String packets[], Node node, PFont font){
    count = Integer.parseInt(packets[0]);
    protocol = packets[1];
    bytes = Integer.parseInt(packets[2]);
    my_ip = packets[3];
    src_ip = packets[4];
    my_port = Integer.parseInt(packets[5]);
    src_port = Integer.parseInt(packets[6]);
    pass_time = Integer.parseInt(packets[7]) - first_passed_time;//最初に送られてきたパケットとの差
    //addr_name = packets[8];
    trans_flag = Boolean.valueOf(packets[8]);
    tcp_flag = packets[9];
    life = 70;
    node_x = node.x;
    node_y = node.y;
    node_z = node.z;
    if(mode == 1 || mode == 2) mode1();
    else if(mode == 3 || mode == 4 || mode == 5) mode3();
    else if(mode == 6) mode3();
    p_size = box_size/50;
    alive_flag = true;
    create_time = millis();
    red = bytes ;
    if(red > 255){
      red = 255;
    }
    p_font = font;
    print_flag = true;


  }

  /*
     private boolean checkPre(String ip, String port, String time, String flag){
     int time_now = Integer.parseInt(time) - first_passed_time;
     int time_pre = pass_time;
     boolean flag2 = Boolean.valueOf(flag); 
     if(ip.equals(src_ip) && port.equals(src_port) && trans_flag == flag2 &&  time_pre +50 > time_now){
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

  private int retSec(){
    return pass_time;
  }

  private boolean visualizePacketFlow(){
    if(alive_flag){
      if(print_flag){
        now_v_count++;
        if(protocol.equals("TCP")) System.out.println("\""+protocol+" "+tcp_flag+"\" "+my_ip+"("+my_port+") > "+src_ip+"("+src_port+")");
        else System.out.println("\""+protocol+"\" "+my_ip+"("+my_port+") > "+src_ip+"("+src_port+")");
        print_flag = false;
      }
      if(mode == 1 || mode == 3 || mode == 4 || mode == 6){
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
      }else if(mode == 2 || mode == 5){
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
      //drawRule();
      drawPrism();
      drawText();
      System.out.println(now_v_count);


      if(stopflag){
        x = x + f_x;
        y = y + f_y;
        z = z + f_z;
        if(life <= 0){
          now_v_count--;
          alive_flag = false;
        }
        life--;
      }else{
        //world座標をwindow座標に変換し、マウスと当たり判定を行う
      }
      return true;
    }else{
      if(!realtime && count == total_count-1){
        System.out.println("finish visualizing log file");
        exit();
      }
      return false;
    }
  }

  private void drawText(){
    if(now_v_count < 150){
      textSize(box_size/25);
      if(!trans_flag){
        text(src_ip, src_x, src_y, src_z);
        text(str(my_port), dst_x, dst_y, dst_z);
      }else{ 
        text(str(my_port), src_x, src_y, src_z);
        text(src_ip, dst_x, dst_y, dst_z);
      }
      /* 目がチカチカする
      if(now_v_count < 50){
        hint(DISABLE_DEPTH_TEST);
        pushMatrix();
        translate(src_x, src_y, src_z);
        PMatrix3D billboardMat = (PMatrix3D)g.getMatrix();
        billboardMat.m00 = billboardMat.m11 = billboardMat.m22 = 1;
        billboardMat.m01 = billboardMat.m02 = billboardMat.m10 = billboardMat.m12 = billboardMat.m20 = billboardMat.m21 = 0;

        resetMatrix();
        applyMatrix(billboardMat);
        if(!trans_flag){
          text(src_ip, 0, 0, 0);
        }else{ 
          text(str(my_port), 0, 0, 0);
        }
        popMatrix();
        hint(ENABLE_DEPTH_TEST);


        hint(DISABLE_DEPTH_TEST);
        pushMatrix();
        translate(dst_x, dst_y, dst_z);
        PMatrix3D billboardMat2 = (PMatrix3D)g.getMatrix();
        billboardMat.m00 = billboardMat.m11 = billboardMat.m22 = 1;
        billboardMat.m01 = billboardMat.m02 = billboardMat.m10 = billboardMat.m12 = billboardMat.m20 = billboardMat.m21 = 0;

        resetMatrix();
        applyMatrix(billboardMat);
        if(trans_flag){
          text(str(my_port), 0, 0, 0);
        }else{ 
          text(src_ip, 0, 0, 0);
        }
        popMatrix();
        hint(ENABLE_DEPTH_TEST);
      }
      */
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
    f_x = (dst_x - x)/float(life);
    f_y = (dst_y - y)/float(life);
    f_z = (dst_z - z)/float(life);
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
    f_x = (dst_x - x)/float(life);
    f_y = (dst_y - y)/float(life);
    f_z = (dst_z - z)/float(life);

  }


  private void set_ip_xyz(){
    int [] div_addr;
    div_addr = int(split(src_ip, "."));
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
    }else if(mode == 3 || mode == 4 || mode == 5){
      ip_x = -box_size/2;
      ip_y = -box_size/2 + div_addr[0] * box_size / 256;
      ip_z = -box_size/2 + div_addr[1] * box_size / 256;
    }
    else if(mode == 6){
      ip_x = -box_size/2;
      ip_y = -box_size/2 + div_addr[0] * div_addr[1] * box_size / 65535;
      ip_z = 0;
    }
  }

  private void set_port_xyz(){
    if(mode == 3 || mode == 4 || mode == 5){
      port_x = box_size/2;
      port_y = -box_size/2 + (my_port / 256) * box_size / 256;
      port_z = -box_size/2 + (my_port % 256) * box_size / 256;
    }else if(mode == 6){
      port_x = box_size/2;
      port_y = -box_size/2 + my_port * box_size / 65535;
      port_z = 0;
    }
  }

  private void drawRule(){
    strokeWeight(0.8);
    if(protocol.equals("TCP")) line(src_x, src_y, src_z, dst_x, dst_y, dst_z);
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
       text(src_ip, 0, 0, 0);
       popMatrix();
       hint(ENABLE_DEPTH_TEST);

    /*
    fill(255);
    textFont(p_font);
    textAlign(CENTER);
    text(src_ip, ip_x, ip_y, ip_z);
     */
  }


  private boolean cmp_p(String s_ip, int m_port, int s_port){
    if(s_ip.equals(src_ip) && s_port == src_port && m_port == my_port){
      return true;
    }else return false;
  }

  private void drawPrism(){
    int status = 0;

    /*
       if(count != 0 && tcp_flag.equals("ACK")){
       if(packets[count - 1].cmp_p(src_ip, my_port, src_port)){
       if(packets[count - 1].alive_flag){
       if(packets[count - 1].tcp_flag.equals("ACK")){
       status = 1;
       }
       }
       }
       }
     */
    if(status == 1){
      strokeWeight(0.8);
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

void keyReleased(){
  if(key == ' '){
    if(stopflag){
      push_ms = millis();
      tmp_ms = ms;
      stopflag = false;
    }else{
      stopflag = true;
      pop_ms = millis();
      if(realtime && mode == 3) System.out.println("don't fix time difference");
      else difference += pop_ms - push_ms;
    }
  }
}

void draw3D(){
  strokeWeight(3.5);
  stroke(235, 86, 10);
  line(-box_size/2, -box_size/2, -box_size/2, -box_size/2, box_size/2, -box_size/2);
  line(-box_size/2, box_size/2, -box_size/2, -box_size/2, box_size/2, box_size/2);
  line(-box_size/2, box_size/2, box_size/2, -box_size/2, -box_size/2, box_size/2);
  line(-box_size/2, -box_size/2, box_size/2, -box_size/2, -box_size/2, -box_size/2);

  line(box_size/2, -box_size/2, -box_size/2, box_size/2, box_size/2, -box_size/2);
  line(box_size/2, box_size/2, -box_size/2, box_size/2, box_size/2, box_size/2);
  line(box_size/2, box_size/2, box_size/2, box_size/2, -box_size/2, box_size/2);
  line(box_size/2, -box_size/2, box_size/2, box_size/2, -box_size/2, -box_size/2);
}
void draw2D(){
  strokeWeight(3.5);
  stroke(235, 86, 10);
  line(-box_size/2, -box_size/2, 0, box_size/2, -box_size/2, 0);
  line(box_size/2, -box_size/2, 0, box_size/2, box_size/2, 0);
  line(box_size/2, box_size/2, 0, -box_size/2, box_size/2, 0);
  line(-box_size/2, box_size/2, 0, -box_size/2, -box_size/2, 0);
}

void reSetup(){
  packet_count = 0;
  last_count = 0;
  difference = millis();
}

void changeMode(int num){
  mode = num;
  for(int i=last_v_num;i<packet_count;i++){
    if(packets[i] == null) break;
    /*
       if(packets[i].checkSec()){
       packets[i].killFlag();
       }
     */
    if(packets[i].alive_flag){
      if(mode == 3 || mode == 4 || mode == 5) packets[i].mode3();
      else if(mode == 1 || mode == 2) packets[i].mode1();
      else if(mode == 6) packets[i].mode3();
    }
  }
}
