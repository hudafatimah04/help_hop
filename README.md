📱 HelpHop — Offline Mesh-Based Disaster Response App

HelpHop is a disaster-response system built in Flutter that works even with **no internet and no mobile network**. 
Victim devices broadcast SOS packets via Bluetooth Low Energy (BLE), nearby phones relay them, 
and rescuers receive live SOS alerts with location and hop count.

✨ What Actually Works Today
✔ Offline SOS broadcasting using BLE Manufacturer Data  
✔ Two-part packet design (Header + Location)  
✔ Packet decoding + reconstruction on receiver  
✔ Deduplicated rescuer SOS list (no spam flood)  
✔ RSSI → human readable signal strength (“Very Close / Far”)  
✔ Hop-based relay (devices re-broadcast SOS only once, controlled)  
✔ Rescuer dashboard with Accept / Reject / Mark Rescued  
✔ Direction estimation (demo)  

🚧 Yet to test fully
▪ Multi-hop verification field testing
▪ Long-duration continuous relay stability
