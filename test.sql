-- Create a new test report
insert into SOCLab.dbo.connected_devices_report (createdDateTime)
values (SYSDATETIME());

-- Get the current report ID
declare @id int = (select top 1 max(reportID) from SOCLab.dbo.connected_devices_report);

-- Store some records into the event table
insert into SOCLab.dbo.connected_devices (reportID, deviceID, name, friendlyName, currentMACAddress, ipv4Address, ipv6Address, connectionType, operatingSystem, deviceType, description, signalDecibels, isGuest, BSSID)
values
(@id, '9097b026-2576-4a9d-b370-3417428f3674', '98" OLED', '98" OLED', '22:AE:06:D7:FA:36', '192.168.1.70', '',
                'Wireless', '', 'MediaPlayer', 'Samsung TV DMR', '38',
                'False', 'E9:98:68:8E:A8:98'),
(@id, 'a07f0528-b3af-442b-933e-5bca0065a7b3', '', '', '06:96:61:6E:A6:38', '192.168.1.182', '',
                'Wireless', 'Android', 'Mobile', '', '71',
                'False', 'E9:98:68:8E:A8:98'),
(@id, '70a7f65a-08a0-480d-982a-eceeb64c359c', 'DESKTOP-TTUN3KK', 'DESKTOP-TTUN3KK', '6E:E8:A7:AC:C2:88', '192.168.1.160', 'f',
                'Wireless', 'Windows 10', 'Computer', '', '66',
                'False', 'E9:98:68:8E:A8:98'),
(@id, '092039bb-e30a-462e-8ef8-383b0a7c4e81', 'NetworknowDevicesevice', 'NetworknowDevicesevice', '3E:8A:2F:5C:D1:96', '192.168.1.138', '',
                'Wireless', 'Android', 'Mobile', '', '70',
                'False', 'E9:98:68:8E:A8:98'),
(@id, '3513fb76-bf67-4990-be34-b0e6a56410b1', 'Android_K11S94XE', 'Android_K11S94XE', '16:29:D6:A1:85:68', '192.168.1.7', '',
                'Wireless', 'Android', 'Mobile', '', '52',
                'False', '60:38:E0:2F:FD:09'),
(@id, '6a7d6898-9e83-417e-8e1d-f9c4410134ba', N'Kaytlyn’s iPad', N'Kaytlyn’s iPad', 'CE:A8:8E:23:8E:B3', '192.168.1.37', '',
                'Wireless', 'iOS', 'Tablet', '', '46',
                'False', 'E9:98:68:8E:A8:98');

-- Review the events with report table jointed with event table
select format(connectedDevicesReport.createdDateTime, 'dddd, MMMM dd, yyyy hh:mm:ss fff') 'Date/Time', *  from SOCLab.dbo.connected_devices_report connectedDevicesReport
join SOCLab.dbo.connected_devices connectedDevices on connectedDevices.reportID = connectedDevicesReport.reportID
order by createdDateTime desc

-- Store the known devices with its device ID
begin try
	insert into SOCLab.dbo.known_devices (deviceID, name, friendlyName)
	values 
	('03b13cdb-c542-4b1f-a17c-794206903945', '', N'Kaytlyn’s iPad'),
	('6a7d6898-9e83-417e-8e1d-f9c4410134ba', '', N'Kaytlyn’s iPad'),
	('0867e4a1-9886-48c8-b6c8-e8b0378f12be', '', 'DESKTOP-CHMUS0H'),
	('092039bb-e30a-462e-8ef8-383b0a7c4e81', '', 'NetworknowDevicesevice'),
	('1b8365fb-6b0f-4a81-84df-ff0445520c2e', '', 'Palo-Alto'),
	('30bdf6b7-ab23-4d01-9e25-0ff09f38cfe6', '', 'vivo'),
	('3456b2c5-86f7-11e6-8000-6038e02ffd08', '', 'Linksys'),
	('3513fb76-bf67-4990-be34-b0e6a56410b1', '', 'Android_K11S94XE'),
	('35d3571e-2c32-46af-b3e5-bbe60f17c6e7', '', 'iPad'),
	('38a31680-4ca5-4229-94a7-3802b407e184', '', 'LP-5CD338M1PN'),
	('462c18cd-01f2-4e4d-bf18-12b4e1b2ca3a', '', 'Galaxy8'),
	('70a7f65a-08a0-480d-982a-eceeb64c359c', '', 'DESKTOP-TTUN3KK'),
	('9097b026-2576-4a9d-b370-3417428f3674', '', '98" OLED'),
	('a07f0528-b3af-442b-933e-5bca0065a7b3', '', ''),
	('b48d94e9-2da3-4b0d-8536-944c4da53e58', '', 'Android_cc2cdf1dbce24b878a0287fa02534e10'),
	('cb882f8c-11b6-4bc7-850b-fbd0dc5380d6', '', 'iPad'),
	('cbbdb552-3df1-4018-ba2e-03b3206d6118', '', 'Android_8TFAY388'),
	('e651837a-19ac-4804-b232-e01fe480812f', '', 'Galaxy28');
end try
begin catch
	print 'Error message: ' + error_message();
end catch


-- Store the known MAC Address with its device ID
insert into SOCLab.dbo.known_MAC_Addresses (deviceID, macAddress)
	values
	('03b13cdb-c542-4b1f-a17c-794206903945', '6A:F4:91:0B:5E:28'),
	('0867e4a1-9886-48c8-b6c8-e8b0378f12be', 'E6:8E:03:51:D8:AE'),
	('092039bb-e30a-462e-8ef8-383b0a7c4e81', '3E:8A:2F:5C:D1:96'),
	('1b8365fb-6b0f-4a81-84df-ff0445520c2e', '56:7D:53:EC:C2:8A'),
	('30bdf6b7-ab23-4d01-9e25-0ff09f38cfe6', '82:05:3A:88:AE:39'),
	('3456b2c5-86f7-11e6-8000-6038e02ffd08', 'BA:9D:7A:1D:7B:28'),
	('3513fb76-bf67-4990-be34-b0e6a56410b1', '16:29:D6:A1:85:68'),
	('35d3571e-2c32-46af-b3e5-bbe60f17c6e7', 'A2:7A:87:CA:43:99'),
	('38a31680-4ca5-4229-94a7-3802b407e184', 'EA:A1:25:04:EA:33'),
	('462c18cd-01f2-4e4d-bf18-12b4e1b2ca3a', '26:6D:87:43:B2:23'),
	('6a7d6898-9e83-417e-8e1d-f9c4410134ba', 'CE:A8:8E:23:8E:B3'),
	('70a7f65a-08a0-480d-982a-eceeb64c359c', '6E:E8:A7:AC:C2:88'),
	('9097b026-2576-4a9d-b370-3417428f3674', '22:AE:06:D7:FA:36'),
	('a07f0528-b3af-442b-933e-5bca0065a7b3', '06:96:61:6E:A6:38'),
	('b48d94e9-2da3-4b0d-8536-944c4da53e58', '5A:11:DA:CA:82:18'),
	('cb882f8c-11b6-4bc7-850b-fbd0dc5380d6', '5E:3E:36:D5:63:98'),
	('cbbdb552-3df1-4018-ba2e-03b3206d6118', 'D6:1B:F3:83:7D:C8'),
	('e651837a-19ac-4804-b232-e01fe480812f', 'DA:A9:C0:9D:69:A8');


select knowDevices.*, '|' , knownMACAddresses.* from SOCLab.dbo.known_devices as knowDevices
left join SOCLab.dbo.known_MAC_Addresses as knownMACAddresses on knowDevices.deviceID = knownMACAddresses.deviceID
order by knowDevices.deviceID
go

--drop type if exists MACAddressTable
--drop type if exists MACAddressTablev2
--drop type if exists MACAddressTablev3

declare @maTable MACAddressTable;

 
insert into @maTable (macAddress)
values
('9E:E8:A8:AC:C2:88')

-- Test to make the isKnownDevice stored procedure is working as it should be.
exec SOCLab.dbo.isKnownDevice
	@unknownMACAddressTable = @maTable;



