
Import-Module PSAutograph

$viewer = New-MSaglViewer
$ObjectMap = @{
  "System.ServiceProcess.ServiceController" = @{
    Follow_Property = "ServicesDependedOn"
    Follow_Label = "DependsUpon"
    Label_Property = "Name"
  }
}

$graph = New-MSaglGraph
Set-MSaglGraphObject -Graph $graph -InputObject (gsv net*p*) -ObjectMap $ObjectMap 

$resultModal=Show-MSaglGraph $viewer $graph
