xquery version "3.1";

(:  create data.tsv :)
import module namespace config="https://lasy.net/feinstaubsensor/config" at " /db/apps/feinstaub//modules/config.xqm";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

declare function local:xml-to-json($category, $samples){
    let $json-sample-data := for $sample in $samples 
                        order by $sample/@timestamp 
                        let $timestamp := replace($sample/@timestamp, " ", "T")
                        return
                            
                                if($category = "Temperature" and string-length($sample//temperature/text()) > 0)
                                then (
                    ('{&quot;date&quot;:&quot;' || $timestamp || '&quot;,&quot;temp&quot;:'||  $sample//temperature/text() || '}' )
                                ) 
                                
                                else if($category = "Humidity" and string-length($sample//humidity/text()) > 0)
                                  then (
                    ('{&quot;date&quot;:&quot;' || $timestamp || '&quot;,&quot;temp&quot;:'||  $sample//humidity/text() || '}' )    
                                ) 
                                
                                else if($category = "P1" and string-length($sample//P1/text()) > 0) 
                                then (
                    ('{&quot;date&quot;:&quot;' || $timestamp || '&quot;,&quot;temp&quot;:'||  $sample//P1/text() || '}' )
                                ) 
                                
                                else if($category = "P2" and string-length($sample//P2/text()) > 0)  
                                then (
                    ('{&quot;date&quot;:&quot;' || $timestamp || '&quot;,&quot;temp&quot;:'||  $sample//P2/text() || '}' )
                                )
                                
                                else ()
                            
                            
    let $json-data := '{"' || $category || '": [' || string-join($json-sample-data, ",") || ']}'            
    let $store-temp-json-data := xmldb:store($config:app-root || "/data/", "data-"|| $category || ".json", $json-data, "application/json")          
    return 
        $json-data
};

let $samples := collection($config:app-root || "/data/sensor/3389190/")//sample
let $categories := ("Temperature", "Humidity", "P1", "P2")
return
    for $category in $categories 
        return 
            local:xml-to-json($category, $samples)
    