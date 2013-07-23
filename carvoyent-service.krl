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
      api_base_url = "http://requestb.in/13asei71";
      api_base_url
       // api_base_url = "https://dash.carvoyant.com/api/vehicle/";
       // api_base_url + vehicle_id;      
    }

    get_vehicle_data = function() {
      http:get(carvoyent_url(my_vehicle_id),
               {"credentials":  {"username": API_key,
	               		 "password": carvoyent_secret,
		       		 "realm": "/",
                       		 "netloc": "requestb.in:80"
		       		  // "realm": "Carvoyant API",
                       		  // "netloc": "dash.carvoyent.com:80"
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

      my_html = <<
<div style="margin: 0px 0px 20px 20px">
Name: #{vinfo.pick("$..name")}<br/>
Mileage: #{vinfo.pick("$..mileage")}<br/>
</div>
>>;
    }
    {
      CloudRain:createLoadPanel("Carvoyent Test", {}, my_html);
    }
  }
 
}