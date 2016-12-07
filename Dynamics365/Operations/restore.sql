USE [master]
GO

RESTORE DATABASE [MicrosoftDynamicsAX] 
	FROM DISK = N'C:\VSTS\drops\backup\MicrosoftDynamicsAX.bak' WITH FILE = 1,  
	MOVE N'MicrosoftDynamicsAX' TO N'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\MicrosoftDynamicsAX.mdf',  
	MOVE N'MicrosoftDynamicsAX_log' TO N'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\MicrosoftDynamicsAX_log.ldf',  
	NOUNLOAD,  REPLACE,  STATS = 5
GO

CREATE DATABASE [MicrosoftDynamicsAX_model]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'MicrosoftDynamicsAX_model', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\MicrosoftDynamicsAX_model.mdf' , SIZE = 1048576KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'MicrosoftDynamicsAX_model_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\MicrosoftDynamicsAX_model_log.ldf' , SIZE = 8192KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
GO

IF NOT EXISTS (SELECT name FROM master.sys.server_principals WHERE sid = 0x010100000000000514000000)
BEGIN
 CREATE LOGIN [NT AUTHORITY\NETWORK SERVICE] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english]
End
GO

ALTER SERVER ROLE [sysadmin] ADD MEMBER [NT AUTHORITY\NETWORK SERVICE]
GO




