/*
 * Processingを用いたcsvファイルの可視化
 * プロセスではなくIPアドレスを通信先として扱う
 * mbpではframerate100が限界の模様
 * スペースキーで一時停止可
 */
/*
 * 文字かぶりの回避について
 * 文字が生成されている間、その領域を変数としてインスタンスに持たせる
 * 文字生成時に他のインスタンスの領域とかぶらないか判定をし、
 * 被った場合は上にずらす
 */

import processing.opengl.*;

int row_length;//配列の長さ
int max_time;//キャプチャ経過時間の最大値
String [][] csv;//csvを格納する二次元配列
/* csvのカラムについて */
/* 
 * 0:キャプチャ時の通し番号
 * 1:プロトコル
 * 2:バイト
 * 3:IP(ホスト)
 * 4:IP(通信先)
 * 5:ポート(source)
 * 6:ポート(destination)
 * 7:キャプチャ開始からの経過時間
 * //8:プロセス名
 * 8:受信か送信か(送信ならtrue)
 * 9:パケットを絵画したかどうか（したらtrueに、デフォルトfalse)
 * 以上の計9のカラムを持つ
 */

String [] addr_name;
Addr_IP [] ip_addrs = new Addr_IP[10000];
Node user;
PFont myFont;
PFont myFont2;
boolean visualize_flag = true;//一度だけビジュアライズを実行
boolean [] sec_flag;//millis()で秒ごとにフラグをON(OFF)にしていく
Packets [] packets;
int packet_count = 0;
int last_count = 0;//最後に読み込んだパケットのカウント(csv[?][0])
int push_ms;//一時停止時保存用
int pop_ms;//一時停止解除時
int tmp_ms;//一時停止時表示用
int ms;
int difference;
boolean stopflag = true;
float rot = 0;
int draw_size;
float cam_z;
int box_size;

void setup(){
	size(750, 750, OPENGL);
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

	/* csvファイルを扱うための設定 */
	/* csvファイル一行あたりの要素数を取得 */
  System.out.println("Now loading...");
	int csvWidth = 0;//csvファイル１行あたりの要素数
	String [] lines = loadStrings("./cap_data.csv");

	for(int i=0;i<lines.length;i++){
		String [] chars = split(lines[i], ",");
		if(chars.length > csvWidth){
			csvWidth = chars.length;
		}
	}

	/* csvファイルを配列csvに落としこむ */
	row_length = lines.length;
	csv = new String [row_length][csvWidth];
	for(int i=0;i<row_length;i++){
		String [] temp_columns = new String [lines.length];
		temp_columns = split(lines[i], ",");
		for(int j=0;j<temp_columns.length;j++){
			csv[i][j] = temp_columns[j];
		}
		for(int k=0;k<i;k++){
			if(csv[i][4].equals(csv[k][4])){
				break;
			}else if(k == i -1){
				addr_num++;
			}
		}
	}

  packets = new Packets[row_length + 1];

	addr_name = new String [addr_num];
	for(int i=0;i<csv.length;i++){
		if(count == 0){
			addr_name[count] = csv[i][4];
			count++;
		}else{
			for(int j=0;j<count;j++){
				if(addr_name[j].equals(csv[i][4])){
					break;
				}else if(j == count - 1){
					addr_name[count] = csv[i][4];
					count++;
				}
			}
		}
	}

	System.out.println("----------------------------------------");
  System.out.println("IP addresses");
	for(int i=0;i<addr_name.length;i++){
		System.out.println(i+":"+addr_name[i]);
	}
	System.out.println("\n"+addr_name.length+" addresses and "+csv.length+" packets will be drawn.");

	max_time = Integer.parseInt(csv[csv.length - 1][7]) + 3000;
	sec_flag = new boolean[max_time+50];
	for(int i=0;i<sec_flag.length;i++){
		sec_flag[i] = true;
	}
	/* オブジェクトを生成 */
	float tmp_width, tmp_height;
	for(int i=0;i<addr_name.length;i++){
		ip_addrs[i] = new Addr_IP(addr_name[i]);
	}
	user = new Node(0, 0, 0, box_size/10);
	System.out.println("----------------------------------------");
  System.out.println("Finish loading. ("+millis()/1000+"sec)");
	System.out.println("Start visualizing!\n");
  difference = millis();
}



void draw(){
	background(245, 85, 1);
  camera(width/2.0, height/2.0, (height/2.0) / tan(PI*60.0 / 360.0) + cam_z, width/2.0, height/2.0, 0, 0, 1, 0);
  lights();
  boolean drawflag = true;
	ms = millis() - difference;
	String sec = nf(ms/1000.0, 1, 1);
	translate(width/2, height/2);
  rotateY(rot);
  user.drawNode();
  noFill();
  strokeWeight(3.5);
  stroke(235, 86, 10);
  box(box_size);
	textFont(myFont);
	fill(360, 0, 10);
	textAlign(CENTER);
  hint(DISABLE_DEPTH_TEST);
  pushMatrix();
  translate(0, -height/4, 0);
  PMatrix3D billboardMat = (PMatrix3D)g.getMatrix();
  billboardMat.m00 = billboardMat.m11 = billboardMat.m22 = 1;
  billboardMat.m01 = billboardMat.m02 = billboardMat.m10 = billboardMat.m12 = billboardMat.m20 = billboardMat.m21 = 0;

  resetMatrix();
  applyMatrix(billboardMat);
  if(stopflag){
	text("Time:"+sec, 0, 0);
  }else{
	text("Time:"+nf(tmp_ms/1000.0, 1, 1), 0, 0);
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
    if(keyCode == LEFT){
      rot = rot - 0.02;
    }else if(keyCode == RIGHT){
      rot = rot + 0.02;
    }else if(keyCode == DOWN){
      cam_z = cam_z + 5;
    }else if(keyCode == UP){    
        cam_z = cam_z - 5;
    }else if(key == ENTER){
      exit();
    }
  }

	if(visualize_flag && stopflag){
		if(sec_flag[ms]){
			for(int j=last_count;j<csv.length;j++){
				if(Integer.parseInt(csv[j][7]) <= ms && csv[j][9].equals("false")){
					for(int k=0;k<addr_name.length;k++){

						if(csv[j][4].equals(addr_name[k])){
							if(csv[j][8].equals("true")){
                System.out.println(sec+" sec:"+"\""+csv[j][1]+"\" "+csv[j][3]+"("+csv[j][5]+") > "+csv[j][4]+"("+csv[j][6]+")");
                //System.out.println(sec+" sec:"+"\""+csv[j][1]+"\" "+csv[j][3]+"("+csv[j][5]+") > "+csv[j][4]+"("+csv[j][6]+") - "+ip_addrs[k].count+" times");
							}else{
                System.out.println(sec+" sec:"+"\""+csv[j][1]+"\" "+csv[j][4]+"("+csv[j][6]+") > "+csv[j][3]+"("+csv[j][5]+")");
                //System.out.println(sec+" sec:"+"\""+csv[j][1]+"\" "+csv[j][4]+"("+csv[j][6]+") > "+csv[j][3]+"("+csv[j][5]+") - "+ip_addrs[k].count+" times");
							}

              if(j == 0){
              ip_addrs[k].addCount();
						  packets[packet_count] = new Packets(csv[j], user, ip_addrs[k], myFont);
              packet_count++;
              }else if(csv[j][4].equals(csv[j-1][4]) && csv[j][8].equals(csv[j-1][8]) && Integer.parseInt(csv[j][7]) < Integer.parseInt(csv[j-1][7]) + 10){
                //時間とipアドレスと送受信フラグを比較
                //直前のデータと全て異なっている場合のみインスタンス生成
                //System.out.println("kill:"+csv[j][7]+", "+csv[j-1][7]);
              }else{
              ip_addrs[k].addCount();
						  packets[packet_count] = new Packets(csv[j], user, ip_addrs[k], myFont);
              packet_count++;
              }
              csv[j][9] = "true";
							last_count = Integer.parseInt(csv[j][0]) - 1;
							break;
						}
					}
				}else if(Integer.parseInt(csv[j][7]) > ms){
					break;
				}
			}
		}
		sec_flag[ms] = false;
		if(ms >= max_time){
			//visualize_flag = false;
			System.out.println("Finish Visualizing");
      reSetup();
		}
	}
	for(int i=0;i<packet_count;i++){
    if(packets[i] == null){
      break;
    }
		packets[i].visualizePacketFlow();
	}
}

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
	String count;
	String protocol;
	String bytes;
	String my_ip;
	String srv_ip;
	String my_port;
	String srv_port;
	String pass_time;
	String addr_name;
	boolean trans_flag;
	float x, y, z;
	float dst_x, dst_y, dst_z;
	float p_size;
	boolean alive_flag;
	float f_x, f_y, f_z;
  float ip_x, ip_y, ip_z;
  int life;//描画時間
  int lo_state;
  int red, green;
  PFont p_font;
  float rotz, roty;
  int create_time;

	Packets(String packets[], Node node, Addr_IP ip_addr, PFont font){
		count = packets[0];
		protocol = packets[1];
		bytes = packets[2];
		my_ip = packets[3];
		srv_ip = packets[4];
		my_port = packets[5];
		srv_port = packets[6];
		pass_time = packets[7];
		//addr_name = packets[8];
		trans_flag = Boolean.valueOf(packets[8]);
    life = 50;
    set_ip_xyz();
		if(trans_flag){
			x = node.x;
			y = node.y;
      z = node.z;
			dst_x = ip_x;
			dst_y = ip_y;
      dst_z = ip_z;
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
      x = ip_x;
      y = ip_y;
      z = ip_z;
			dst_x = node.x;
			dst_y = node.y;
      dst_z = node.z;
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
    p_size = box_size/50;
    alive_flag = true;
    create_time = millis();
    f_x = (dst_x - x)/float(life);
    f_y = (dst_y - y)/float(life);
    f_z = (dst_z - z)/float(life);
    red = ip_addr.count/5;
    if(red > 255){
      red = 255;
    }
    p_font = font;


	}

	void visualizePacketFlow(){
		if(alive_flag){
			if(protocol.equals("TCP")){
				fill(300, 69, 9, red);
				stroke(300, 69, 9);
      }else if(protocol.equals("UDP")){
				fill(180, 69, 9, red);
				stroke(180, 69, 9);
			}else if(protocol.equals("ICMP")){
        fill(69, 69, 9, red);
        stroke(69, 69, 9);
      }else{
        fill(360, 0, 10, red);
        stroke(360, 100, 10);
      }
     
    strokeWeight(0.8);
      //line(0, 0, 0, ip_x, ip_y, ip_z);
      strokeWeight(3);
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
        //world座標をwindow座標に変換し、マウスと当たり判定を行う
        drawRule();
      }
    }
  }

  private void set_ip_xyz(){
    int [] div_addr;
		div_addr = int(split(srv_ip, "."));
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
  }

  private void drawRule(){
    /*
    strokeWeight(0.8);
    line(0, 0, 0, ip_x, ip_y, ip_z);
    strokeWeight(1.3);
    stroke(red, green, 0, 30);
    if(lo_state == 0){
      line(-box_size/2, ip_y, ip_z, box_size/2, ip_y, ip_z);
      line(ip_x, -box_size/2, ip_z, ip_x, box_size/2, ip_z);
    }else if(lo_state == 1){
      line(-box_size/2, ip_y, ip_z, box_size/2, ip_y, ip_z);
      line(ip_x, -box_size/2, ip_z, ip_x, box_size/2, ip_z);
    }else if(lo_state == 2){
      line(ip_x, -box_size/2, ip_z, ip_x, box_size/2, ip_z);
      line(ip_x, ip_y, -box_size/2, ip_x, ip_y, box_size/2);
    }else{
      line(ip_x, -box_size/2, ip_z, ip_x, box_size/2, ip_z);
      line(ip_x, ip_y, -box_size/2, ip_x, ip_y, box_size/2);
    }
    */
    /* 重い
    noFill();
    pushMatrix();
    translate(ip_x, ip_y, ip_z);
    sphere(p_size/4);
    popMatrix();
    */

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

  private void drawPrism(){
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

void keyReleased(){
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
void reSetup(){
	for(int i=0;i<sec_flag.length;i++){
		sec_flag[i] = true;
	}
  for(int i=0;i<csv.length;i++){
    csv[i][9] = "false";
  }
  for(int i=0;i<ip_addrs.length;i++){
    if(ip_addrs[i] != null){
      ip_addrs[i].resetCount();
    }else{
      System.out.println("null : "+i);
    }
  }
  packets = new Packets[row_length + 1];
  packet_count = 0;
  last_count = 0;
  difference = millis();
}
