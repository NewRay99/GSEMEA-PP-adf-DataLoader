$json = Get-Content -Raw './kv.json';

$jsonparsed = convertFrom-Json $json -ErrorAction Stop;

ForEach ($p in $jsonparsed.psobject.properties.name) {
    Write-Host '***********'
    Write-Host 'key' $p
    Write-Host 'type' $jsonparsed.$p.type
    Write-Host 'value' $jsonparsed.$p.Env.'dev'

}