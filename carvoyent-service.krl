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

    get_config_value = function (name) {
      pds:get_setting_data_value(meta:rid(), name);
    };

     // API_key = "04b4df2e-04f3-4c11-b0be-796a05896ae1";
     // carvoyent_secret = "13319e3b-c2be-4d24-aee5-9b2b9e6af6e7";
     // my_vehicle_id = "C201200099";

    carvoyent_url = function(vehicle_id) {
      api_base_url = "https://dash.carvoyant.com/api/"+"/vehicle/";
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

      vinfo = get_vehicle_data().pick("$.content").decode();
      running = vinfo.pick("$..running") => "Running" | "Off";
      lat = vinfo.pick("$..latitude");
      long = vinfo.pick("$..longitude");

      my_html = <<
<div style="margin: 0px 0px 20px 20px">
Name: #{vinfo.pick("$..name")}<br/>
Mileage: #{vinfo.pick("$..mileage")}<br/>
Status: #{running} at #{vinfo.pick("$..lastRunningTimestamp")}<br/>
<p><iframe width="425" height="350" frameborder="0" scrolling="no" marginheight="0" marginwidth="0" src="https://maps.google.com/maps?f=q&amp;source=s_q&amp;hl=en&amp;geocode=&amp;q=#{lat},#{long}&amp;aq=&amp;sll=#{lat-1},#{long-.4}&amp;sspn=10.363221,9.788818&amp;ie=UTF8&amp;t=m&amp;z=14&amp;ll=#{lat},#{long}&amp;output=embed"></iframe><br /><small><a href="https://maps.google.com/maps?f=q&amp;source=embed&amp;hl=en&amp;geocode=&amp;q=#{lat},#{long}&amp;aq=&amp;sll=#{lat-1},#{long-0.4}&amp;sspn=10.363221,9.788818&amp;ie=UTF8&amp;t=m&amp;z=14&amp;ll=#{lat},#{long}" style="color:#0000FF;text-align:left">View Larger Map</a></small></p>
</div>
>>;
    }
    {
      CloudRain:createLoadPanel("Carvoyent Test", {}, my_html);
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
	"api_key" : "",
	"api_secret" : "",
	"vehicle_id" : ""
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