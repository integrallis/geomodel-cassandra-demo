console.log "Geocoded to LAT <%= @latitude %>, LON <%= @longitude %>"
$.SchoolMap.centerMap(<%= @latitude %>, <%= @longitude %>)
$.SchoolMap.addMarkers(<%= raw @markers.to_json %>)
$.SchoolMap.zoom(12)
$('#alerts').html("<%=j render 'search_alert', schools: @schools %>")
