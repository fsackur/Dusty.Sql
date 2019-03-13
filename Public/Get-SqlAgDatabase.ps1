function Get-SqlAgDatabase {
<#
    .Synopsis
    Gets information about all databases in all availability groups

    .Description
    Queries the server specified by the Instance parameter and finds all availability groups that that instance is part of. Returns information about all databases in all those availability groups.

    Uses the current user account to connect to SQL.

    By default, only returns information about databases that are replicated as part of an availability group.

    .Parameter Instance
    Specifies the instance to query for AG membership

    .Parameter IncludeNonReplicatedDatabases
    Include user databases that exist on a replica but are not part of any availability group replication

    .Example
    Get-SqlAgDatabase -Instance PARISDB2\ACCOUNTS | Format-Table

    Returns all replicas in all AGs that the PARISDB2\ACCOUNTS instance is part of, and formats as a table
#>
    param(
        [string]$Instance,
        [switch]$IncludeNonReplicatedDatabases
    )

    if ($IncludeNonReplicatedDatabases) {
        $JoinType = "LEFT OUTER"
    } else {
        $JoinType = "INNER"
    }

    $Query = "
        DECLARE @ServerName NVARCHAR(128)
        SET @ServerName = CONVERT(NVARCHAR(128), (SELECT SERVERPROPERTY('ServerName')))

        SELECT
	        ag.name AS availability_group
	        , @ServerName AS replica
	        , db.name
	        , db.database_id AS id
	        , db.state_desc
	        , dbrs.synchronization_state_desc
	        , dbrs.group_database_id
	        , dbrcs.is_failover_ready
            , dbrs.is_primary_replica

        FROM sys.databases AS db
        $JoinType JOIN sys.dm_hadr_database_replica_states AS dbrs --include non-replicated DBs
        ON dbrs.database_id = db.database_id

        $JoinType JOIN sys.dm_hadr_database_replica_cluster_states AS dbrcs
        ON dbrcs.group_database_id = dbrs.group_database_id AND dbrcs.replica_id = dbrs.replica_id

        $JoinType JOIN sys.availability_groups AS ag
        ON ag.group_id = dbrs.group_id

        WHERE
            (dbrs.is_local = 1 OR dbrs.is_local IS NULL)
            AND
            db.database_id NOT IN (1,2,3,4)
    "


    #Get all instances involved in AGs
    $Instances = Get-SqlAgInstance -Instance $Instance


    #We can only get primary/secondary info on the current instance, so we need to run this query against each SQL server
    $InstanceDBs = $Instances | foreach {
        Invoke-Sqlcmd -ServerInstance $_ -Query $Query
    }

    #Convert to a PSObject so that we can be clever about formatting
    $InstanceDBs | foreach {

        New-Object psobject -Property @{
            AvailabilityGroup = $_.availability_group | where {$_ -isnot [DBNull]};
            Replica = $_.replica;
            Database = $_.name;
            DatabaseId = $_.id;
            DatabaseState = $_.state_desc;
            SynchronizationState = $_.synchronization_state_desc;
            AgDatabaseId = $_.group_database_id;
            IsFailoverReady = $_.is_failover_ready | where {$_ -isnot [DBNull]};
            IsPrimary = $_.is_primary_replica | where {$_ -isnot [DBNull]};

        }

    #Apply formatting
    } | foreach {

        Add-DefaultMembers `
            -InputObject $_ `
            -SortProperties AvailabilityGroup, Replica `
            -DisplayProperties AvailabilityGroup, Replica, Database, IsFailoverReady, IsPrimary `
            -TypeName "Rax.SqlAgDatabase" `
            -PassThru            #return to pipeline

    }

}
