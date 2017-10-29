xquery version "3.1";

(:  create data.tsv :)
import module namespace config="https://lasy.net/feinstaubsensor/config" at " /db/apps/feinstaub//modules/config.xqm";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

let $samples := collection($config:app-root || "/data/sensor/3389190/")//sample
let $sample-data :=  for $sample in $samples 
                        order by $sample/@timestamp 
                        let $timestamp := replace($sample/@timestamp, " ", "T")
                        return
                            if(string-length($sample//temperature/text()) > 0)
                            then (
                            ('{&quot;date&quot;:&quot;' || $timestamp || '&quot;,&quot;temp&quot;:'||  $sample//temperature/text() || '}' )
                            ) else ()

let $json-data := '{"Temperature": [' || string-join($sample-data, ",") || ']}'
let $store-temp-json-data := xmldb:store($config:app-root, "data-temp.json", $json-data, "application/json")          
return
    $json-data