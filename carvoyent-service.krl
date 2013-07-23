ruleset carvoyent_service {

  meta {
    name "Carvoyent service"
    description <<
Uses Carvoyent API to retrieve and store data about my vehicle at regular intervals
    >>
    author "Phil Windley"
    logging on

    use module a169x701 alias CloudRain

  }

  global {

    API_key = "04b4df2e-04f3-4c11-b0be-796a05896ae1";
    carvoyent_secret = "13319e3b-c2be-4d24-aee5-9b2b9e6af6e7";
    my_vehicle_id = "C201200099";

    carvoyent_url = function(vehicle_id) {
       // api_base_url = "http://httpbin.org/basic-auth/user/passwd";
       // api_base_url
      api_base_url = "https://dash.carvoyant.com/api/vehicle/";
      api_base_url + vehicle_id;      
    }

    get_vehicle_data = function() {
      http:get(carvoyent_url(my_vehicle_id),
               {"credentials":  {"username": API_key,
	               		 "password": carvoyent_secret,
				 "realm": "Carvoyant API",
                      		 "netloc": "dash.carvoyant.com:443"
                      		},
		 "params":{}
		}
	       );
               
    }
    
  }

  rule show_carvoyent_data {
    select when web cloudAppSelected

    pre {

      vinfo = get_vehicle_data().pick("$.content").decode();
      running = vinfo.pick("$..running") => "Running" | "Off";
      lat = vinfo.pick("$..latitude");
      long = vinfo.pick("$..longitude");

      my_html = <<
<div style="margin: 0px 0px 20px 20px">
Name: #{vinfo.pick("$..name")}<br/>
Mileage: #{vinfo.pick("$..mileage")}<br/>
Status: #{running} at #{vinfo.pick("$..lastRunningTimestamp")}<br/>
<iframe width="425" height="350" frameborder="0" scrolling="no" marginheight="0" marginwidth="0" src="https://maps.google.com/maps?f=q&amp;source=s_q&amp;hl=en&amp;geocode=&amp;q=${lat},#{long}&amp;aq=&amp;sll=#{lat-1},#{long-.4}&amp;sspn=10.363221,9.788818&amp;ie=UTF8&amp;t=m&amp;z=14&amp;ll=#{lat},#{long}&amp;output=embed"></iframe><br /><small><a href="https://maps.google.com/maps?f=q&amp;source=embed&amp;hl=en&amp;geocode=&amp;q=#{lat},#{long}&amp;aq=&amp;sll=#{lat-1},#{long-0.4}&amp;sspn=10.363221,9.788818&amp;ie=UTF8&amp;t=m&amp;z=14&amp;ll=#{lat},#{long}" style="color:#0000FF;text-align:left">View Larger Map</a></small>
</div>
>>;
    }
    {
      CloudRain:createLoadPanel("Carvoyent Test", {}, my_html);
    }
  }
 
}