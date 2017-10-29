xquery version "3.1";

import module namespace config="https://lasy.net/feinstaubsensor/config" at " /db/apps/feinstaub//modules/config.xqm";
import module namespace http = "http://expath.org/ns/http-client";

declare variable $local:sensor-ids := ("2125","2126");


declare function local:update-sensor-data() {
    for $sensor-id in $local:sensor-ids
        return
            local:load-and-store-sensor-data($sensor-id)
};

(:~
 : Download sensor data for the provided id and store it as json and xml
~:)
declare function local:load-and-store-sensor-data($sensor-id) {
    (: prepare http request :)
    let $url := "http://api.luftdaten.info/static/v1/sensor/" || $sensor-id || "/"
    let $req := <http:request href="{$url}" method="get"/>
    (: send http request and store result :)
    let $http-response := http:send-request($req)
    let $load-new-data :=  
        if ($http-response[1]/@status = "200") then (
            (: parse json :)
            let $json := parse-json(util:binary-to-string($http-response[2]))
            (: prepare filename :)
            let $timestamp := replace(substring(string(fn:current-dateTime()),1,19),":","-")
            let $filename := "sensor-" || $sensor-id || "-" || $timestamp 
            (: store data as json :)
            let $store-data := xmldb:store($config:app-root || "/data/json", $filename || ".json", $http-response[2], "application/json" ) 
            (: transform json into own xml structure :)
            let $xml := local:json-to-xml($filename, $sensor-id, $json)
            return
                $xml
        ) else ()
    return
        if($load-new-data)
            then (local:reformat-xml-data())
            else ("error")
};

declare function local:json-to-xml($filename, $sensor-id, $json){
    for $entry in $json?*
        let $sample := element sample {
                        attribute id { $entry?id},
                        attribute sensor-id { $sensor-id},
                        attribute timestamp { $entry?timestamp},
                        local:parse-sensor-location($entry?location),   
                        local:parse-sensor($entry?sensor),
                        local:parse-sensor-data($entry?sensordatavalues)
                    }


        let $store-data := xmldb:store($config:app-root || "/data/xml", $entry?id || "-" || $sensor-id || ".xml", $sample) 
        return
            $sample
    
};

declare function local:parse-sensor-location($location){
    element location {
        attribute id {$location?id},
        attribute latitude {$location?latitude},
        attribute longitude {$location?longitude},
        attribute country {$location?country}
    }
};

declare function local:parse-sensor($sensor){
    element sensor {
        attribute id {$sensor?id},
        attribute pin {$sensor?pin},
        local:parse-sensor-type($sensor?sensor_type)
    }
};

declare function local:parse-sensor-type($type){
    element type {
        attribute id {$type?id},
        attribute name {$type?name},
        attribute manufacturer {$type?manufacturer}
    }
};

declare function local:parse-sensor-data($sensor-data){
    for $data in $sensor-data?*
        return 
            element {$data?value_type} {
                attribute id {$data?id},
                $data?value
            }
};

declare function local:reformat-xml-data() {
  let $raw-samples := collection($config:app-root || "/data/xml")//sample
  for $timestamp in distinct-values($raw-samples/@timestamp)          
            let $samples := $raw-samples[@timestamp = $timestamp]
            let $sensor-id := $samples[1]/@sensor-id/string()
            let $timestamp := $samples[1]/@timestamp/string()
            let $location-id := $samples[1]/location/@id/string()
            let $location-lat := $samples[1]/location/@latitude/string()
            let $location-long := $samples[1]/location/@longitude/string()
            let $location-country := $samples[1]/location/@country/string()
            
            let $aggregated-sample := 
                <sample timestamp="{$timestamp}" 
                        location-id="{$location-id}" latitude="{$location-lat}" 
                        longitude="{$location-long}" country="{$location-country}">
                        
                    <sensor id="{$samples[1]/sensor/@id/string()}" 
                            sample-id="{$samples[1]/@id/string()}" 
                            pin="{$samples[1]/sensor/@pin/string()}">
                        {   
                            $samples[1]/sensor/type, 
                            $samples[1]/P1,
                            $samples[1]/P2,
                            $samples[1]/temperature,
                            $samples[1]/humidity
                        }
                    </sensor>
                    <sensor id="{$samples[2]/sensor/@id/string()}" 
                            sample-id="{$samples[2]/@id/string()}" 
                            pin="{$samples[2]/sensor/@pin/string()}">
                        {   
                            $samples[2]/sensor/type, 
                            $samples[2]/P1,
                            $samples[2]/P2,
                            $samples[2]/temperature,
                            $samples[2]/humidity
                        }
                    </sensor>                            
                </sample>

            let $ts-1 := replace($aggregated-sample/@timestamp," ", "-")
            let $ts-2 := replace($ts-1, ":", "-")
            let $filename := "sample-" || $ts-2 || ".xml"
            let $store-sample := xmldb:store($config:app-root || "/data/sensor/3389190/", $filename , $aggregated-sample) 
            return
                $aggregated-sample      
        
};

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

declare function local:generate-json(){
    let $samples := collection($config:app-root || "/data/sensor/3389190/")//sample
    let $categories := ("Temperature", "Humidity", "P1", "P2")
    return
        for $category in $categories 
            return 
                local:xml-to-json($category, $samples)
};

let $login := xmldb:login("/", "admin","" ) 
let $log := util:log("info", "pulling Feinstaub data")
return
    local:update-sensor-data(),
    local:generate-json()
