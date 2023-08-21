//#define DEBUG

//instruction
#define ID_SET 0x00
#define DIR_GET 0x01
#define DIR_SET 0x02
#define IO_UPDATE 0x03
#define IN_GET 0x04
#define OUT_GET 0x05
#define REVERCE_MODE 0x06
#define BOARD_RESET 0x0F

//address
#define TO_ALL 0xFE
#define TO_MASTER 0xFF

//pin asign
const uint8_t PIN__ARRAY[] = { PC0,PC1, PC2, PC3, PC4, PC5, PC6, PC7 };//下位 - 上位
const uint8_t PIN__ARRAY_R[] = { PC7,PC6, PC5, PC4, PC3, PC2, PC1, PC0 };//下位 - 上位
uint8_t *IO_PIN__ARRAY;
//const uint8_t IO_PIN__ARRAY[] = { PC0, PD0, PA2, PA1, PD7, PD6, PD5, PD4, PC1, PC2, PC3, PC4, PC5, PC6, PC7, PD2, PD3};//下位 - 上位
const size_t IO_PIN__ARRAY_COUNT = (sizeof(IO_PIN__ARRAY) / sizeof(IO_PIN__ARRAY[0]));


String serial_rx = "";

uint16_t id = 0x00;
uint16_t dir = 0x0000;
uint16_t output = 0x0000;
uint16_t input = 0x0000;
void setup() {
  // put your setup code here, to run once:
  IO_PIN__ARRAY = PIN__ARRAY;
  Serial.begin(9600);
  for (size_t i = 0; i < IO_PIN__ARRAY_COUNT; i++) {
    pinMode(IO_PIN__ARRAY[i], INPUT);
  }
  Serial.print("\n");
  //*
  pinMode(PD2,OUTPUT);
  digitalWrite(PD2,HIGH);
  delay(40);
  digitalWrite(PD2,LOW);
  delay(40);
  digitalWrite(PD2,HIGH);
  delay(40);
  digitalWrite(PD2,LOW);
  //*/
}

void loop() {
  // put your main code here, to run repeatedly:
  while(1){//continue使いたかっただけ
    delay(1);//念のためのdelay なくても問題なく動作した
    serial_rx = "";//前回の受信データをクリア
/*
    Serial.print("id : ");
    Serial.println(id,HEX);
//*/
    while(serialReceive()){}//改行が来るまでserial_rxに受信データをためる
    
    //本処理開始
    if(serial_rx.length() != 10){//受信データサイズは10文字でなければデータの不良なので無視する
      continue;
    }
    //受信データから目的のデータを取り出す
    int to_id = hex_str_to_int(serial_rx.substring(0,2));//ID取得16進2桁
    int mode = hex_str_to_int(serial_rx.substring(3,5));//命令のモード取得16進2桁
    int value = hex_str_to_int(serial_rx.substring(6,10));//値取得16進2桁
    
    if(to_id != id && to_id != TO_ALL){//宛先が自身ではなく かつ 全体に向けてのものでなければ 受け取った命令を次のボードへ転送する
      data_stansfer(to_id,mode,value);
      continue;
    }
//*
    digitalWrite(PD2,HIGH);
    delay(1);
    digitalWrite(PD2,LOW);
//*/
    switch(mode){
      case ID_SET:
        //00 - 識別番号設定
        id = value;
/*
        status_print();
//*/
        data_stansfer(TO_ALL,mode,value+1);
        break;
      case DIR_GET:
        //01 - 入出力方向確認
/*
        status_print();
//*/
        data_stansfer(TO_MASTER,mode,dir);
        break;
      case DIR_SET:
        //02 - 入出力方向指定
        dir = value;
        pinMode_update(dir);
/*
        status_print();
//*/
        data_stansfer(TO_MASTER,mode,dir);
        break;
      case IO_UPDATE:
        //03 - 入出力
        output = value;
        //input = IO(output);
        input = IO_IN();
        IO_OUT();
/*
        status_print();
//*/
        data_stansfer(TO_MASTER,mode,input);
        break;
      case IN_GET:
        //04 - 入力
        input = IO_IN();
        data_stansfer(TO_MASTER,mode,input);
        break;
      case OUT_GET:
        //05 - 出力
        data_stansfer(TO_MASTER,mode,output);
        break;
      case REVERCE_MODE:
        //逆順モード
        if(value == 0){
          IO_PIN__ARRAY = PIN__ARRAY_R;
        }
        else{
          IO_PIN__ARRAY = PIN__ARRAY;
        }
        pinMode_update(dir);
        IO_OUT();
        data_stansfer(TO_MASTER,mode,dir);
      case BOARD_RESET:
        //04 - Reset
        id=0x00;
        dir=0x0000;
        output=0x0000;
        pinMode_update(dir);
        IO_OUT();
        if(to_id == TO_ALL){
          data_stansfer(TO_ALL,mode,value);
        }
        break;
      default:
        //Serial.print("Error");
        break;
    }
  }
}

//データを転送
void data_stansfer(uint16_t to_id, uint16_t mode, uint16_t value){
  if(to_id <= 0xFF && mode <= 0xFF, value <= 0xFFFF){
    char Buf[14];
    sprintf(Buf,"%02X-%02X-%04X",to_id,mode,value);
    Serial.println(Buf);
  }
}
//デバッグ用に内部の状態を出力するもの
void status_print(){
  char Buf[46];
  sprintf(Buf,"status : id:%02X,dir:%04X,in:%04X,out:%04X\n",id,dir,input,output);
  Serial.print(Buf);
}
//16進文字列を数値に 最大4桁
int hex_str_to_int(String str){
  char Buf[5];
  str.toCharArray(Buf, 5);
  return strtol(Buf,NULL,16);
}
//入出力の方向を変更する
void pinMode_update(uint16_t value){
  for(int i = 0,mask=1;i<IO_PIN__ARRAY_COUNT;i++,mask<<=1){
    pinMode(IO_PIN__ARRAY[i],mask&value?OUTPUT:INPUT);
/*
    Serial.print(IO_PIN__ARRAY[i]);
    Serial.print(" : ");
    Serial.println(mask&value?"OUTPUT":"INPUT");
//*/
  }
}
//入力
uint16_t IO_IN(){
  input = 0x0000;
  for(int i = 0,mask=1;i<IO_PIN__ARRAY_COUNT;i++,mask<<=1){
    int in = digitalRead((mask&dir) ? 0 : IO_PIN__ARRAY[i]);
    input |= in<<i;
  }
  return input;
}
void IO_OUT(){
  output = output & dir;
  for(int i = 0,mask=1;i<IO_PIN__ARRAY_COUNT;i++,mask<<=1){
    if((mask & dir) != 0){
      digitalWrite(IO_PIN__ARRAY[i],mask&output?HIGH:LOW);
    }
  }
}
//受信ルーチン
int serialReceive(){
  char c = Serial.read();
  if(c == '\r'){
    return 1;
  }
  if(c == '\n'){
    return 0;
  }
  if(c > 0){
    serial_rx += c;
  }
  return 1;
}