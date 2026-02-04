# Wireless Network Watcher
Monitor the wireless network for unknown devices and log them to a database.


## Introduction
This project I created for monitoring and logging unknown devices connecting to the network. The python script utilizes the JNAP endppoint on the router to get the list of devices currently connected to the router and their information. It then parses the data returned from the router, checked it against the list of known devices on the database, and then log the unknown devices to a database table of unknown device that have connected to the network.

## 🚀Usage
```
python3 "wireless network watcher.py" --router-ip <router ip> --username <Admin's username> --password <Admin's password> --database-connection-string <SQL server connection string> --check-interval <number of seconds until next check>
```

## 🔤🛠️Languages/Tools
 - Python
 - Microsoft SQL Server (Backend)
   
## 📸Screenshots
