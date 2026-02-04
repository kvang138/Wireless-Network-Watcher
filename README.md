# Wireless Network Watcher
Monitor and log unknown devices


## Introduction
This project I created for monitoring and logging unknown devices connecting to the network. The python script utilizes the JNAP endppoint on the router to get the list of devices currently connected to the router and their information. It then parses the data returned from the router, checked it against the list of known devices on the database, and then log the unknown devices to a database table of unknown device that have connected to the network.

## Usage
```
python3 "wireless network watcher.py"
```

## Languages/Tools
 - Python
 - Microsoft SQL Server and SQL (Backend)
   
