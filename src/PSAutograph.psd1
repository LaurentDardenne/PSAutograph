# Laurent Dardenne le 29/06/215
@{
	ModuleToProcess = 'PSAutoGraph.psm1'

	ModuleVersion = '1.1.1'
 
	GUID = 'c39c549d-082e-473c-9a4b-331c8ac85807'
	
	Author = 'Laurent Dardenne' 

	Description = 'Cmdlets to manage Microsoft Automatic Graph Layout.'

	PowerShellVersion = '4.0'
  
	RequiredAssemblies = @(
       (Join-Path $psScriptRoot '\bin\Microsoft.Msagl.dll'),
       (Join-Path $psScriptRoot '\bin\Microsoft.Msagl.Drawing.dll'),
       (Join-Path $psScriptRoot '\bin\Microsoft.Msagl.GraphViewerGdi.dll'),
       'System.Windows.Forms' #       (Join-Path $psScriptRoot 'Dot2Graph.dll')
    )
}

