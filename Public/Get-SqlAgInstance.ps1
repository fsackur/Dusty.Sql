function Get-SqlAgInstance {
    param(
        [string]$Instance
    )

    Invoke-Sqlcmd `
        -ServerInstance $Instance `
        -Query "SELECT DISTINCT (replica_server_name) FROM sys.availability_replicas" |
            select -ExpandProperty replica_server_name

}
