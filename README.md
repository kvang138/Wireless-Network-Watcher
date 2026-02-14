# 📶🕵️‍♂️📋Wireless Network Watcher
Ever wonder who is connected to your wireless network at all times? Now you don't have to. Wireless Network Watcher monitors your wireless network for unknown devices and logs them to a database.

## 📖 Introduction
This project was created for monitoring and logging unknown devices connecting to the network. The Python script utilizes the JNAP endpoint on the router to get the list of devices currently connected to the router along with their information. It then parses the data returned from the router, checks it against the list of known devices in the database, and logs any unknown devices to a database table of unknown devices that have connected to the network.

For now, it uses Microsoft SQL Server as the backend for log storage, but it can be modified to use SQLite, MySQL, Oracle, PostgreSQL, etc. The alerting feature will be added in the next update.

## 🚀Usage
### Single line
````
python3 "wireless network watcher.py" --router-ip <router-ip> --username <base64-encoded-username> --password <base64-encoded-password> --database-connection-string <base64-encoded-connection-string> --check-interval <seconds>
````
### Multiline

```
python3 "wireless network watcher.py" --router-ip <router-ip> \
--username <base64-encoded-username> \
--password <base64-encoded-password> \
--database-connection-string <base64-encoded-connection-string> \
--check-interval <seconds>
```

## 🔤🛠️Languages/Tools
 - Python
 - Microsoft SQL Server (backend)
   
## 📸Screenshots
One unknown device detected.
![One unknown device detected.](https://github.com/kvang138/Wireless-Network-Watcher/blob/main/Screenshots/Wireless-Network-Watcher.png)
