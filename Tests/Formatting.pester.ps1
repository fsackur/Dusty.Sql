Import-Module $PSScriptRoot\..\Formatting.psm1 -Force


Describe 'Add-DefaultMembers' {

    #Set up the test stuff

    #Global variables for this Describe
    $DisplayProperties = "Material", "Size"
    $SortProperties = "Size"
    $TypeName = "Silly.Pester.TypeName"

    #Repeated test blocks
    $ScriptblockDisplay = {
        $_.PSStandardMembers.DefaultDisplayPropertySet.ReferencedPropertyNames | 
            Should BeExactly $DisplayProperties
    }
    $ScriptblockSort ={
        $_.PSStandardMembers.DefaultKeyPropertySet.ReferencedPropertyNames | 
            Should BeExactly $SortProperties
    }

    $ScriptblockType ={
        $_.PSTypeNames[0] | Should BeExactly $TypeName
    }



    Context 'Input from argument, update by reference' {

        $MyObject = New-Object psobject -Property @{
            Material="Wood"; Size=15; FearFactor=9; ComfortLevel=12; Id=(New-Guid).Guid
        }

        Add-DefaultMembers `
            -InputObject $MyObject `
            -DisplayProperties $DisplayProperties `
            -SortProperties $SortProperties `
            -TypeName $TypeName

        It 'Adds display properties' { $MyObject | foreach $ScriptblockDisplay }
        It 'Adds sort properties' { $MyObject | foreach $ScriptblockSort }
        It 'Adds type name' { $MyObject | foreach $ScriptblockType }

    }

    Context 'Used in pipeline' {

        $MyObject = New-Object psobject -Property @{
            Material="Wood"; Size=15; FearFactor=9; ComfortLevel=12; Id=(New-Guid).Guid
        }

        $MyArray = @(
            (New-Object psobject -Property @{
                Material="Wood"; Size=15; FearFactor=9; ComfortLevel=12; Id=(New-Guid).Guid}),
            (New-Object psobject -Property @{
                Material="Steel"; Size=9; FearFactor=43; ComfortLevel=1; Id=(New-Guid).Guid}),
            (New-Object psobject -Property @{
                Material="Cheese"; Size=60; FearFactor=0; ComfortLevel=99; Id=(New-Guid).Guid})
        )

        It 'Handles single object' {
            $Result = $MyObject | Add-DefaultMembers `
                -DisplayProperties $DisplayProperties `
                -SortProperties $SortProperties `
                -TypeName $TypeName `
                -PassThru

            $Result | foreach $ScriptblockDisplay
            $Result | foreach $ScriptblockSort
            $Result | foreach $ScriptblockType
        }

        It 'Handles array input' {
            $Result = $MyArray | Add-DefaultMembers `
                -DisplayProperties $DisplayProperties `
                -SortProperties $SortProperties `
                -TypeName $TypeName `
                -PassThru

            $Result.Count | Should BeExactly $MyArray.Count
            $Result | foreach $ScriptblockDisplay
            $Result | foreach $ScriptblockSort
            $Result | foreach $ScriptblockType
        }
    }

}
