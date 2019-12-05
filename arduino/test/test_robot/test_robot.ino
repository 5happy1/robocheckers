
int button_pin = 8;
int x = 0;
int n = 1;

void setup() {
  pinMode(button_pin, INPUT);
  Serial2.begin(115200);
  Serial.begin(9600);
}

void loop() {

  if (digitalRead(button_pin)) {
     
//    Serial2.println("#0 M201 N0");
//    delay(100);
//    Serial2.println("#1 M201 N1");
//    delay(100);
//    Serial2.println("#2 M201 N2");
//    delay(100);
//    Serial2.println("#3 M201 N3");
//    delay(100);
    //Serial2.println("#3 G0 X0 Y0 Z30 F40");
    Serial2.print("#2 G202 N0 V180\n");
//    Serial2.print("#");
//    Serial2.print(n);
//    Serial2.print(" G0 X");
//    Serial2.print(x);
//    Serial2.println(" Y50 Z20 F10");
//    x += 20;
//    n++;
    delay(1000);
    String thing = Serial2.readStringUntil('\n');
    Serial.println(thing);
  }

}
