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
    Write-Debug "Set-MSaglGraphObject: call"
    foreach ($o in $InputObject)
    {   
       #Recherche l'association pour l'objet courant
      $oMap = $ObjectMap.$($o.PsTypenames[0])
      if ($oMap)
      {
        #Ajoute un noeud au graphe
        $Label=$oMap.Label_Property
        $FollowProperty=$oMap.Follow_Property
        $FollowLabel=$oMap.Follow_Label
        Write-Debug "Set-MSaglGraphObject: oMap  '$Label' '$FollowProperty' '$Followlabel'"
        Write-Debug "Set-MSaglGraphObject: CreateNode '$($o.$Label)'"               
        
        $node = $graph.AddNode($o.$Label)
        $node.UserData = $o
   
        Write-debug "foreach on o '$FollowProperty' -> $($o.$FollowProperty)"
        foreach ($property in $o.$FollowProperty)
        {   
          Write-Debug "Set-MSaglGraphObject:  property ='$property'"
          $pMap = $ObjectMap.$($property.PsTypeNames[0])
          if ($pmap)
          {
            Write-Debug "Set-MSaglGraphObject:  pMmap.Label_property ='$($pMap.Label_Property)'"
             #Le type est  connue dans objectMap
             #Ajoute une liaison (arête) entre deux noeuds
             # AddEdge(string source, string edgeLabel, string target)
            Write-Debug "Set-MSaglGraphObject: Add '$($o.$Label)' '$FollowLabel' '$($Property.$($pMap.Label_Property))'"
            [void]$graph.AddEdge($o.$Label, $FollowLabel, $Property.$($pMap.Label_Property))
            
             #Parcourt du graphe ( i.e des objets reliés au premier)
            if ($pMap.Follow_Property)
            { Set-MSaglGraphObject -graph $graph -inputObject $Property -ObjectMap $ObjectMap   }
          }
          else
          { 
             #Le type n'est pas référencé dans objectMap, alors  
            # le champ target contient le nom du type de l'objet
            Write-Debug "Set-MSaglGraphObject: Add not ref '$($o.$Label)' '$FollowLabel' '$($Property.ToString())'"
            [Void]$graph.AddEdge($o.$Label, $FollowLabel, $Property.ToString())   
          }
        }
      }
    }
  }
  
  function Set-MSaglGraphObjectWithNode{
    param(
      #L'objet Microsoft.MSagl.Drawing.Graph peuplé avec $InputObject selon le paramètrage défini dans $objectmap
      [Microsoft.MSagl.Drawing.Graph] $Graph,
      
      # Null est autorisé, dans ce cas le graph est vide la visualisation n'affichera rien.
      $InputObject,
  
      #Hashtable de définition des relations
      [HashTable] $objectMap
    )

    Write-Debug "Set-MSaglGraphObjectWithNode: call"
    foreach ($o in $InputObject)
    {   
       #Recherche l'association pour l'objet courant
      $oMap = $ObjectMap.$($o.PsTypenames[0])
      if ($oMap)
      {
         #Ajoute un noeud au graphe
        $Label=$oMap.Label_Property
        $ID=$oMap.ID_Property
        $FollowProperty=$oMap.Follow_Property
        $FollowLabel=$oMap.Follow_Label
        Write-Debug "Set-MSaglGraphObjectWithNode: oMap '$ID' '$Label' '$FollowProperty' '$Followlabel'"
        Write-Debug "Set-MSaglGraphObjectWithNode: Create Node '$($o.$ID)' '$($o.$Label)'"
  
        $Node= [Microsoft.Msagl.Drawing.Node]::New($o.$ID)
        $Node.LabelText=$o.$Label
        $Node.UserData = $o
        $graph.AddNode($Node) > $null

        Write-debug "foreach on o '$FollowProperty' -> $($o.$FollowProperty)"
        foreach ($property in $o.$FollowProperty)
        {   
          Write-Debug "Set-MSaglGraphObjectWithNode:  property ='$property'"
          $pMap = $ObjectMap.$($property.PsTypeNames[0])
         
          if ($pmap)
          {
            Write-Debug "Set-MSaglGraphObjectWithNode:  pMmap.ID_property ='$($pMap.ID_Property)'"
            #Le type est  connue dans objectMap
             #Ajoute une liaison (arête) entre deux noeuds
             # AddEdge(string source, string edgeLabel, string target)
             Write-Debug "Set-MSaglGraphObjectWithNode: Add '$($o.$ID)' '$FollowLabel' '$($Property.$($pMap.ID_Property))'"
  
              #On crée le noeud sinon AddEdge le crée mais, à priori et pour ici, pas de la 'bonne manière'.
              #todo $graph.FindNode(($Property.$($pMap.ID_Property)))
             $Node= [Microsoft.Msagl.Drawing.Node]::New( $Property.$($pMap.ID_Property))
             $Node.Labeltext= $Property.$($pMap.Label_Property)
             $Node.UserData = $Property
             $graph.AddNode($Node) > $null
             [void]$graph.AddEdge($o.$ID, $FollowLabel, $Property.$($pMap.ID_Property))
  
             #Parcourt du graphe ( i.e des objets reliés au premier)
            if ($pMap.Follow_Property)
            { Set-MSaglGraphObjectWithNode -graph $graph -InputObject $Property -ObjectMap $ObjectMap   }
          }
          else
          { 
             #Le type n'est pas référencé dans objectMap, alors  
             # le champ target contient le nom du type de l'objet
            Write-Debug "Set-MSaglGraphObjectWithNode: Add not ref '$($o.$ID)' '$FollowLabel' '$($Property.ToString())'"
            [Void]$graph.AddEdge($o.$ID, $FollowLabel, $Property.ToString())   
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

