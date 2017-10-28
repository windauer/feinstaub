xquery version "3.1";

import module namespace config="https://lasy.net/feinstaubsensor/config" at " /db/apps/feinstaub//modules/config.xqm";
import module namespace http = "http://expath.org/ns/http-client";
import module namespace xqjson="http://xqilla.sourceforge.net/lib/xqjson";

declare variable $local:sensor-ids := ("2521");


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
    return 
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


        let $store-data := xmldb:store($config:app-root || "/data/xml", $sensor-id || "-" || $entry?id || ".xml", $sample) 
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

(:  let $login := xmldb:login("/", $config:user,$config:pwd) :) 

local:update-sensor-data()
