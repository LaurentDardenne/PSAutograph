# PSAutograph.psm1
# ------------------------------------------------------------------
# Depend : https://github.com/Microsoft/automatic-graph-layout
#    see : https://devblogs.microsoft.com/powershell/graphing-with-glee/
# ------------------------------------------------------------------

Import-LocalizedData -BindingVariable MSaglMsgs -Filename  PSAutographLocalizedData.psd1 -EA Stop

function New-MSaglViewer {
#from 
  Param(
   [Drawing.Size] $size = $(New-Object Drawing.Size @(600,600))
  )
  
  $form = New-Object Windows.Forms.Form
  $form.Size = $size

  $viewer = New-Object Microsoft.MSagl.GraphViewerGdi.GViewer
  $viewer.Dock = "Fill"
  $form.Controls.Add($viewer)
  #$form.Add_Shown( { $form.Activate() } ) todo
  return $form
}

function New-MSaglGraph{
 param (
  [string] $Name='Graph'
 )

 return  New-Object Microsoft.MSagl.Drawing.Graph($Name)
}#New-MSaglGraph

function Show-MSaglGraph{
  param(
   [Windows.Forms.Form] $viewer,
   [Microsoft.MSagl.Drawing.Graph] $Graph
  )

  $viewer.Controls[0].Graph = $graph
  $viewer.ShowDialog()
  $viewer.Controls[0].Graph = $null
}

function Set-MSaglNodeAttribute{
  param(
    [Microsoft.MSagl.Drawing.Graph] $Graph,
    [ScriptBlock] $FilterScript,
    $Property,
    $Value
  )
  
  foreach ($Node in ($graph.NodeMap.Keys | Foreach-Object  {$graph.NodeMap.$_}))
  { 
    if ($Node.UserData |Where-Object $FilterScript)
    { $Node.Attr.$Property = $Value  }
  }
}

function Set-MSaglGraphObject{
#Utilise une hashtable.
#Chaque nom de clé est un nom de type d'un objet à traiter, sa valeur est une hashtable possédant les clés suivantes :
# Follow_Property  : est un nom d'une propriété d'un objet, son contenu pouvant pointer sur un autre objet (de même type ou pas) ou être $null
# Follow_Label     : libellé de la relation (arête/edge) entre deux noeuds (sommet/vertex) du graphe
# Label_Property   : Nom de la propriété d'un objet contenant le libellé de chaque noeud (sommet) du graphe

# Exemple pour un objet service :
# $ObjectMap = @{
#     "System.ServiceProcess.ServiceController" = @{
#         Follow_Property = "ServicesDependedOn"
#         Follow_Label = "DependsUpon"    #Nom de la relation 
#         Label_Property = "Name"         #Nom du service
#         }
# } #$ObjectMap

  param(
    #L'objet Microsoft.MSagl.Drawing.Graph peuplé avec $InputObject selon le paramètrage défini dans $objectmap
    [Microsoft.MSagl.Drawing.Graph] $Graph,
    
    # Null est autorisé, dans ce cas le graph est vide la visualisation n'affichera rien.
    $InputObject,

    #Hashtable de définition des relations
    [HashTable] $objectMap
  )

  foreach ($o in $InputObject)
  {   
     #Recherche l'association pour l'objet courant
    $oMap = $ObjectMap.$($o.PsTypenames[0])
    if ($oMap)
    {
       #Ajoute un noeud au graphe
      $node = $graph.AddNode($o.$($oMap.Label_Property))
      $node.UserData = $o

      foreach ($property in $o.$($oMap.Follow_Property))
      {   
        $pMap = $ObjectMap.$($property.PsTypeNames[0])
        if ($pmap)
        {
           #Le type est  connue dans objectMap
           #Ajoute une liaison (arête) entre deux noeuds
           # AddEdge(string source, string edgeLabel, string target)
          [void]$graph.AddEdge($o.$($oMap.Label_Property), $oMap.Follow_Label, $Property.$($pMap.Label_Property))
          
           #Parcourt du graphe ( i.e des objets reliés au premier)
          if ($pMap.Follow_Property)
          { Set-MSaglGraphObject -graph $graph -inputObject $Property -ObjectMap $ObjectMap   }
        }
        else
        { 
           #Le type n'est pas référencé dans objectMap, alors  
          # le champ target contient le nom du type de l'objet
          [Void]$graph.AddEdge($o.$($oMap.Label_Property), $oMap.Follow_Label, $Property.ToString())   
        }
      }
    }
  }
}

#Bug du parser ou beta ? 
# function ConvertFrom-DOTlanguage {
#   param(
#      [Parameter(Position=1, Mandatory=$true)]
#      [ValidateNotNullOrEmpty()]
#    [string] $Path 
#  )
#   
#  [int] $line=-1
#  [int] $column=-1
#  [string] $msg=[string]::Empty
#  [Microsoft.MSagl.Drawing.Graph] $Graph=$null
#   #todo contrôles I/O
#  $graph = [Dot2Graph.Parser]::Parse($Path, [ref] $line, [ref] $column, [ref] $msg)
#  if ($graph) 
#  { return $graph } 
#  else
#  {
#     $exmsg="Conversion impossible`r`n" #todo localisation
#     Throw "$exmsg $msg "+(": line {0} column {1}" -F $line, $column)
#     #return $null
#  }
# }#ConvertFrom-DOTlanguage

#bug : le libéllé d'une arête n'est pas au norme  
# function ConvertTo-DOTlanguage {
#  param (
#     [Parameter(Position=1, Mandatory=$true)]
#     [ValidateNotNull()]
#   [Microsoft.MSagl.Drawing.Graph] $Graph,
#    
#    [Parameter(Position=2, Mandatory=$true)]
#    [ValidateNotNullOrEmpty()]
#   [string] $Path
#  )
#   #todo contrôles I/O
#  $Graph.ToString() > $path
# }#ConvertTo-DOTlanguage

