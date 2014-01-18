class SchoolMap
  constructor: ->    
    # ------------------------------------------------------
    # on document ready
    # ------------------------------------------------------
    $(document).ready => @initialize()

  initialize: ->
    @placedMarkers = []
    schoolMap = @
    # Build the Google Map
    @handler = Gmaps.build("Google")
    @map = @handler.buildMap
      provider: { 
        zoom: 8 
        disableDoubleClickZoom: true
        scrollwheel: false
      },
      internal: {
        id: "map"
      }, ->
        google.maps.event.addListener schoolMap.handler.getMap(), 'dblclick', (e) -> doubleClickHandler(e)
        #google.maps.event.addListener schoolMap.handler.getMap(), 'bounds_changed', -> boundsChangedHandler(schoolMap.handler)
        
    @centerMap(40.676828, -101.539688) # center on Merka!
    @handler.getMap().setZoom(5)
    @handler.fitMapToBounds()
      
  centerMap: (lat, lon) ->
    @map.centerOn({ lat: lat, lng: lon })
     
  addMarkers: (markers) ->
    # grab all the school ids (I stored them in the marker_title)  
    marker_ids = _.map(markers, (marker) -> marker.marker_title)
    # calculate the ones that are not on the map already
    ids_not_placed = _.difference(marker_ids, @placedMarkers)
    # update the markers
    @placedMarkers = @placedMarkers.concat(ids_not_placed)
    # filter the markers to be placed
    to_be_placed = (marker for marker in markers when marker.marker_title in ids_not_placed)

    @handler.addMarkers(to_be_placed)
    
  zoom: (level) ->
    @handler.getMap().setZoom(level)
    
  doubleClickHandler = (e) ->
    $.get "/schools/search.js", { latitude: e.latLng.lat(), longitude: e.latLng.lng() }
    
  boundsChangedHandler = (handler) ->
    SW = handler.getMap().getBounds().getSouthWest()
    NE = handler.getMap().getBounds().getNorthEast()
    NW = new google.maps.LatLng(NE.lat(),SW.lng())
    latHeight = google.maps.geometry.spherical.computeDistanceBetween(SW, NW)
    lonWidth = google.maps.geometry.spherical.computeDistanceBetween(NE, NW)
    console.log("BOUNDS CHANGED: latHeight ==> #{latHeight}, lonWidth ==> #{lonWidth}")
      
$.SchoolMap = new SchoolMap
      
      