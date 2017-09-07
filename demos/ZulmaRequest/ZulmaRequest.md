# Lat/lon queries
OJ Watson  
`r format(Sys.time(), '%d %B, %Y')`  

## Overview
  
1. Intro
2. LatLon Examples
3. Extra

## 1. Intro

The following shows a simple way to fetch latitude/longitude coordinates for a street
address or similar using [ggmap](https://github.com/dkahle/ggmap). This package 
simply uses Google's geocoding API and thus will cap out at 2500 queries per day. 
Might be a way to spoof Google API to get round this but I haven't tried before. 

## 2. LatLon Examples

Following simply shows how to use it. 


```r
install.packages("ggmap",repos = "https://cloud.r-project.org/")
```

```
## package 'ggmap' successfully unpacked and MD5 sums checked
## 
## The downloaded binary packages are in
## 	C:\Users\Oliver\AppData\Local\Temp\RtmpI5XmgW\downloaded_packages
```

```r
## Then let's build a function to query google for the lat long of our location
latlon_list <- function(location){   
  
  # use the gecode function to query google servers
  geo_reply = ggmap::geocode(location, output='latlon', messaging=FALSE, override_limit=TRUE)
  
  return(list("lat"=geo_reply$lat,"lon"=geo_reply$lon))
}

## Example address
location <- "Cra. 27 #7-48, Bogotá, Colombia"

## Example use
latlon_list(location)
```

```
## $lat
## [1] 7.130543
## 
## $lon
## [1] -73.11965
```

## 3. Extra

Can also get more information about the address by changing the ouput argument
to "all".


```r
str(ggmap::geocode(location, output='all', messaging=FALSE, override_limit=TRUE))
```

```
## List of 2
##  $ results:List of 1
##   ..$ :List of 5
##   .. ..$ address_components:List of 7
##   .. .. ..$ :List of 3
##   .. .. .. ..$ long_name : chr "19-10"
##   .. .. .. ..$ short_name: chr "19-10"
##   .. .. .. ..$ types     : chr "street_number"
##   .. .. ..$ :List of 3
##   .. .. .. ..$ long_name : chr "Carrera 27"
##   .. .. .. ..$ short_name: chr "Cra. 27"
##   .. .. .. ..$ types     : chr "route"
##   .. .. ..$ :List of 3
##   .. .. .. ..$ long_name : chr "San Alonso"
##   .. .. .. ..$ short_name: chr "San Alonso"
##   .. .. .. ..$ types     : chr [1:2] "neighborhood" "political"
##   .. .. ..$ :List of 3
##   .. .. .. ..$ long_name : chr "Bucaramanga"
##   .. .. .. ..$ short_name: chr "Bucaramanga"
##   .. .. .. ..$ types     : chr [1:2] "administrative_area_level_2" "political"
##   .. .. ..$ :List of 3
##   .. .. .. ..$ long_name : chr "Santander"
##   .. .. .. ..$ short_name: chr "Santander"
##   .. .. .. ..$ types     : chr [1:2] "administrative_area_level_1" "political"
##   .. .. ..$ :List of 3
##   .. .. .. ..$ long_name : chr "Colombia"
##   .. .. .. ..$ short_name: chr "CO"
##   .. .. .. ..$ types     : chr [1:2] "country" "political"
##   .. .. ..$ :List of 3
##   .. .. .. ..$ long_name : chr "680002"
##   .. .. .. ..$ short_name: chr "680002"
##   .. .. .. ..$ types     : chr "postal_code"
##   .. ..$ formatted_address : chr "Cra. 27 #19-10, Bucaramanga, Santander, Colombia"
##   .. ..$ geometry          :List of 3
##   .. .. ..$ location     :List of 2
##   .. .. .. ..$ lat: num 7.13
##   .. .. .. ..$ lng: num -73.1
##   .. .. ..$ location_type: chr "ROOFTOP"
##   .. .. ..$ viewport     :List of 2
##   .. .. .. ..$ northeast:List of 2
##   .. .. .. .. ..$ lat: num 7.13
##   .. .. .. .. ..$ lng: num -73.1
##   .. .. .. ..$ southwest:List of 2
##   .. .. .. .. ..$ lat: num 7.13
##   .. .. .. .. ..$ lng: num -73.1
##   .. ..$ place_id          : chr "ChIJocysm2UVaI4RLY9Y7tTVcV8"
##   .. ..$ types             : chr [1:4] "bank" "establishment" "finance" "point_of_interest"
##  $ status : chr "OK"
```
