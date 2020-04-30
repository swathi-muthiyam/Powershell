#### DB connection string details     
$ServerInstance = "[DB server Instance]"
$Database = "[Database Name]"
$Userid = "[User Id]"
$Password = "[Password]"
# Enter Blob Container Name
$container_name = '[BLOB Container Name]'
# Enter BLOB connection string
$BLOBconnection_string = "[BLOB connection String]"

 

$ConnectionTimeout = 30
$QueryTimeout = 120

 

#### Place required script to run .
$Query = "select * from Tablefile ta JOIN TableVersion tav on ta.AttachmentId = tav.AttachmentId
where ta.filefroupid = '" + $container_name.ToLower() + "' and ta.isdeleted = 0"

 #### Logging , This line of code should be before using the method.
Function LogWrite
{
   Param ([string]$logstring)
   Add-content $Logfile -value $logstring
}

 


#### File creation variables, Make sure to have below mentioned path in local machine.
$folderLocation = 'C:\FILES\'
$filename = Get-Date -Format "MMddyyyyHHmmss"
$Logfile = "C:\FILES\"+ $filename + ".log"

 #### BLOB cnnection string conect to BLOB storage 
$storage_account = New-AzStorageContext -ConnectionString $BLOBconnection_string

 

$conn=new-object System.Data.SqlClient.SQLConnection
$ConnectionString = "Server = $ServerInstance; Database = $Database; User ID = $Userid; Password = $Password;"
####$ConnectionString = "Server={0};Database={1};Integrated Security=True;Connect Timeout={2}" -f $ServerInstance,$Database,$ConnectionTimeout
$conn.ConnectionString=$ConnectionString
$conn.Open()
$cmd=new-object system.Data.SqlClient.SqlCommand($Query,$conn)
$cmd.CommandTimeout=$QueryTimeout
$ds=New-Object system.Data.DataSet
$da=New-Object system.Data.SqlClient.SqlDataAdapter($cmd)
[void]$da.fill($ds)
$conn.Close()
$ds.Tables
#### Get single table from dataset
$data = $ds.Tables[0]

 

foreach($row in $data)
{
IF([string]::IsNullOrEmpty($row.BlobUri)) {
     LogWrite("BLOBURI is empty in DB :  "+ $row.BlobUri)
}
else {
#### Downloads the BLOBuri received in the container and renames the file to actaul name with extension.
       Get-AzStorageBlobContent `
        -Container $container_name.ToLower() -Blob $row.BLOBUri -Destination $folderLocation `
        -Context $storage_account

 

        LogWrite($row.BLOBUri + " downloaded...!")

 

    $fullFileName = $folderLocation

 

    $BlobFile = $fullFileName + $row.BLOBUri
    $ActualFile =  $fullFileName + $row.Name
    Rename-Item $BlobFile $ActualFile
    LogWrite($row.BLOBUri + " renamed to " + $row.Name)
 }

 

}