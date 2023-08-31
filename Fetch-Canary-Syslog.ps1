$ConfigFile = '.\Fetch-Canary-Syslog-Config.xml'
$ConfigParams = [xml](get-content $ConfigFile)

# Initialize configuration variables from config xml file
$WorkerURL = $ConfigParams.configuration.cloudflare.URL.value
$WorkerAuth = $ConfigParams.configuration.cloudflare.auth.value
$SyslogTarget = $ConfigParams.configuration.syslog.fqdn.value
$SyslogPort = $ConfigParams.configuration.syslog.port.value
$OutputFile = $ConfigParams.configuration.file.canarylogs.value

$Response = $WorkerURL -Headers @{ 'auth' = $WorkerAuth}
$UdpClient = New-Object System.Net.Sockets.UdpClient $SyslogTarget, $SyslogPort

if($Response.Statuscode -eq 204){exit 0} # Nothing to process - resultset is empty

$Content = $Response.RawContent
$SyslogArray = ($Content -split "\r?\n|\r")
ForEach ($SyslogEntry in $SyslogArray){
    # Convert message to array of ASCII bytes.
    $bytearray = $([System.Text.Encoding]::ASCII).getbytes($SyslogEntry)
    
    # Send the Syslog message...
    if ($SyslogTarget -ne "syslog.hostname.here") {
        $UdpClient.Send($bytearray, $bytearray.length) | out-null
    }
    else {
        $SyslogEntry >> $OutputFile
    }
}