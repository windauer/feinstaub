xquery version "3.1";

(:  create data.tsv :)
import module namespace config="https://lasy.net/feinstaubsensor/config" at " /db/apps/feinstaub//modules/config.xqm";

let $samples := collection($config:app-root || "/data/sensor/3389190/")//sample
let $tsv-data := ("Date  Temperature",
                    for $sample in $samples 
                        order by $sample/@timestamp 
                        return
                            ($sample/@timestamp/string() || "    " ||  $sample//temperature/text() )
                )
let $store-temp-tsv-data := xmldb:store($config:app-root, "data-temp.tsv", string-join($tsv-data,"\n"), "text/csv")                
return
    $tsv-data