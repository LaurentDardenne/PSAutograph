@{
	ModuleToProcess = 'PSAutoGraph.psm1'

	ModuleVersion = '1.3.0'

	GUID = 'c39c549d-082e-473c-9a4b-331c8ac85807'

	Author = 'Laurent Dardenne'

	Description = 'Cmdlets to manage Microsoft Automatic Graph Layout.'

	PowerShellVersion = '4.0'

	RequiredAssemblies = @(
       (Join-Path $psScriptRoot '\bin\AutomaticGraphLayout.dll'),
       (Join-Path $psScriptRoot '\bin\AutomaticGraphLayout.Drawing.dll'),
       (Join-Path $psScriptRoot '\bin\Microsoft.Msagl.GraphViewerGdi.dll'),
       'System.Windows.Forms'
    )

    # Private data to pass to the module specified in RootModule/ModuleToProcess.
    PrivateData = @{

        # PSData data to pass to the Publish-Module cmdlet
        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('PSEdition_Desktop')

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/LaurentDardenne/PSAutograph'

        } # End of PSData hashtable
    }
}

