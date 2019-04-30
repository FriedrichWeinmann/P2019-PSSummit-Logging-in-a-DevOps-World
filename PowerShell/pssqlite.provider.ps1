# Action that is performed on registration of the provider using Register-PSFLoggingProvider
$registrationEvent = {
	
}

#region Logging Execution
# Action that is performed when starting the logging script (or the very first time if enabled after launching the logging script)
$begin_event = {
	
}

# Action that is performed at the beginning of each logging cycle
$start_event = {
	$pssqlite_datasource = (Get-PSFConfigValue -FullName 'PSFramework.Logging.PSSqlite.Datasource')
}

# Action that is performed for each message item that is being logged
$message_Event = {
	Param (
		$Message
	)
	
    Invoke-SqliteQuery -DataSource $pssqlite_datasource -Query @"
INSERT INTO psframework.logs (Timestamp, Message)
VALUES ('$($Message.Timestamp)','$($Message.LogMessage)');
"@
}

# Action that is performed for each error item that is being logged
$error_Event = {
	Param (
		$ErrorItem
	)
	
	
}

# Action that is performed at the end of each logging cycle
$end_event = {
	
}

# Action that is performed when stopping the logging script
$final_event = {
	
}
#endregion Logging Execution

#region Function Extension / Integration
# Script that generates the necessary dynamic parameter for Set-PSFLoggingProvider
$configurationParameters = {
	$configroot = "psframework.logging.pssqlite"
	
	$configurations = Get-PSFConfig -FullName "$configroot.*"
	
	$RuntimeParamDic = New-Object  System.Management.Automation.RuntimeDefinedParameterDictionary
	
	foreach ($config in $configurations)
	{
		$ParamAttrib = New-Object System.Management.Automation.ParameterAttribute
		$ParamAttrib.ParameterSetName = '__AllParameterSets'
		$AttribColl = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
		$AttribColl.Add($ParamAttrib)
		$RuntimeParam = New-Object System.Management.Automation.RuntimeDefinedParameter(($config.FullName.Replace($configroot, "").Trim(".")), $config.Value.GetType(), $AttribColl)
		
		$RuntimeParamDic.Add(($config.FullName.Replace($configroot, "").Trim(".")), $RuntimeParam)
	}
	return $RuntimeParamDic
}

# Script that is executes when configuring the provider using Set-PSFLoggingProvider
$configurationScript = {
	$configroot = "psframework.logging.pssqlite"
	
	$configurations = Get-PSFConfig -FullName "$configroot.*"
	
	foreach ($config in $configurations)
	{
		if ($PSBoundParameters.ContainsKey(($config.FullName.Replace($configroot, "").Trim("."))))
		{
			Set-PSFConfig -Module $config.Module -Name $config.Name -Value $PSBoundParameters[($config.FullName.Replace($configroot, "").Trim("."))]
		}
	}
}

# Script that returns a boolean value. "True" if all prerequisites are installed, "False" if installation is required
$isInstalledScript = {
	$null -ne (Get-Module PSSqlite -ListAvailable)
}

# Script that provides dynamic parameter for Install-PSFLoggingProvider
$installationParameters = {
	# None needed
}

# Script that performs the actual installation, based on the parameters (if any) specified in the $installationParameters script
$installationScript = {
	Install-Module PSSqlite
}
#endregion Function Extension / Integration

# Configuration settings to initialize
$configuration_Settings = {
	Set-PSFConfig -Module PSFramework -Name 'Logging.PSSQLite.Datasource' -Value "$($env:AppData)\log.sqlite" -Initialize -Validation string -Handler { } -Description "The path to where the logfile is written."
    
    Set-PSFConfig -Module LoggingProvider -Name 'PSSQLite.Enabled' -Value $false -Initialize -Validation "bool" -Handler { if ([PSFramework.Logging.ProviderHost]::Providers['pssqlite']) { [PSFramework.Logging.ProviderHost]::Providers['pssqlite'].Enabled = $args[0] } } -Description "Whether the logging provider should be enabled on registration"
	Set-PSFConfig -Module LoggingProvider -Name 'PSSQLite.AutoInstall' -Value $true -Initialize -Validation "bool" -Handler { } -Description "Whether the logging provider should be installed on registration"
	Set-PSFConfig -Module LoggingProvider -Name 'PSSQLite.InstallOptional' -Value $false -Initialize -Validation "bool" -Handler { } -Description "Whether installing the logging provider is mandatory, in order for it to be enabled"
	Set-PSFConfig -Module LoggingProvider -Name 'PSSQLite.IncludeModules' -Value @() -Initialize -Validation "stringarray" -Handler { if ([PSFramework.Logging.ProviderHost]::Providers['pssqlite']) { [PSFramework.Logging.ProviderHost]::Providers['pssqlite'].IncludeModules = $args[0] } } -Description "Module whitelist. Only messages from listed modules will be logged"
	Set-PSFConfig -Module LoggingProvider -Name 'PSSQLite.ExcludeModules' -Value @() -Initialize -Validation "stringarray" -Handler { if ([PSFramework.Logging.ProviderHost]::Providers['pssqlite']) { [PSFramework.Logging.ProviderHost]::Providers['pssqlite'].ExcludeModules = $args[0] } } -Description "Module blacklist. Messages from listed modules will not be logged"
	Set-PSFConfig -Module LoggingProvider -Name 'PSSQLite.IncludeTags' -Value @() -Initialize -Validation "stringarray" -Handler { if ([PSFramework.Logging.ProviderHost]::Providers['pssqlite']) { [PSFramework.Logging.ProviderHost]::Providers['pssqlite'].IncludeTags = $args[0] } } -Description "Tag whitelist. Only messages with these tags will be logged"
	Set-PSFConfig -Module LoggingProvider -Name 'PSSQLite.ExcludeTags' -Value @() -Initialize -Validation "stringarray" -Handler { if ([PSFramework.Logging.ProviderHost]::Providers['pssqlite']) { [PSFramework.Logging.ProviderHost]::Providers['pssqlite'].ExcludeTags = $args[0] } } -Description "Tag blacklist. Messages with these tags will not be logged"
}

$paramRegisterPSFLoggingProvider = @{
	Name				    = "PSSQLite"
	RegistrationEvent	    = $registrationEvent
	BeginEvent			    = $begin_event
	StartEvent			    = $start_event
	MessageEvent		    = $message_Event
	ErrorEvent			    = $error_Event
	EndEvent			    = $end_event
	FinalEvent			    = $final_event
	ConfigurationParameters = $configurationParameters
	ConfigurationScript	    = $configurationScript
	IsInstalledScript	    = $isInstalledScript
	InstallationScript	    = $installationScript
	InstallationParameters  = $installationParameters
	ConfigurationSettings   = $configuration_Settings
}

Register-PSFLoggingProvider @paramRegisterPSFLoggingProvider