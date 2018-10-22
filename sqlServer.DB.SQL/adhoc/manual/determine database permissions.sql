


Select 'Server level security granted to a SQL User, Windows User/Group, or Server Role'
Go

Select Distinct 
	perm.class_desc As ObjectType
	,@@ServerName As ObjectName
    ,ServerLogin = princ.[name]
    ,LoginType = CASE princ.[type]
                    WHEN 'S' THEN 'SQL User'
                    WHEN 'U' THEN 'Windows User'
                    WHEN 'G' THEN 'Windows Group'
                    WHEN 'R' THEN 'SQL Role'
                 END  
	,perm.permission_name As PermissionType
	,perm.state_desc As PermissionState
	,IsNull(servRole.RoleName,'No Role Assigned') As AssignedServerRole
From
	-- Server Login
	sys.server_principals princ 
	-- Permissions
	Inner Join sys.server_permissions perm On 
		princ.principal_id = perm.grantee_principal_id
	-- Server Role
	Left Outer Join
	(
		Select
			roleMem.member_principal_id As Principal_Id
			,roleName.[Name] as roleName
		From
			sys.server_role_members roleMem
			Inner Join sys.server_principals roleName On 
				roleMem.role_principal_id = roleName.principal_id
	) servRole On 
		princ.principal_id = servRole.Principal_Id
Where
	princ.[Type] in ('S','U','G','R')
	And
	princ.[Name] Not In ('sys','INFORMATION_SCHEMA','dbo')
Order By
	princ.[name]

Select 'Database level security granted to a SQL User, Windows User/Group, or Database Role'
Go

Select 
	perm.class_desc As ObjectType
	,DB_Name() As ObjectName
    ,ServerLogin = servPrinc.[name]
    ,LoginType = CASE princ.[type]
                    WHEN 'S' THEN 'SQL User'
                    WHEN 'U' THEN 'Windows User'
                    WHEN 'G' THEN 'Windows Group'
                    WHEN 'R' THEN 'SQL Role'
                 END
    ,DatabaseUser = princ.[name]   
	,perm.permission_name As PermissionType
	,perm.state_desc As PermissionState
	,IsNull(dbRole.RoleName,'No Role Assigned') As AssignedDBRole
From
	-- Database User
	sys.database_principals princ 
	-- Permissions
	Inner Join sys.database_permissions perm On 
		princ.principal_id = perm.grantee_principal_id
	-- Database Role
	Left Outer Join
	(
		Select
			dbRoleMember.member_principal_id As Principal_Id
			,dbRoleName.[Name] as RoleName
		From
			sys.database_role_members dbRoleMember
			Inner Join sys.database_principals dbRoleName On 
				dbRoleMember.role_principal_id = dbRoleName.principal_id
	) dbRole On 
		princ.principal_id = dbRole.Principal_Id
	-- Server Login
	Left Outer Join sys.database_principals servPrinc On
		princ.principal_id = servPrinc.principal_id
Where
	princ.[Type] in ('S','U','G','R')
	And
	princ.[Name] Not In ('sys','INFORMATION_SCHEMA','dbo')
	And
	perm.class_desc = 'Database'
Go

Select 'Below database level security granted to a SQL User, Windows User/Group, or Role'
Go

Select
	'Table' As ObjectType
	,Table_Name As ObjectName
Into
	#SQLObjects
From
	Information_Schema.Tables
Where
	Table_Type = 'BASE TABLE'
	
Union All

Select
	'View' As ObjectType
	,Table_Name As ObjectName
From
	Information_Schema.Tables
Where
	Table_Type = 'View'
	
Union All

select 
	'User Defined Function' As ObjectType
	,r.routine_schema + '.' + p.[name] as objectName
from
	sys.objects p
	inner join sys.sql_modules m on p.object_id = m.object_id
	inner join information_schema.routines r on p.[name] = r.routine_name
where
	p.[type] = 'FN'

Union All

Select 
	'Stored Procedure' As ObjectType
	,r.routine_schema + '.' + p.[name] as objectName
From
	sys.procedures p
	inner join sys.sql_modules m on p.object_id = m.object_id
	inner join information_schema.routines r on p.[name] = r.routine_name

-- start permission search

Select 
	o.ObjectType As ObjectType
	,OBJECT_NAME(perm.major_id) As ObjectName
    ,UserName = servPrinc.[name]
    ,LoginType = CASE princ.[type]
                    WHEN 'S' THEN 'SQL User'
                    WHEN 'U' THEN 'Windows User'
                    WHEN 'G' THEN 'Windows Group'
                    WHEN 'R' THEN 'SQL Role'
                 END
    ,DatabaseUser = princ.[name]   
	,perm.permission_name As PermissionType
	,perm.state_desc As PermissionState
From
	-- Database User
	sys.database_principals princ 
	-- Permissions
	Inner Join sys.database_permissions perm On 
		princ.principal_id = perm.grantee_principal_id
	Inner Join #SQLObjects o On 
		OBJECT_NAME(perm.major_id) = o.ObjectName
	-- Server Login
	Left Outer Join sys.database_principals servPrinc On
		princ.principal_id = servPrinc.principal_id
Where
	princ.[Type] in ('S','U','G','R')
	And
	--princ.[Name] Not In ('sys','INFORMATION_SCHEMA','dbo')
	--And
	perm.class_desc != 'Database'
Go
