import sys
import argparse
import requests
import base64
from collections import defaultdict
import pyodbc
import time
from datetime import datetime
import pandas as pd
import re
from requests.exceptions import ConnectTimeout, RequestException

arg_parser = argparse.ArgumentParser(description=f"{sys.argv[0]}'s command line argument parser.")

arg_parser.add_argument("-r", "--router-ip", help="The router's IP Address", default="192.168.1.1", required=True)
arg_parser.add_argument("-u", "--username", help="The username", default="admin", required=True)
arg_parser.add_argument("-p", "--password", help="The password", required=True)
arg_parser.add_argument("-dbcs", "--database-connection-string", help="The database connection string", required=True)
arg_parser.add_argument("-ci", "--check-interval", help="Number of seconds until next check", required=True)

args, unknowns = arg_parser.parse_known_args()

args.database_connection_string = base64.b64decode(args.database_connection_string).decode("utf-8")

def get_device_info():
    # JNAP requires Basic Auth: "admin:password" encoded in Base64
    auth_str = f"{args.username}:{base64.b64decode(args.password).decode("utf-8")}"
    encoded_auth = base64.b64encode(auth_str.encode()).decode()

    url = f"http://{args.router_ip}/JNAP/"
    headers = {
        "X-JNAP-Action": "http://linksys.com/jnap/core/Transaction",
        "X-JNAP-Authorization": f"Basic {encoded_auth}",
        "Content-Type": "application/json"
    }
    
    response = requests.post(url, headers=headers,
                         json=[{"action":"http://linksys.com/jnap/devicelist/GetDevices","request":{}},
                               {"action":"http://linksys.com/jnap/networkconnections/GetNetworkConnections","request":{}}])

    if response.status_code == 200:
        return response.json()
    return {}

# Parse the json data into a nested dictionary for easy and efficient retrieval
def parseData(device_info_json):
    device_info_dict = defaultdict(dict)
    
    connections = device_info_json["responses"][1]["output"]["connections"]

    # Add the devices connection to the dictionary
    for connection in connections:
        device_info_dict[connection["macAddress"]] = {
            "currentMACAddress" : connection["macAddress"],
            "connectionType" : "LAN" if connection.get("wireless", {}) is None else "Wireless",
            "BSSID" : connection["wireless"]["bssid"],
            "isGuest" : connection["wireless"]["isGuest"],
            "signalDecibels" : connection["wireless"]["signalDecibels"]
        }
        
    devices =  device_info_json["responses"][0]["output"]["devices"]
    key = ""
    ip_address = ""
    
    # Add the devices info to the dictionary
    for device in devices:
        if len(device["connections"]) < 1:
            continue

        key = device["connections"][0]["macAddress"]

        if key not in device_info_dict:
            continue

        ip_address = device["connections"][0].get("ipAddress", "")

        if (ip_address != "" and ip_address == args.router_ip) :
            continue
        
        device_info_dict[key]["deviceID"] = "Unknown ID" if device.get("deviceID", "") == "" else device["deviceID"]
        device_info_dict[key]["deviceType"] = device["model"]["deviceType"]
        device_info_dict[key]["name"] = "" if device.get("friendlyName", "") == "" else device["friendlyName"]
        device_info_dict[key]["friendlyName"] = "" if device.get("friendlyName", "") == "" else device["friendlyName"]
        device_info_dict[key]["operatingSystem"] = "" if device.get("unit", {}).get("operatingSystem") is None else device["unit"]["operatingSystem"]
        device_info_dict[key]["ipv4Address"] = ip_address
        device_info_dict[key]["ipv6Address"] = "" if (len(device["connections"]) < 1 or device["connections"][0].get("ipv6Address", "") == "") else device["connections"][0]["ipv6Address"]
        device_info_dict[key]["description"] = "" if device.get("model", {}).get("description", "") == "" else device["model"]["description"]

    # Set the information fields of devices with missing info or unable to correlate to Unkown or blank.
    for key in device_info_dict:
        device = device_info_dict[key]

        if device.get("deviceID", "") != "":
            continue

        device["deviceID"] = "Unknown ID"
        device["deviceType"] = "Unknown type"
        device["name"] = "Unknown"
        device["friendlyName"] = "Unknown" 
        device["operatingSystem"] = "Unknown"
        device["ipv4Address"] = "Unknown"
        device["ipv6Address"] = "unknown" 
        device["description"] = "Unknown"

    return device_info_dict

# Show the devices info in a table format
def show_device_info(device_info_dict):
    keys = list(dict.fromkeys(key for sub in device_info_dict.values() if isinstance(sub, dict) for key in sub))

    row_format = "{:<18} {:<16} {:<18} {:<8} {:<16} {:<38} {:<12} {:<28} {:<28} {:<18} {:<18} {:<40} {:<28}"
    print(row_format.format(*keys))
    properties = []
    
    for device in device_info_dict:
       for key in keys:
          properties.append(str(device_info_dict[device][key]))
       print(f"\033[38;2;57;255;20m{row_format.format(*properties)}\033[0m")
       properties.clear()

# Monitor for any unknown device
def monitor():
    device_info_json = get_device_info()
    device_info_dict = parseData(device_info_json)
    
    macAddressTable = []

    # Create a table of MAC Addresses
    for key in device_info_dict:
        macAddressTable.append(key)

    # Connect to the database
    conn = pyodbc.connect(args.database_connection_string)
    cursor = conn.cursor()

    values_string = ", ".join([f"('{macAddress}')" for macAddress in macAddressTable])

    sql = f"""
            set nocount on;

            declare @macAddressTable MACAddressTable;
            insert into @macAddressTable
            values {values_string};

            exec dbo.isKnownDevice
                @unknownMACAddressTable = @macAddressTable;
          """
    
    cursor.execute(sql)

    while cursor.description is None:
        if not cursor.nextset():
            break
    
    # Get the unknown devices return from the database.
    unknown_MAC_Addresses_table = cursor.fetchall()
    cursor.close()
    conn.close()

    # Convert the result into a list.
    unknown_MAC_Addresses_list = [item for tpl in unknown_MAC_Addresses_table for item in tpl]

    # Conver the list into a dictionary.
    unknown_devices_info_dict = { key: value for key, value in device_info_dict.items() if key in unknown_MAC_Addresses_list }

    num_unknown_devices = len(unknown_devices_info_dict)
    
    # Show the unknown devices.
    if num_unknown_devices > 0:
        print(f"\033[31m[!][{datetime.now().strftime("%A, %B %d, %Y %H:%M:%S %f %p")}] {num_unknown_devices} unknown device(s) detected.\033[0m")
        show_device_info(unknown_devices_info_dict)

    return unknown_devices_info_dict

# Log the unknown devices by storing in a database.
def log(unknow_device_info_dict):

    # Only log if there are any unknown devices to log.
    if len(unknow_device_info_dict) < 1:
        return
    
    # Create a new report record
    sql = f"insert into connected_devices_report (createdDateTime) values('{pd.to_datetime(time.time_ns(), unit="ns")}')"
    
    conn = pyodbc.connect(args.database_connection_string)
    cursor = conn.cursor()
    cursor.execute(sql)
    cursor.commit()

    # Get the current ID
    sql = "select top 1 max(reportID) from connected_devices_report"
    cursor.execute(sql)
    id = cursor.fetchall()

    if id == "":
        id = 1

    values_string = ""

    # Generate the value string for insert command.
    for key in unknow_device_info_dict:
        device = unknow_device_info_dict[key]

        values_string += f"""({id[0][0]}, '{ device["deviceID"] }', N'{ device["name"] }', N'{ device["friendlyName"] }', '{ device["currentMACAddress"] }', '{ device["ipv4Address"] }',
                '{ device["ipv6Address"] }', '{ device["connectionType"] }', N'{ device["operatingSystem"] }', '{ device["deviceType"] }', N'{ device["description"] }', 
                '{ device["signalDecibels"] }', '{ device["isGuest"] }', '{ device["BSSID"] }'),\r\n"""
        
    sql = f"""insert into connected_devices (reportID, deviceID, name, friendlyName, currentMACAddress, ipv4Address, ipv6Address, connectionType, operatingSystem, 
                                            deviceType, description, signalDecibels, isGuest, BSSID)
                values {re.sub(",\r\n$", "", values_string)};
            
            """
    # Log the unknown device to the database.    
    cursor.execute(sql)
    cursor.commit()

    # Close the connection
    cursor.close()
    conn.close()

# The main function that monitor and log the unknown devices.
def main():
    try:
        unknow_device_info_dict = monitor()
        
        log(unknow_device_info_dict)
    except ConnectTimeout:
        print(f"[❗][{datetime.now().strftime("%A, %B %d, %Y %H:%M:%S %f %p")}] Connection timeout with router at {args.router_ip}.")
    except ConnectionError:
        print(f"[❗][{datetime.now().strftime("%A, %B %d, %Y %H:%M:%S %f %p")}] Connection error with router at {args.router_ip}.")
    except ConnectionRefusedError:
        print(f"[❗][{datetime.now().strftime("%A, %B %d, %Y %H:%M:%S %f %p")}] Router at {args.router_ip} refused the connection.")
    except ConnectionAbortedError:
        print(f"[❗][{datetime.now().strftime("%A, %B %d, %Y %H:%M:%S %f %p")}] Connection aborted with router at {args.router_ip}.")
    except ConnectionResetError:
        print(f"[❗][{datetime.now().strftime("%A, %B %d, %Y %H:%M:%S %f %p")}] Connection reseted with router at {args.router_ip}.")
    except Exception as exception:
        print(f"[❗][{datetime.now().strftime("%A, %B %d, %Y %H:%M:%S %f %p")}] An error has occured.\t{exception}")

if __name__ == "__main__":
    print(f"[i][{datetime.now().strftime("%A, %B %d, %Y %H:%M:%S %f %p")}] Monitoring and logging have been initiated.")
    print(f"[i][{datetime.now().strftime("%A, %B %d, %Y %H:%M:%S %f %p")}] Now monitoring and logging {args.router_ip} for unknown devices.")

    # Monitor for unknown devices and log the unknown devices to the database every x seconds specificed by check_interval
    while True:
        main()

        print (f"[i][{datetime.now().strftime("%A, %B %d, %Y %H:%M:%S %f %p")}] Sleeping for {args.check_interval} second(s).")
        time.sleep(int(args.check_interval))










