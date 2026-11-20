# Smart Room Presence

แอป Flutter สำหรับแสดงข้อมูลจากอุปกรณ์ตรวจสภาพห้อง Smart Room Presence ที่ใช้ ESP32-C6, SCD40, HDC2080, VEML7700 และ radar presence sensor

## ขอบเขตของโปรเจกต์

แอปแสดงข้อมูลที่อุปกรณ์วัดได้จริง ได้แก่ CO₂, อุณหภูมิ, ความชื้น, แสง, presence และสถานะการเชื่อมต่อ นอกจากนี้ยังมีโหมด Explore Demo สำหรับนำเสนอหน้าจอโดยไม่ต้องมีบอร์ดจริง

ระบบ BLE ใช้สำหรับส่ง Wi-Fi 2.4 GHz ให้บอร์ด ส่วน telemetry ของบอร์ดส่งขึ้น ThingsBoard ผ่าน MQTT

## เปิดโปรเจกต์

ต้องติดตั้ง Flutter stable และ Dart ก่อน จากนั้นรัน:

```bash
cd app
flutter pub get
flutter run
```

สำหรับดูหน้าจอโดยไม่ใช้ฮาร์ดแวร์ ให้เลือก **Explore Demo** ที่หน้า Login

## โครงสร้างหลัก

```text
app/
├── lib/                 Flutter application
├── functions/            optional Firebase bridge
├── assets/               application assets
├── ios/ macos/ web/      Flutter platform targets
└── test/                 widget tests
```

## การทำงานกับข้อมูลจริง

เฟิร์มแวร์ส่ง telemetry ไปยัง ThingsBoard topic `v1/devices/me/telemetry` โดยใช้ device access token เฉพาะบนบอร์ด แอปไม่ควรมี device token, Wi-Fi password หรือ API secret อยู่ใน source code

การเชื่อมต่อกับ ThingsBoard สำหรับการอ่านข้อมูลต้องใช้ credential ที่เก็บนอก repository และตั้งค่าตาม deployment ที่เลือกใช้ ห้าม commit ไฟล์ `.env`, `secrets.h`, token หรือ password

## ข้อจำกัดที่ทราบ

- Presence เป็นการตรวจพบ/ไม่พบจาก radar ไม่ใช่จำนวนคนและไม่สร้างแผนผังห้อง
- BLE และค่าจากเซนเซอร์จริงต้องยืนยันกับบอร์ดที่ประกอบแล้ว
- Explore Demo เป็นข้อมูลจำลองและไม่ใช่ผลการวัดจากฮาร์ดแวร์

## ตรวจสอบก่อนส่งงาน

```bash
cd app
flutter analyze
flutter build web --debug
```
