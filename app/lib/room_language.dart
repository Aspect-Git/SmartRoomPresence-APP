import 'package:flutter/material.dart';

class LanguageHost extends StatefulWidget {
  const LanguageHost({super.key, required this.child});
  final Widget child;
  @override
  State<LanguageHost> createState() => _LanguageHostState();
}

class _LanguageHostState extends State<LanguageHost> {
  final language = ValueNotifier<bool>(false);
  @override
  void dispose() {
    language.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      RoomLanguage(notifier: language, child: widget.child);
}

class RoomLanguage extends InheritedNotifier<ValueNotifier<bool>> {
  const RoomLanguage(
      {super.key, required super.notifier, required super.child});
  static ValueNotifier<bool> of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RoomLanguage>()!.notifier!;
}

class LanguagePicker extends StatelessWidget {
  const LanguagePicker({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final language = RoomLanguage.of(context);
    if (compact) {
      return Tooltip(
        message: tr(context, 'Switch language'),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          RoomText(language.value ? 'ไทย' : 'EN',
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          Switch(
            key: const ValueKey('language-switch'),
            value: language.value,
            onChanged: (value) => language.value = value,
          ),
        ]),
      );
    }
    return SwitchListTile(
      key: const ValueKey('language-switch'),
      secondary: const Icon(Icons.language),
      title: const RoomText('Use Thai'),
      subtitle: Text(language.value ? 'ไทย' : 'English'),
      value: language.value,
      onChanged: (value) => language.value = value,
    );
  }
}

/// Localizes display copy while keeping internal scene/filter values stable.
class RoomText extends StatelessWidget {
  const RoomText(this.data,
      {super.key, this.style, this.textAlign, this.maxLines, this.overflow});
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  @override
  Widget build(BuildContext context) => Text(tr(context, data),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow);
}

String tr(BuildContext context, String text) {
  if (!RoomLanguage.of(context).value) return text;
  if (_thai.containsKey(text)) return _thai[text]!;
  if (text.startsWith('Hi, ')) return 'สวัสดี ${text.substring(4)}';
  if (text.startsWith('Brightness: ')) {
    return text.replaceFirst('Brightness:', 'ความสว่าง:');
  }
  if (text.startsWith('Target: ')) {
    return text.replaceFirst('Target:', 'ตั้งอุณหภูมิ:');
  }
  if (text.endsWith(' unread')) {
    return '${text.split(' ').first} รายการยังไม่อ่าน';
  }
  if (text.endsWith(' similar updates')) {
    return '${text.split(' ').first} กิจกรรมที่คล้ายกัน';
  }
  var result = text;
  // Longer phrases precede shorter ones for composed status/event messages.
  for (final entry in _dynamic.entries) {
    result = result.replaceAll(entry.key, entry.value);
  }
  return result;
}

const _dynamic = <String, String>{
  'Meeting Room A': 'ห้องประชุม A',
  'Lab 1': 'ห้องแล็บ 1',
  'Lounge': 'ห้องพักผ่อน',
  'empty-room routine · now': 'ทำงานตามกฎห้องว่าง · เมื่อสักครู่',
  'scene applied to': 'ถูกนำไปใช้กับ',
  'scene applied · now': 'ถูกนำไปใช้ · เมื่อสักครู่',
  'Demo control': 'การควบคุมจำลอง',
  'Demo readings': 'ค่าตัวอย่าง',
  'Live sensor data · ThingsBoard EU': 'ข้อมูลเซนเซอร์จริง · ThingsBoard EU',
  'Demo workspace · No fresh device data':
      'โหมดตัวอย่าง · ไม่มีข้อมูลอุปกรณ์ใหม่',
  'Open Air quality sensor': 'เปิดเซนเซอร์คุณภาพอากาศ',
  'Open Smart light': 'เปิดไฟอัจฉริยะ',
  'Open Air conditioner': 'เปิดเครื่องปรับอากาศ',
  'Open Ventilation': 'เปิดระบบระบายอากาศ',
  'Morning': 'ยามเช้า',
  'Focus': 'โฟกัส',
  'Relax': 'ผ่อนคลาย',
  'Strong signal': 'สัญญาณแรง',
  'Good signal': 'สัญญาณดี',
  'Weak signal': 'สัญญาณอ่อน',
  'Min ': 'ต่ำสุด ',
  ' · Average ': ' · เฉลี่ย ',
  ' · Max ': ' · สูงสุด ',
  'Waiting for sensor history.': 'กำลังรอประวัติข้อมูล',
  'Presence detected in ': 'ตรวจพบการมีอยู่ใน ',
  ' samples.': ' ตัวอย่าง',
  'History chart': 'กราฟประวัติ',
  'Horizontal axis is time. Vertical axis is the reading.':
      'แกนนอนแสดงเวลา แกนตั้งแสดงค่าที่อ่านได้',
};
const _thai = <String, String>{
  'Devices': 'อุปกรณ์',
  'Your device is set up': 'ตั้งค่าอุปกรณ์แล้ว',
  'Add your first device': 'เพิ่มอุปกรณ์เครื่องแรก',
  'Create a room to organize the readings from your board.':
      'สร้างห้องเพื่อจัดกลุ่มข้อมูลจากบอร์ด',
  'Connect your Smart Room board to bring live room conditions into the app.':
      'เชื่อมต่อบอร์ด Smart Room เพื่อดูสภาพแวดล้อมในห้องแบบสด',
  'Create a room': 'สร้างห้อง',
  'Add device': 'เพิ่มอุปกรณ์',
  'Strong signal': 'สัญญาณแรง',
  'Good signal': 'สัญญาณดี',
  'Weak signal': 'สัญญาณอ่อน',
  'Select room': 'เลือกห้องนี้',
  'Hardware diagnostics': 'การตรวจสอบอุปกรณ์',
  'Simulated device checks': 'ผลตรวจสอบจำลอง',
  'Reading availability': 'สถานะการอ่านค่า',
  'Waiting for device data': 'กำลังรอข้อมูลจากอุปกรณ์',
  'Air quality readings': 'ค่าคุณภาพอากาศ',
  'Room climate readings': 'ค่าอุณหภูมิและความชื้น',
  'Light readings': 'ค่าความสว่าง',
  'Ambient light level': 'ระดับแสงโดยรอบ',
  'About this device': 'เกี่ยวกับอุปกรณ์นี้',
  'Presence & room conditions': 'การตรวจจับและสภาพแวดล้อมในห้อง',
  'Reading': 'รายการข้อมูล',
  'How setup works': 'ขั้นตอนการตั้งค่า',
  'Put the board in setup mode': 'เปิดโหมดตั้งค่าบนบอร์ด',
  'Choose the nearby Smart Room board.': 'เลือกบอร์ด Smart Room ที่อยู่ใกล้',
  'Provide 2.4 GHz Wi-Fi': 'กรอก Wi-Fi 2.4 GHz',
  'Credentials are sent to the board for provisioning.':
      'ส่งข้อมูล Wi-Fi ไปยังบอร์ดเพื่อตั้งค่า',
  'Once online, readings appear here through your ThingsBoard connection.':
      'เมื่อออนไลน์แล้ว ข้อมูลจะปรากฏที่นี่ผ่าน ThingsBoard',
  'Bring your room online': 'เชื่อมต่อห้องของคุณ',
  'Pair the board, then send your 2.4 GHz Wi-Fi details securely over Bluetooth.':
      'จับคู่กับบอร์ด แล้วส่งข้อมูล Wi-Fi 2.4 GHz ผ่าน Bluetooth',
  'Prepare the board': 'เตรียมบอร์ด',
  'Connect to your board': 'เชื่อมต่อบอร์ด',
  'Scan nearby devices': 'ค้นหาอุปกรณ์ใกล้เคียง',
  'Connect to Wi-Fi': 'เชื่อมต่อ Wi-Fi',
  'Send Wi-Fi details': 'ส่งข้อมูล Wi-Fi',
  'Continue to create a room': 'ดำเนินการสร้างห้อง',
  'Your board will appear here after scanning.': 'บอร์ดจะแสดงที่นี่หลังค้นหา',
  'Presence detection': 'การตรวจจับการมีอยู่',
  'Room overview': 'ภาพรวมห้อง',
  'Add room': 'เพิ่มห้อง',
  'Demo data': 'ข้อมูลจำลอง',
  'Connected': 'เชื่อมต่อแล้ว',
  'No recent data': 'ไม่มีข้อมูลล่าสุด',
  'Not connected': 'ยังไม่เชื่อมต่อ',
  'Presence now': 'สถานะการตรวจจับ',
  'Waiting for radar data': 'กำลังรอข้อมูลเรดาร์',
  'No presence detected': 'ไม่พบการเคลื่อนไหว',
  'Room conditions': 'สภาพแวดล้อมในห้อง',
  'History': 'ประวัติ',
  'Carbon dioxide': 'คาร์บอนไดออกไซด์',
  'Illuminance': 'ความสว่าง',
  'CO₂ is critically high · ventilate now': 'CO₂ สูงวิกฤต · ควรระบายอากาศทันที',
  'CO₂ is elevated · consider ventilation': 'CO₂ สูง · พิจารณาระบายอากาศ',
  'Device connection': 'การเชื่อมต่ออุปกรณ์',
  'Smart Room Presence board': 'บอร์ด Smart Room Presence',
  'No connection': 'ไม่มีการเชื่อมต่อ',
  'Simulated': 'จำลอง',
  'Wi-Fi signal': 'สัญญาณ Wi-Fi',
  'ThingsBoard': 'ThingsBoard',
  'Disconnected': 'ขาดการเชื่อมต่อ',
  'Set up device over BLE': 'ตั้งค่าอุปกรณ์ผ่าน BLE',
  'Device details': 'รายละเอียดอุปกรณ์',
  'Sensor overview': 'ภาพรวมเซนเซอร์',
  'View status': 'ดูสถานะ',
  'No data': 'ไม่มีข้อมูล',
  'CO₂ and temperature': 'CO₂ และอุณหภูมิ',
  'Temperature and humidity': 'อุณหภูมิและความชื้น',
  'Ambient light': 'แสงโดยรอบ',
  'Manage rooms': 'จัดการห้อง',
  'Explore Demo · simulated board and sensor data':
      'เดโม · จำลองข้อมูลบอร์ดและเซนเซอร์',
  'Room names organize your workspace. Live readings currently come from one connected board.':
      'ชื่อห้องช่วยจัดพื้นที่ของคุณ ขณะนี้ข้อมูลสดมาจากบอร์ดที่เชื่อมต่อหนึ่งตัว',
  'NO DEVICE': 'ไม่มีอุปกรณ์',
  'LIVE': 'กำลังทำงาน',
  'DEMO': 'เดโม',
  'No device assigned to this room.': 'ยังไม่มีอุปกรณ์ในห้องนี้',
  'Select': 'เลือก',
  'What this device measures': 'ค่าที่อุปกรณ์นี้วัดได้',
  'The radar reports presence and, when available, target distance. It does not estimate a room map or count people. The board also reports CO₂, temperature, humidity and ambient light.':
      'เรดาร์ตรวจจับการมีอยู่และระยะเป้าหมายเมื่อมีข้อมูล ไม่สร้างแผนผังห้องหรือนับคน บอร์ดยังวัด CO₂ อุณหภูมิ ความชื้น และแสงโดยรอบ',
  'Refresh history': 'โหลดประวัติใหม่',
  'Simulated sensor history': 'ประวัติเซนเซอร์จำลอง',
  'History reported by the device': 'ประวัติจากอุปกรณ์',
  '24 h': '24 ชม.',
  '7 days': '7 วัน',
  '30 days': '30 วัน',
  'Trend': 'แนวโน้ม',
  'No readings yet': 'ยังไม่มีข้อมูลเซนเซอร์',
  'Waiting for sensor history.': 'กำลังรอประวัติเซนเซอร์',
  'Latest readings': 'ค่าล่าสุด',
  'Recent records': 'รายการล่าสุด',
  'Newest first': 'เรียงจากรายการล่าสุด',
  'records': 'รายการ',
  'No records for this sensor yet.': 'ยังไม่มีข้อมูลของเซนเซอร์นี้',
  'No presence': 'ไม่พบการเคลื่อนไหว',
  'Detected': 'ตรวจพบ',
  'Clear': 'ไม่พบ',
  'Start': 'เริ่ม',
  'Now': 'ตอนนี้',
  'Explore Demo': 'เดโม',
  'Preferences': 'การตั้งค่า',
  'Temperature display unit': 'หน่วยแสดงอุณหภูมิ',
  'Device': 'อุปกรณ์',
  'Set up Smart Room device': 'ตั้งค่าอุปกรณ์ Smart Room',
  'Connect over Bluetooth and provide Wi-Fi':
      'เชื่อมต่อ Bluetooth และตั้งค่า Wi-Fi',
  'About sensing': 'เกี่ยวกับการตรวจจับ',
  'Presence is a binary radar detection with optional target distance. The device does not count people or create a room map. Measurements are CO₂, temperature, humidity and ambient light. Readings reach the app through ThingsBoard via the authenticated backend.':
      'เรดาร์ตรวจจับการมีอยู่และอาจรายงานระยะเป้าหมาย อุปกรณ์ไม่นับคนหรือสร้างแผนผังห้อง วัด CO₂ อุณหภูมิ ความชื้น และแสง ข้อมูลส่งผ่าน ThingsBoard และ backend ที่ยืนยันตัวตนแล้ว',
  'Exit demo': 'ออกจากเดโม',
  'Sign out': 'ออกจากระบบ',
  'Set up device': 'ตั้งค่าอุปกรณ์',
  'Press the side button on the board for 3 seconds, then scan.':
      'กดปุ่มด้านข้างบนบอร์ดค้าง 3 วินาที แล้วเริ่มค้นหา',
  'Hold the side button for 3 seconds until the status LED blinks teal. The board then accepts Wi-Fi setup for two minutes.':
      'กดปุ่มด้านข้างค้าง 3 วินาทีจนไฟสถานะกะพริบสีเขียวอมฟ้า บอร์ดจะเปิดรับการตั้งค่า Wi-Fi เป็นเวลา 2 นาที',
  'Select the nearby Smart Room device.': 'เลือกอุปกรณ์ Smart Room ที่อยู่ใกล้',
  'Connecting to the board…': 'กำลังเชื่อมต่อกับบอร์ด…',
  'Device: saved': 'อุปกรณ์บันทึกข้อมูลแล้ว',
  'Wi-Fi details received. The board will now connect.':
      'บอร์ดได้รับข้อมูล Wi-Fi แล้ว และกำลังเชื่อมต่อเครือข่าย',
  'Select the device and enter the 2.4 GHz Wi-Fi name.':
      'เลือกอุปกรณ์และกรอกชื่อ Wi-Fi 2.4 GHz',
  'Wi-Fi name/password exceeds the firmware limit.':
      'ชื่อหรือรหัสผ่าน Wi-Fi ยาวเกินขีดจำกัดของเฟิร์มแวร์',
  'No SmartRoom-Setup device was found.': 'ไม่พบอุปกรณ์ SmartRoom-Setup',
  'Bluetooth permission is required.': 'ต้องอนุญาตให้แอปใช้ Bluetooth',
  'Device not found. Put it in BLE setup mode and try again.':
      'ไม่พบอุปกรณ์ โปรดเปิดโหมดตั้งค่า BLE แล้วลองอีกครั้ง',
  'Find your device': 'ค้นหาอุปกรณ์',
  'Scan for Smart Room': 'ค้นหา Smart Room',
  'Scanning…': 'กำลังค้นหา…',
  'Enter Wi-Fi details': 'กรอกข้อมูล Wi-Fi',
  '2.4 GHz Wi-Fi name (SSID)': 'ชื่อ Wi-Fi 2.4 GHz (SSID)',
  'Send Wi-Fi to device': 'ส่งข้อมูล Wi-Fi ไปยังอุปกรณ์',
  'Sending…': 'กำลังส่ง…',
  'The app sends Wi-Fi details directly to the selected board over BLE. It does not store the Wi-Fi password or ThingsBoard device token.':
      'แอปส่งข้อมูล Wi-Fi ไปยังบอร์ดผ่าน BLE โดยตรง และไม่เก็บรหัสผ่าน Wi-Fi หรือโทเคน ThingsBoard ไว้',
  'Connect to an ESP32-C6 over Bluetooth, then send Wi-Fi details to the device.':
      'เชื่อมต่อ ESP32-C6 ผ่าน Bluetooth แล้วส่งข้อมูล Wi-Fi ไปยังอุปกรณ์',
  'Device name prefix': 'คำนำหน้าชื่ออุปกรณ์',
  'The firmware default is often PROV_.':
      'ค่าเริ่มต้นของ Firmware มักเป็น PROV_',
  'Scan for devices': 'ค้นหาอุปกรณ์',
  'BLE device': 'อุปกรณ์ BLE',
  'No setup devices found.': 'ไม่พบอุปกรณ์ในโหมดตั้งค่า',
  'Enter the device name prefix.': 'กรอกคำนำหน้าชื่ออุปกรณ์',
  'Verify the device': 'ยืนยันตัวตนของอุปกรณ์',
  'Proof of possession (PoP)': 'รหัสยืนยันอุปกรณ์ (PoP)',
  'Enter the PoP printed on the device or provided by the firmware team.':
      'กรอกรหัส PoP บนฉลากอุปกรณ์ หรือรหัสที่ทีม Firmware แจ้ง',
  'Select a device and enter its PoP.': 'เลือกอุปกรณ์และกรอกรหัส PoP',
  'Scan Wi-Fi networks': 'ค้นหาเครือข่าย Wi-Fi',
  'No Wi-Fi networks found.': 'อุปกรณ์ไม่พบเครือข่าย Wi-Fi',
  'Send Wi-Fi credentials': 'ส่งข้อมูล Wi-Fi',
  'Wi-Fi name (SSID)': 'ชื่อ Wi-Fi (SSID)',
  'Wi-Fi password': 'รหัสผ่าน Wi-Fi',
  'Complete the device, PoP and Wi-Fi fields.':
      'กรอกอุปกรณ์ รหัส PoP และข้อมูล Wi-Fi ให้ครบ',
  'Connecting…': 'กำลังเชื่อมต่อ…',
  'Wi-Fi setup complete. The device will connect to the network.':
      'ตั้งค่า Wi-Fi สำเร็จ อุปกรณ์กำลังเชื่อมต่อเครือข่าย',
  'Sensor data will reach Room after the device connects to Wi-Fi and the backend. Reconfigure an existing device by putting it back into setup mode.':
      'ข้อมูลเซ็นเซอร์จะส่งเข้า Room เมื่ออุปกรณ์เชื่อมต่อ Wi-Fi และ Backend แล้ว หากต้องการเปลี่ยน Wi-Fi ให้เปิดโหมดตั้งค่าที่อุปกรณ์อีกครั้ง',
  'Credentials are sent to the selected device through Espressif BLE provisioning. The app does not store the Wi-Fi password.':
      'แอปส่งข้อมูลไปยังอุปกรณ์ผ่าน BLE Provisioning ของ Espressif และไม่บันทึกรหัสผ่าน Wi-Fi ไว้ในแอป',
  'PoP or Wi-Fi password is incorrect. Check it and try again.':
      'รหัส PoP หรือรหัสผ่าน Wi-Fi ไม่ถูกต้อง โปรดตรวจสอบแล้วลองอีกครั้ง',
  'Could not complete BLE setup. Check the device and try again.':
      'ตั้งค่า BLE ไม่สำเร็จ โปรดตรวจสอบอุปกรณ์แล้วลองอีกครั้ง',
  'Show or hide password': 'แสดงหรือซ่อนรหัสผ่าน',
  'Use Thai': 'ใช้ภาษาไทย',
  'Switch language': 'เปลี่ยนภาษา',
  'Cancel': 'ยกเลิก',
  'Apply': 'นำไปใช้',
  'Demo activity updates': 'อัปเดตกิจกรรมจำลอง',
  'Room activity': 'กิจกรรมในห้อง',
  'Home': 'หน้าหลัก',
  'Rooms': 'ห้อง',
  'Insights': 'สถิติ',
  'Profile': 'โปรไฟล์',
  'Language': 'ภาษา',
  'Logout': 'ออกจากระบบ',
  'All': 'ทั้งหมด',
  'Meeting Room': 'ห้องประชุม',
  'Lab': 'ห้องแล็บ',
  'Lounge': 'ห้องพักผ่อน',
  'SPACE INTELLIGENCE': 'เข้าใจพื้นที่ของคุณ',
  'SMART PRESENCE': 'ตรวจจับการใช้งานห้อง',
  'Notifications': 'การแจ้งเตือน',
  'A little more aware.': 'เข้าใจห้องของคุณมากขึ้น',
  'Your spaces, people and comfort — at a glance.':
      'ดูการใช้พื้นที่และสภาพห้องได้ในที่เดียว',
  'Empty': 'ว่าง',
  '● Demo': '● เดโม',
  'Room empty': 'ห้องว่าง',
  'People present': 'คนในห้อง',
  'Presence detected': 'ตรวจพบการมีอยู่',
  'Room clear': 'ไม่พบการมีอยู่ในห้อง',
  'No live device data': 'ยังไม่มีข้อมูลจากอุปกรณ์จริง',
  'Radar presence detected': 'เรดาร์ตรวจพบการมีอยู่',
  'Presence detection only · no occupant count or room map':
      'ตรวจจับการมีอยู่เท่านั้น · ไม่ระบุจำนวนคนหรือตำแหน่งในห้อง',
  'Connect the device to see radar presence':
      'เชื่อมต่ออุปกรณ์เพื่อดูสถานะเรดาร์',
  'Presence status': 'สถานะการตรวจจับ',
  'Presence sensor': 'เซนเซอร์ตรวจจับการมีอยู่',
  'Radar data unavailable': 'ไม่มีข้อมูลเรดาร์',
  'ONLINE': 'ออนไลน์',
  'OFFLINE': 'ออฟไลน์',
  'Waiting for a sensor reading': 'กำลังรอข้อมูลจากเซนเซอร์',
  'Nearest reported target · ': 'ระยะเป้าหมายที่ใกล้ที่สุด · ',
  'Binary presence sensing': 'ตรวจจับการมีอยู่แบบพบ/ไม่พบ',
  'The radar reports presence and target range. It cannot identify people, count occupants, or locate them on a room plan.':
      'เรดาร์รายงานการมีอยู่และระยะเป้าหมาย แต่ไม่ระบุตัวบุคคล ไม่นับจำนวนคน และระบุตำแหน่งบนแผนผังไม่ได้',
  'Camera-free sensing': 'ตรวจจับโดยไม่ใช้กล้อง',
  'Comfort now': 'สภาพห้องตอนนี้',
  'Details ›': 'รายละเอียด ›',
  'Make it feel right': 'บรรยากาศที่ต้องการ',
  'Morning': 'ยามเช้า',
  'Focus': 'โฟกัส',
  'Relax': 'ผ่อนคลาย',
  'Room controls': 'ควบคุมห้อง',
  'All devices ›': 'อุปกรณ์ทั้งหมด ›',
  'Less idle time. Less waste.': 'ลดเวลาที่เปิดอุปกรณ์ทิ้งไว้',
  'Explore your room usage and automation.':
      'ดูการใช้งานห้องและตั้งค่าการทำงานอัตโนมัติ',
  'Demo workspace · No hardware connected':
      'พื้นที่สาธิต · ยังไม่เชื่อมต่ออุปกรณ์จริง',
  'Back to Home': 'กลับหน้าหลัก',
  'Room settings': 'ตั้งค่าห้อง',
  'Light controls': 'ควบคุมไฟ',
  'Presence map': 'สถานะการตรวจจับ',
  'Environment': 'สภาพแวดล้อม',
  'My devices': 'อุปกรณ์ของฉัน',
  'Presence & room map': 'การตรวจจับและแผนผังห้อง',
  'Open ›': 'เปิด ›',
  'Automation': 'การทำงานอัตโนมัติ',
  'Empty room routine': 'กฎเมื่อห้องว่าง',
  'After 10 minutes: lights, AC and fan off':
      'ห้องว่าง 10 นาที: ปิดไฟ แอร์ และพัดลม',
  'Enable the routine first': 'กรุณาเปิดใช้กฎก่อน',
  'Room is occupied. Simulate an empty room first.':
      'ยังมีคนในห้อง กรุณาจำลองให้ห้องว่างก่อน',
  'Demo: 10 minutes elapsed, devices switched off':
      'เดโม: ครบ 10 นาที ปิดอุปกรณ์แล้ว',
  'Simulate 10 minutes elapsed': 'จำลองว่าผ่านไป 10 นาที',
  'Air quality sensor': 'เซนเซอร์อากาศ',
  'Smart light': 'ไฟอัจฉริยะ',
  'Air conditioner': 'เครื่องปรับอากาศ',
  'Ventilation': 'ระบบระบายอากาศ',
  '● Online': '● ออนไลน์',
  'Good air': 'อากาศดี',
  'On': 'เปิด',
  'Off': 'ปิด',
  'Decrease temperature': 'ลดอุณหภูมิ',
  'Increase temperature': 'เพิ่มอุณหภูมิ',
  'Auto': 'อัตโนมัติ',
  'Low': 'ต่ำ',
  'Medium': 'กลาง',
  'High': 'สูง',
  'Sensor': 'เซนเซอร์',
  'Power': 'เปิด / ปิด',
  'Done': 'เสร็จสิ้น',
  'Temperature': 'อุณหภูมิ',
  'Humidity': 'ความชื้น',
  'Brightness': 'ความสว่าง',
  'Room environment': 'สภาพแวดล้อมในห้อง',
  'Smart status': 'สถานะห้อง',
  'No configured alert threshold has been exceeded. Verify sensor readings before changing ventilation.':
      'ค่าที่อ่านได้ยังไม่เกินเกณฑ์แจ้งเตือนที่ตั้งไว้ โปรดตรวจสอบค่าเซนเซอร์ก่อนปรับการระบายอากาศ',
  'View history': 'ดูประวัติ',
  'Demo tracking · No camera or identity recognition':
      'จำลองการตรวจจับ · ไม่ใช้กล้องหรือระบุตัวตน',
  'Room name': 'ชื่อห้อง',
  'Save room name': 'บันทึกชื่อห้อง',
  'Room sensor · SRP-01': 'เซนเซอร์ห้อง · SRP-01',
  'Demo device · Live backend not connected':
      'อุปกรณ์จำลอง · ยังไม่เชื่อมต่อระบบจริง',
  'In-app alerts': 'การแจ้งเตือนในแอป',
  'New in-app alerts are muted.': 'ปิดการแจ้งเตือนใหม่ในแอปแล้ว',
  'All caught up': 'ไม่มีการแจ้งเตือนใหม่',
  'Mark all as read': 'อ่านทั้งหมด',
  'Room insights': 'ข้อมูลการใช้งานห้อง',
  'Understand your space, over time.': 'เข้าใจการใช้พื้นที่ในแต่ละช่วงเวลา',
  'Day': 'วัน',
  'Week': 'สัปดาห์',
  'Month': 'เดือน',
  'Occupancy': 'การใช้ห้อง',
  '4h 12m': '4 ชม. 12 นาที',
  '18h 24m': '18 ชม. 24 นาที',
  '72h 08m': '72 ชม. 08 นาที',
  'Total room usage · Sample history': 'เวลาที่ใช้ห้องรวม · ประวัติตัวอย่าง',
  'Mon        Tue        Wed        Thu        Fri':
      'จ.        อ.        พ.        พฤ.        ศ.',
  'Week 1       Week 2       Week 3       Week 4':
      'สัปดาห์ 1     สัปดาห์ 2     สัปดาห์ 3     สัปดาห์ 4',
  'Energy opportunity': 'โอกาสประหยัดพลังงาน',
  '2h 18m unoccupied': 'ห้องว่าง 2 ชม. 18 นาที',
  '11h 30m unoccupied': 'ห้องว่าง 11 ชม. 30 นาที',
  '46h unoccupied': 'ห้องว่าง 46 ชม.',
  'Potential device-off time, not measured energy savings. Power-meter data is required to estimate kWh.':
      'ช่วงเวลาที่อาจปิดอุปกรณ์ได้ ยังไม่ใช่พลังงานที่ประหยัดจริง ต้องใช้ข้อมูลมิเตอร์เพื่อประเมิน kWh',
  'Set up an empty-room routine →': 'ตั้งกฎเมื่อห้องว่าง →',
  'Recent activity': 'กิจกรรมล่าสุด',
  'Sensor history': 'ประวัติเซนเซอร์',
  'CO₂ · Demo daily trend (ppm)': 'CO₂ · แนวโน้มรายวันจำลอง (ppm)',
  'Minimum 540  ·  Average 680  ·  Maximum 820':
      'ต่ำสุด 540 · เฉลี่ย 680 · สูงสุด 820',
  'Demo workspace': 'พื้นที่สาธิต',
  'Use Fahrenheit': 'ใช้หน่วยฟาเรนไฮต์',
  'Display units for sensor readings': 'หน่วยแสดงค่าอุณหภูมิ',
  'Connected devices': 'อุปกรณ์ที่เชื่อมต่อ',
  'Help & privacy': 'ความช่วยเหลือและความเป็นส่วนตัว',
  'Using Room': 'วิธีใช้ Room',
  '1. Choose a room on Home.\n2. Open Rooms to control devices.\n3. Open the presence map to simulate entry and exit.\n4. Check Insights for sample usage history.\n\nAll readings, controls and account information in this MVP are simulated and kept in memory. Restarting the app resets them. No camera or identity tracking is used. No commands are sent to real devices.':
      '1. เลือกห้องในหน้าหลัก\n2. ไปที่ห้องเพื่อควบคุมอุปกรณ์\n3. เปิดแผนผังเพื่อจำลองคนเข้าและออก\n4. ดูประวัติตัวอย่างในข้อมูลเชิงลึก\n\nค่าเซนเซอร์ การควบคุม และบัญชีใน MVP นี้เป็นข้อมูลจำลอง เก็บไว้ในหน่วยความจำและรีเซ็ตเมื่อเปิดแอปใหม่ ไม่มีการใช้กล้อง ระบุตัวตน หรือส่งคำสั่งไปยังอุปกรณ์จริง',
  'Room · Prototype 0.2\nDemo mode': 'Room · ต้นแบบ 0.2\nโหมดสาธิต',
  'Edit profile': 'แก้ไขโปรไฟล์',
  'Display name': 'ชื่อที่แสดง',
  'Save changes': 'บันทึกการเปลี่ยนแปลง',
  'Demo sign-in': 'เข้าสู่ระบบสาธิต',
  'There is no saved account or password yet. Enter any valid email and a password of at least 6 characters, or choose Explore demo. Nothing is sent to a server.':
      'ยังไม่มีบัญชีหรือรหัสผ่านที่บันทึกไว้ กรอกอีเมลรูปแบบถูกต้องและรหัสผ่านอย่างน้อย 6 ตัวอักษร หรือเลือกลองใช้งานเดโม ไม่มีการส่งข้อมูลไปยังเซิร์ฟเวอร์',
  'Got it': 'เข้าใจแล้ว',
  'Presence. Without a camera.': 'ไม่ใช้กล้อง · ไม่ระบุตัวตน',
  'Welcome to\nyour space.': 'ยินดีต้อนรับสู่\nพื้นที่ของคุณ',
  'Sign in to understand your rooms and\nmake every space work better.':
      'เข้าสู่ระบบเพื่อเข้าใจห้องของคุณ\nและจัดการพื้นที่ให้ดียิ่งขึ้น',
  'Email address': 'อีเมล',
  'Enter a valid email address': 'กรุณากรอกอีเมลให้ถูกต้อง',
  'Password': 'รหัสผ่าน',
  'Hide password': 'ซ่อนรหัสผ่าน',
  'Show password': 'แสดงรหัสผ่าน',
  'Use at least 6 characters': 'ใช้รหัสผ่านอย่างน้อย 6 ตัวอักษร',
  'Need help signing in?': 'ต้องการความช่วยเหลือ?',
  'Sign in': 'เข้าสู่ระบบ',
  'Or continue with': 'หรือใช้บัญชี',
  'Google sign-in is ready to connect when account services are set up.':
      'เตรียมปุ่มเข้าสู่ระบบด้วย Google ไว้เชื่อมต่อเมื่อระบบบัญชีพร้อม',
  'Facebook sign-in is ready to connect when account services are set up.':
      'เตรียมปุ่มเข้าสู่ระบบด้วย Facebook ไว้เชื่อมต่อเมื่อระบบบัญชีพร้อม',
  'Explore demo': 'ลองใช้งานเดโม',
  'Prototype sign-in • No real account required':
      'ระบบเข้าสู่ระบบจำลอง • ไม่ต้องใช้บัญชีจริง',
};
