function Get-SqlAgFailoverReadiness {
<#
    .Synopsis
    Gets information about failover readiness of all replicas in all availability groups

    .Description
    Queries the server specified by the Instance parameter and finds all availability groups that that instance is part of. Returns information about all replicas in all those availability groups.

    Uses the current user account to connect to SQL.

    IsFailoverReady is true if all databases on a replica are failover-ready. If this property shows false on a secondary and you fail over the primary replica to this secondary, you will have to accept data loss. To make this show true, you will need to set the current primary and the target secondary replicas to Synchronous Commit mode and wait.

    HasNonReplicatedDatabases is true if there are any user databases present on an instance that are not replicated in an availability group. These databases may experience downtime along with the server they reside on unless they have another high-availability strategy.

    .Parameter Instance
    Specifies the instance to query for AG membership

    .Example
    Get-SqlAgFailoverReadiness -Instance PARISDB2\ACCOUNTS | Format-Table

    Returns all replicas in all AGs that the PARISDB2\ACCOUNTS instance is part of, and formats as a table
#>
    param(
        [string]$Instance
    )

    $DBs = Get-SqlAgDatabase @PSBoundParameters -IncludeNonReplicatedDatabases

    $ReplicatedDBs = $DBs | where {$null -ne $_.IsPrimary}

    $NonReplicatedDBs = $DBs | where {$null -eq $_.IsPrimary}

    $Replicas = $ReplicatedDBs |
        #This puts the "false" above the "true" for IsFailoverReady
        sort AvailabilityGroup, Replica, IsFailoverReady -Unique |
        #This removes the "true" for IsFailoverReady
        sort AvailabilityGroup, Replica -Unique |
        #strip out DB-related properties
        select AvailabilityGroup, Replica, IsPrimary, IsFailoverReady


    foreach ($Replica in $Replicas) {

        $Replica |

            Add-Member -MemberType NoteProperty -Name NonReplicatedDatabases -Value (
                $NonReplicatedDBs | where {$_.Replica -eq $Replica.Replica} | select -ExpandProperty Database
            ) -PassThru |

            Add-Member -MemberType ScriptProperty -Name HasNonReplicatedDatabases -Value {
                    $null -ne $_.NonReplicatedDatabases
                } -PassThru |

            Add-DefaultMembers `
                -SortProperties AvailabilityGroup, Replica `
                -DisplayProperties AvailabilityGroup, Replica, IsPrimary, IsFailoverReady, HasNonReplicatedDatabases `
                -TypeName "Rax.SqlAgReplica" `
                -PassThru        #write to pipeline

    }


}
