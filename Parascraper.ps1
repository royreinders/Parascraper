$json = Invoke-WebRequest -Uri "https://www.pararius.nl/library/app_getListHouses.php?lang=nl&cmd=1&version=1.1&cityname=Utrecht&range=5&delivery=3&nrBedrooms=3&m2=10&minPrice=0&maxPrice=1750&pageSize=100000&pageNr=1" | ConvertFrom-Json
[System.Collections.ArrayList]$NewHouses = @()
[System.Collections.ArrayList]$Links = @()

#MySQL Insert code

$MySQLHost = "MOCK"
$database = "MOCK"
$user = "MOCK"
$pass = "MOCK"

[void][system.reflection.Assembly]::LoadWithPartialName("MySql.Data") 
 
# Open Connection 
$connStr = "server=" + $MySQLHost + ";port=3306;uid=" + $user + ";pwd=" + $pass + ";database="+$database+";Pooling=FALSE" 
$conn = New-Object MySql.Data.MySqlClient.MySqlConnection($connStr) 
$conn.Open()

Foreach($house in $json.listings){
    $HouseIDExists = $house.id
    $query = "SELECT count(*) FROM houses WHERE houseID = $HouseIDExists"

    $command = $conn.CreateCommand()                  # Create command object
    $command.CommandText = $query                     # Load query into object
    $numrows = $command.ExecuteScalar()        # Execute command

    if($numrows -eq "0"){
        $NewHouses.Add($house)
    }
}


Foreach($house in $NewHouses){
    $HouseID = $house.id
    $price = $house.price
    $m2 = $house.m2
    $new = "1"
    $time = Get-Date

    $query = "INSERT INTO houses (houseID, price, m2, new, time) VALUES ('$HouseID', '$price', '$m2', '$new', '$time')" 

    $command = $conn.CreateCommand()                  # Create command object
    $command.CommandText = $query                     # Load query into object
    $RowsInserted = $command.ExecuteNonQuery()        # Execute command

    $housejson = Invoke-WebRequest -Uri "https://www.pararius.nl/library/app_getHouseDetails.php?id=$HouseID" | ConvertFrom-Json
    $Links.Add($housejson.listingUrl)
    
    
}

$command.Dispose()                                # Dispose of command object

$conn.Close()

$newcount = $NewHouses.Count

#Send mail
if($newcount -gt 0){

    $From = "MOCK"
    $To = "MOCK"
    $SMTPServer = "MOCK"
    $SMTPPort = "MOCK"
    $Username = "MOCK"
    $Password = "MOCK"
    $body = "$newcount new listing(s) found. Check the following links:"
    foreach($Link in $Links){
        $body = "$body `n https://pararius.nl/$Link"
    }
    
    $subject = "New pararius listings found"

    $smtp = New-Object System.Net.Mail.SmtpClient($SMTPServer, $SMTPPort);

    $smtp.EnableSSL = $true
    $smtp.Credentials = New-Object System.Net.NetworkCredential($Username, $Password);
    $smtp.Send($From, $To, $subject, $body);
}



