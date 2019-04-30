# Failsafe
return

 #----------------------------------------------------------------------------# 
 #                             Logging in Action                              # 
 #----------------------------------------------------------------------------# 

# Write a message
Write-PSFMessage "Test"
Write-PSFMessage "Test 2" -Verbose
# Retrieve it
Get-PSFMessage
# Same as before, but ... Level?:
Write-PSFMessage -Level Verbose -Message "Test" -Verbose
# What Levels?
Write-PSFMessage -Level Host -Message "Test to Host"
Write-PSFMessage -Level Warning -Message "Test warning"
Write-PSFMessage -Level Debug -Message "Test Debug" -Debug

<#
All Linear Levels, 1-1 match of Write-* commands?
No.
Numeric range of levels: 1 - 9
- Host: Level 2
- Verbose: Level 5
- Debug: Level 8

Default Visible Range: 1-3
Default Verbose Range: 4-6
#>
Get-PSFConfig -Module PSFramework -Name message.info.maximum
Set-PSFConfig -Module PSFramework -Name message.info.maximum -Value 6

Write-PSFMessage -Level SomewhatVerbose -Message 'Test Message for the strong and silent amongst us'

Write-PSFMessage -Level VeryVerbose -Message 'For those of us that need to share.'

Set-PSFConfig -Module PSFramework -Name message.info.maximum -Value 3

# Fooling around
Write-PSFMessage -Level Host -Message 'This <c="em">might</c> get a <c="sub">little</c> <c="red">colorful</c>!'


# Log...file?
Get-PSFConfigValue -FullName psframework.logging.filesystem.logpath | Invoke-Item

# Failing with a plan
try { $null.GetFoo() }
catch { Write-PSFMessage -Level Warning -Message 'I failed' -ErrorRecord $_ }

Get-PSFMessage | Select-Object -Last 1 | Format-List Message, Level, ErrorRecord

# Proxy
Set-Alias Write-Host Write-PSFMessageProxy
Write-Host "Kittens are an evil distraction"

# --> PowerPoint (sorry)


 #----------------------------------------------------------------------------# 
 #                              The Architecture                              # 
 #----------------------------------------------------------------------------# 

# Asynchronous: The Runspace
Get-Runspace | Format-Table -AutoSize

Get-PSFRunspace

# Asynchronous: Writing Messages
# The full data revealed
Get-PSFMessage | Select-Object -Last 1 | Format-List *

$null = 1..5 | Start-RSJob {
    $outer = $_
    1..10 | ForEach-Object {
        Start-Sleep -Milliseconds (Get-Random -Minimum 1000 -Maximum 5000)
        Write-PSFMessage -Message "Asynchronous $outer | $_" -Tag Async
    }
} -Throttle 99
Get-PSFMessage -Tag Async | Format-Table Timestamp, Runspace, Message

# The Queue:
Write-PSFMessage Foo
Write-PSFMessage Bar
[PSFramework.Message.LogHost]::OutQueueLog.Count

# Logging Provider
Get-PSFLoggingProvider

Set-PSFLoggingProvider -Name logfile -FilePath (Resolve-PSFPath demo:\logfile.csv -NewChild) -Enabled $true
Write-PSFMessage -Level Host -Message "Demo for logfile"
code (Resolve-Path demo:\logfile.csv).ProviderPath

# Logging Provider: Filter
Set-PSFLoggingProvider -Name logfile -IncludeModules MyModule
Write-PSFMessage -Message "Test 1"
Write-PSFMessage -Message "Test 2" -ModuleName MyModule

# --> PowerPoint (sorry)


 #----------------------------------------------------------------------------# 
 #                                Multilingual                                # 
 #----------------------------------------------------------------------------# 

# Introducing Language Files
code "$filesRoot\strings_de.psd1"
code "$filesRoot\strings_en.psd1"
Import-PSFLocalizedString -Path "$filesRoot\strings_de.psd1" -Module Litter -Language de-DE
Import-PSFLocalizedString -Path "$filesRoot\strings_en.psd1" -Module Litter -Language en-US
$PSDefaultParameterValues['Write-PSFMessage:ModuleName'] = 'Litter'
Get-PSFConfig -FullName PSFramework.Localization.Language

Write-PSFMessage -String 'Kittens.Petting' -StringValues 'Fred' -Level Host -Tag Kittens
Set-PSFConfig -FullName PSFramework.Localization.Language -Value 'de-DE'
Write-PSFMessage -String 'Kittens.Petting' -StringValues 'Jeffrey' -Level Host -Tag Kittens
Get-PSFMessage -Tag Kittens
Set-PSFConfig -FullName PSFramework.Localization.Language -Value 'en-US'
Get-PSFMessage -Tag Kittens
# --> Language changes dynamically
# --> Check the logs

# Managing the logging language
Get-PSFConfig -FullName PSFramework.Localization.LoggingLanguage

# --> PowerPoint (sorry)


 #----------------------------------------------------------------------------# 
 #                             Extending Logging                              # 
 #----------------------------------------------------------------------------# 

# a) Creating a simple provider
#-------------------------------

Register-PSFLoggingProvider -Name EventLog1 -MessageEvent {
    param ($Message)
    
    $paramWriteEventLog = @{
        LogName   = "Windows PowerShell"
        Source    = "PowerShell"
        EntryType = 'Information'
        Category  = 1
        EventId   = 1000
        Message   = ($Message | Format-List * | Out-String)
    }
    
    Write-EventLog @paramWriteEventLog
} -Enabled
Write-PSFMessage -Message 'Just some random line of string so people see something.'
Get-WinEvent -FilterHashtable @{
    LogName = 'Windows PowerShell'
    Id = 1000
} | Select-Object -ExpandProperty Properties | Select-Object -ExpandProperty Value

# b) Handling errors
#---------------------

Register-PSFLoggingProvider -Name EventLog2 -MessageEvent {
    param ($Message)
    
    $paramWriteEventLog = @{
        LogName   = "Windows PowerShell"
        Source    = "PowerShell"
        EntryType = 'Information'
        Category  = 1
        EventId   = 1000
        Message   = ($Message | Format-List * | Out-String)
    }
    
    Write-EventLog @paramWriteEventLog
} -ErrorEvent {
    param ($Exception)
    
    $paramWriteEventLog = @{
        LogName   = "Windows PowerShell"
        Source    = "PowerShell"
        EntryType = 'Error'
        Category  = 1
        EventId   = 666
        Message   = ($Exception | ConvertTo-PSFClixml)
    }
    
    Write-EventLog @paramWriteEventLog
} -Enabled
Set-PSFLoggingProvider -Name EventLog1 -Enabled $false
try { $null.GetFoo() }
catch { Write-PSFMessage -Level Warning -Message "Failed" -ErrorRecord $_ }

# Get Error Message from Event
Get-WinEvent -FilterHashtable @{
    LogName = 'Windows PowerShell'
    Id = 666
} | Select-Object -ExpandProperty Properties | Select-Object -ExpandProperty Value | ConvertFrom-PSFClixml


# c) Warnings should be warnings
#---------------------------------

Register-PSFLoggingProvider -Name EventLog3 -MessageEvent {
    param ($Message)
    
    if ($Message.Level -like 'Warning') {
        $eventLogType = 'Warning'
        $eventLogID = 1001
    }
    else {
        $eventLogType = 'Information'
        $eventLogID = 1000
    }

    $paramWriteEventLog = @{
        LogName   = "Windows PowerShell"
        Source    = "PowerShell"
        EntryType = $eventLogType
        Category  = 1
        EventId   = $eventLogID
        Message   = ($Message | Format-List * | Out-String)
    }
    
    Write-EventLog @paramWriteEventLog
} -ErrorEvent {
    param ($Exception)
    
    $paramWriteEventLog = @{
        LogName   = "Windows PowerShell"
        Source    = "PowerShell"
        EntryType = 'Error'
        Category  = 1
        EventId   = 666
        Message   = ($Exception | ConvertTo-PSFClixml)
    }
    
    Write-EventLog @paramWriteEventLog
} -Enabled
Set-PSFLoggingProvider -Name EventLog2 -Enabled $false
Write-PSFMessage -Level Warning -Message "Demo Warning"
Get-WinEvent -FilterHashtable @{
    LogName = 'Windows PowerShell'
    Id = 1001
}

# d) The full layout
#---------------------

code $filesRoot\pssqlite.provider.ps1


 #----------------------------------------------------------------------------# 
 #                In the unlikely event of too much spare time                # 
 #----------------------------------------------------------------------------# 

# 1) Debug v2
function Test-DebugLevel {
    [CmdletBinding()]
    param ()
    Write-PSFMessage -Level Verbose -Message "Message (Verbose)"

    Write-PSFMessage -Level Debug -Message "Message (Debug)"
    Write-PSFMessage -Level Debug -Message "Message (Debug Breakpoint)" -Breakpoint
}
Test-DebugLevel
Test-DebugLevel -Verbose
Test-DebugLevel -Debug


# 2) Tracking Stuff
function Show-Message
{
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        $InputObject,

        [string]
        $Name
    )

    begin {
        Write-PSFMessage -Message "[$Name] Beginning" -Tag Tracking
    }
    process {
        foreach ($item in $InputObject) {
            Write-PSFMessage -Message "[$Name] Processing $item" -Target $item -Tag start, Tracking
            $item
            Write-PSFMessage -Message "[$Name] Finished processing $item" -Target $item -Tag end, Tracking
        }
    }
    end {
        Write-PSFMessage -Message "[$Name] Ending" -Tag Tracking
    }
}
1..3 | 
  Show-Message -Name "First" | 
    Show-Message -Name "Second" |
      Show-Message -Name "Third"

Get-PSFMessage -Tag Tracking
Get-PSFMessage -Target 1 -Tag Tracking

# 3) Integrating from within a Cmdlet
code "$filesRoot\..\csharp\Litter\GetKittenCommand.cs"
Import-Module "$filesRoot\Litter.dll"
Get-Kitten -Kitten 'Mephisto' -Slave 'Warren'
Set-PSFConfig -FullName PSFramework.Localization.Language -Value 'de-DE'
Get-Kitten -Kitten 'Mephisto' -Slave 'Warren'
Set-PSFConfig -FullName PSFramework.Localization.Language -Value 'en-US'

# 4) Module Logging Provider
Invoke-PSMDTemplate -TemplateName PSFLoggingProvider -OutPath 'Demo:\' -Parameters @{
    Name = 'MyModuleProvider'
    Module = 'MyModule'
}
code (Resolve-Path 'demo:\MyModuleProvider.provider.ps1').ProviderPath

# 5) Configuration Reference

# Core Provider Config
Get-PSFConfig LoggingProvider*

# Message System settings
Get-PSFConfig PSFramework.message.*

# Logging Settings
Get-PSFConfig PSFramework.Logging.*
# Settings specific to a provider
Get-PSFConfig PSFramework.Logging.logfile.*

<#
# Core Logging Provider settings                                                       
LoggingProvider.FileSystem.AutoInstall     Whether the logging provider should be installed on registration   
LoggingProvider.FileSystem.Enabled         Whether the logging provider should be enabled on registration     
LoggingProvider.FileSystem.ExcludeModules  Module blacklist. Messages from listed modules will not be logged  
LoggingProvider.FileSystem.ExcludeTags     Tag blacklist. Messages with these tags will not be logged         
LoggingProvider.FileSystem.IncludeModules  Module whitelist. Only messages from listed modules will be logged 
LoggingProvider.FileSystem.IncludeTags     Tag whitelist. Only messages with these tags will be logged        
LoggingProvider.FileSystem.InstallOptional Whether installing the logging provider is mandatory, in order for 
                                           it to be enabled                                                   
LoggingProvider.GELF.AutoInstall           Whether the logging provider should be installed on registration   
LoggingProvider.GELF.Enabled               Whether the logging provider should be enabled on registration     
LoggingProvider.GELF.ExcludeModules        Module blacklist. Messages from listed modules will not be logged  
LoggingProvider.GELF.ExcludeTags           Tag blacklist. Messages with these tags will not be logged         
LoggingProvider.GELF.IncludeModules        Module whitelist. Only messages from listed modules will be logged 
LoggingProvider.GELF.IncludeTags           Tag whitelist. Only messages with these tags will be logged        
LoggingProvider.GELF.InstallOptional       Whether installing the logging provider is mandatory, in order for 
                                           it to be enabled                                                   
LoggingProvider.LogFile.AutoInstall        Whether the logging provider should be installed on registration   
LoggingProvider.LogFile.Enabled            Whether the logging provider should be enabled on registration     
LoggingProvider.LogFile.ExcludeModules     Module blacklist. Messages from listed modules will not be logged  
LoggingProvider.LogFile.ExcludeTags        Tag blacklist. Messages with these tags will not be logged         
LoggingProvider.LogFile.IncludeModules     Module whitelist. Only messages from listed modules will be logged 
LoggingProvider.LogFile.IncludeTags        Tag whitelist. Only messages with these tags will be logged        
LoggingProvider.LogFile.InstallOptional    Whether installing the logging provider is mandatory, in order for 
                                           it to be enabled

# Message System Settings:                                                     
PSFramework.message.consoleoutput.disable    Global toggle that allows disabling all regular messages to      
                                             screen. Messages from '-Verbose' and '-Debug' are unaffected     
PSFramework.message.debug.maximum            The maximum message level where debug information is still       
                                             written.                                                         
PSFramework.message.debug.minimum            The minimum required message level where debug information is    
                                             written.                                                         
PSFramework.message.developercolor           The color to use when writing text with developer specific       
                                             additional information to the screen on PowerShell.              
PSFramework.message.info.color               The color to use when writing text to the screen on PowerShell.  
PSFramework.message.info.color.emphasis      The color to use when emphasizing written text to the screen on  
                                             PowerShell.                                                      
PSFramework.message.info.color.subtle        The color to use when making writing text to the screen on       
                                             PowerShell appear subtle.                                        
PSFramework.message.info.maximum             The maximum message level to still display to the user directly. 
PSFramework.message.info.minimum             The minimum required message level for messages that will be     
                                             shown to the user.                                               
PSFramework.message.nestedlevel.decrement    How many levels should be reduced per callstack depth. This      
                                             makes commands less verbose, the more nested they are called     
PSFramework.message.style.breadcrumbs        Controls how messages are displayed. Enables Breadcrumb display, 
                                             showing the entire callstack. Takes precedence over command name 
                                             display.                                                         
PSFramework.message.style.functionname       Controls how messages are displayed. Enables command name,       
                                             showing the name of the writing command. Is overwritten by       
                                             enabling breadcrumbs.                                            
PSFramework.message.style.timestamp          Controls how messages are displayed. Enables timestamp display,  
                                             including a timestamp in each message.                           
PSFramework.message.transform.errorqueuesize The size of the queue for transformation errors. May be useful   
                                             for advanced development, but can be ignored usually.            
PSFramework.message.verbose.maximum          The maximum message level where verbose information is still     
                                             written.                                                         
PSFramework.message.verbose.minimum          The minimum required message level where verbose information is  
                                             written.

# Logging Settings                                             
PSFramework.Logging.DisableLogFlush                  When shutting down the process, PSFramework will by      
                                                     default flush the log. This ensures that all events are  
                                                     properly logged. If this is not desired, it can be       
                                                     turned off with this setting.                            
PSFramework.Logging.ErrorLogEnabled                  Governs, whether a log of recent errors is kept in       
                                                     memory. This setting is on a per-Process basis.          
                                                     Runspaces share, jobs or other consoles counted          
                                                     separately.                                              
PSFramework.Logging.FileSystem.ErrorLogFileEnabled   Governs, whether log files for errors are written. This  
                                                     setting is on a per-Process basis. Runspaces share, jobs 
                                                     or other consoles counted separately.                    
PSFramework.Logging.FileSystem.LogPath               The path where the PSFramework writes all its logs and   
                                                     debugging information.                                   
PSFramework.Logging.FileSystem.MaxErrorFileBytes     The maximum size all error files combined may have. When 
                                                     this number is exceeded, the oldest entry is culled.     
                                                     This setting is on a per-Process basis. Runspaces share, 
                                                     jobs or other consoles counted separately.               
PSFramework.Logging.FileSystem.MaxLogFileAge         Any logfile older than this will automatically be        
                                                     cleansed. This setting is global.                        
PSFramework.Logging.FileSystem.MaxMessagefileBytes   The maximum size of a given logfile. When reaching this  
                                                     limit, the file will be abandoned and a new log created. 
                                                     Set to 0 to not limit the size. This setting is on a     
                                                     per-Process basis. Runspaces share, jobs or other        
                                                     consoles counted separately.                             
PSFramework.Logging.FileSystem.MaxMessagefileCount   The maximum number of logfiles maintained at a time.     
                                                     Exceeding this number will cause the oldest to be        
                                                     culled. Set to 0 to disable the limit. This setting is   
                                                     on a per-Process basis. Runspaces share, jobs or other   
                                                     consoles counted separately.                             
PSFramework.Logging.FileSystem.MaxTotalFolderSize    This is the upper limit of length all items in the log   
                                                     folder may have combined across all processes.           
PSFramework.Logging.FileSystem.MessageLogFileEnabled Governs, whether a log file for the system messages is   
                                                     written. This setting is on a per-Process basis.         
                                                     Runspaces share, jobs or other consoles counted          
                                                     separately.                                              
PSFramework.Logging.FileSystem.ModernLog             Enables the modern, more powereful version of the        
                                                     filesystem log, including headers and extra columns      
PSFramework.Logging.GELF.Encrypt                     Whether to use TLS encryption when communicating with    
                                                     the GELF server                                          
PSFramework.Logging.GELF.GelfServer                  The GELF server to send logs to                          
PSFramework.Logging.GELF.Port                        The port number the GELF server listens on               
PSFramework.Logging.LogFile.CsvDelimiter             The delimiter to use when writing to csv.                
PSFramework.Logging.LogFile.FilePath                 The path to where the logfile is written. Supports some  
                                                     placeholders such as %Date% to allow for timestamp in    
                                                     the name. For full documentation on the supported        
                                                     wildcards, see the documentation on                      
                                                     https://psframework.org                                  
PSFramework.Logging.LogFile.FileType                 In what format to write the logfile. Supported styles:   
                                                     CSV, XML, Html or Json. Html, XML and Json will be       
                                                     written as fragments.                                    
PSFramework.Logging.LogFile.Headers                  The properties to export, in the order to select them.   
PSFramework.Logging.LogFile.IncludeHeader            Whether a written csv file will include headers          
PSFramework.Logging.LogFile.Logname                  A special string you can use as a placeholder in the     
                                                     logfile path (by using '%logname%' as placeholder)       
PSFramework.Logging.MaxErrorCount                    The maximum number of error records maintained           
                                                     in-memory. This setting is on a per-Process basis.       
                                                     Runspaces share, jobs or other consoles counted          
                                                     separately.                                              
PSFramework.Logging.MaxMessageCount                  The maximum number of messages that can be maintained in 
                                                     the in-memory message queue. This setting is on a        
                                                     per-Process basis. Runspaces share, jobs or other        
                                                     consoles counted separately.                             
PSFramework.Logging.MessageLogEnabled                Governs, whether a log of recent messages is kept in     
                                                     memory. This setting is on a per-Process basis.          
                                                     Runspaces share, jobs or other consoles counted          
                                                     separately.
#>