ruleset carvoyent_service {

  meta {
    name "Carvoyant Service"
    description <<
Uses Carvoyant API to retrieve and store data about my vehicle at regular intervals
    >>
    author "Phil Windley"
    logging on

    use module a169x676 alias pds
    use module a169x701 alias CloudRain

  }

  global {

    get_config_value = function (name) {
      pds:get_setting_data_value(meta:rid(), name);
    };

    carvoyent_url = function(vehicle_id) {
      api_base_url = "https://dash.carvoyant.com/api"+"/vehicle/";
      api_base_url + vehicle_id;      
    }

    get_vehicle_data = function() {
      http:get(carvoyent_url(get_config_value("vehicle_id")),
               {"credentials":  {"username": get_config_value("api_key"),
	               		 "password": get_config_value("api_secret"),
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

       // vinfo = get_vehicle_data().pick("$.content").decode();
       // running = vinfo.pick("$..running") => "Running" | "Off";
       // lat = vinfo.pick("$..latitude");
       // long = vinfo.pick("$..longitude");

      vehicle_data = pds:get_items(get_config_value("vehicle_id"));

      mileage = vehicle_data{'mileage'};
      name = vehicle_data{'name'};
      timestamp = vehicle_data{'now'};
      lastRunningTimestamp = vehicle_data{'lastRunningTimestamp'};
      status = vehicle_data{'status'};
      lat = vehicle_data{'latitude'};
      long = vehicle_data{'longitude'};

      my_html = <<
<div style="margin: 0px 0px 20px 20px">
Mileage:  #{mileage}<br/>
Status: #{status} at #{lastRunningTimestamp}<br/>
<p style="margin-top:10px"><iframe width="425" height="350" frameborder="0" scrolling="no" marginheight="0" marginwidth="0" src="https://maps.google.com/maps?f=q&amp;source=s_q&amp;hl=en&amp;geocode=&amp;q=#{lat},#{long}&amp;aq=&amp;sll=#{lat-1},#{long-.4}&amp;sspn=10.363221,9.788818&amp;ie=UTF8&amp;t=m&amp;z=14&amp;ll=#{lat},#{long}&amp;output=embed"></iframe><br/><small><a href="https://maps.google.com/maps?f=q&amp;source=embed&amp;hl=en&amp;geocode=&amp;q=#{lat},#{long}&amp;aq=&amp;sll=#{lat-1},#{long-0.4}&amp;sspn=10.363221,9.788818&amp;ie=UTF8&amp;t=m&amp;z=14&amp;ll=#{lat},#{long}" target="_blank" style="color:#0000FF;text-align:left">View Larger Map</a></small></p>
Last check: #{timestamp}
</div>
>>;
    }
    {
      CloudRain:createLoadPanel("Vehicle Data for #{name}", {}, my_html);
    }
  }

  // --------------------------------------- scheduling --------------------------------------------
  rule set_schedule {
    select when web sessionLoaded
    noop();
    always {
      schedule explicit event check_vehicle repeat "0-23/6 * * * *" // every six hours
    }
  }

 
 rule check_vehicle {
   select when explicit check_vehicle
    pre {

      vinfo = get_vehicle_data().pick("$.content").decode();
      name = vinfo.pick("$..name");
      mileage = vinfo.pick("$..mileage");
   }
   always {
     raise pds event new_map_available with
          namespace = get_config_value("vehicle_id") and
          mapvalues = {
            "mileage" : 
            "name": name,
	    "status" : vinfo.pick("$..running") => "Running" | "Off",
	    "latitude" :  vinfo.pick("$..latitude"),
            "longitude" : vinfo.pick("$..longitude"),
            "lastRunningTimestamp" : vinfo.pick("$..lastRunningTimestamp"),
            "now" : time:now()
          };
      raise notification event status
          with application = "Carvoyent Vehicle Data"
           and subject = "Daily Report on #{name}"
           and description = "A new vehicle status report is available. Current mileage is #{mileage} miles."
           and priority = 1;
   }
 }

  // ----------------------------------- configuration setup ---------------------------------------
  rule load_app_config_settings {
    select when web sessionLoaded
    pre {
      schema = [
        {
          "name"     : "api_key",
          "label"    : "Carvoyant API Key",
          "dtype"    : "text"
        },
        {
          "name"     : "api_secret",
          "label"    : "Security token",
          "dtype"    : "text"
        },
        {
          "name"     : "vehicle_id",
          "label"    : "Device ID for vehicle",
          "dtype"    : "text"
        }
      ];
      data = {
	"api_key" : "none",
	"api_secret" : "none",
	"vehicle_id" : "none"
      };

    }
    always {
      raise pds event new_settings_schema
        with setName   = meta:rulesetName()
        and  setRID    = meta:rid()
        and  setSchema = schema
        and  setData   = data
        and  _api = "sky";
    }
  }

 
}