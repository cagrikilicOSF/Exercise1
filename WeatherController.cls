/******************************************************************
 * @Name         : WeatherController
 * @Description  : Controller of WeatherController class
 * @Created By   : Cagri Kilic
 * @Created Date : Jan 16, 2023
 * @Modification Log :
 ******************************************************************
 * Version        Developer        Date        Description
 *------------------------------------------------------------
 *
 ******************************************************************/
public with sharing class WeatherController {
    public static final String HTTP_RESPONSE_ERROR = 'Error : An error occurred while retrieving weather information!';
    public WrapperData wrpData { get; set; }
    private final Account acc;
    private String city;
    /******************************************************************
     * @Name         : WeatherController
     * @Description  : Constructor of the class
     * @Created By   : CagriKilic
     * @Created Date : Jan 16, 2023
     * @Param controller   : ApexPages.StandardController - standard controller
     ******************************************************************/
    public WeatherController(ApexPages.StandardController controller) {
        this.acc = (Account) controller.getRecord();
        this.city = this.acc.BillingCity;
        fetchWeatherInfo();
    }
    /******************************************************************
  	* @Name         : fetchWeatherInfo 
  	* @Description  : Retrieves the weather information of the corresponding account
  	* @Created By   : CagriKilic
  	* @Created Date : Jan 16, 2023

  	******************************************************************/
    private void fetchWeatherInfo() {
        String APIKey = '3e6dc3c440ec8593b831072f36667c5d';
        String endPoint =
            'https://api.openweathermap.org/data/2.5/weather?q=' +
            city +
            '&units=metric&appid=' +
            APIKey;
        HttpRequest request = new HttpRequest();
        HttpResponse response = new HttpResponse();
        Http http = new Http();
        request.setEndpoint(endPoint);
        request.setMethod('GET');
        response = http.send(request);
        if (response.getStatusCode() == 200) {
            String jsonResponse = response.getBody();
            FromJSON jsonParseData = (FromJSON) parse(jsonResponse);
            wrpData = new WrapperData(jsonParseData);
        } else {
            ApexPages.addmessage(
                new ApexPages.message(
                    ApexPages.severity.ERROR,
                    HTTP_RESPONSE_ERROR
                )
            );
        }
    }
    /******************************************************************
     * @Name         : WrapperData
     * @Description  : Assigns weather information to variables
     * @Created By   : Cagri Kilic
     * @Created Date : Jan 16, 2023
     * @Modification Log :
     ******************************************************************
     * Version        Developer        Date        Description
     *------------------------------------------------------------
     *
     ******************************************************************/
    public class WrapperData {
        public Double temp { get; set; }
        public String description { get; set; }
        public String icon { get; set; }
        public WrapperData(FromJSON parseData) {
            Main te = parseData.main;
            this.temp = te.temp;
            this.description = parseData.weather[0].description;
            this.icon =
                'http://openweathermap.org/img/wn/' +
                parseData.weather[0].icon +
                '@2x.png';
        }
    }
    /******************************************************************
     * @Name         : FromJSON
     * @Description  : Contains objects of weather data
     * @Created By   : Cagri Kilic
     * @Created Date : Jan 16, 2023
     * @Modification Log :
     ******************************************************************
     * Version        Developer        Date        Description
     *------------------------------------------------------------
     *
     ******************************************************************/
    public class FromJSON {
        public Weather[] weather;
        public Main main;
    }
    /******************************************************************
     * @Name         : Weather
     * @Description  : Contains variables of json data of weather
     * @Created By   : Cagri Kilic
     * @Created Date : Jan 16, 2023
     * @Modification Log :
     ******************************************************************
     * Version        Developer        Date        Description
     *------------------------------------------------------------
     *
     ******************************************************************/
    public class Weather {
        public String main;
        public String description;
        public String icon;
    }
    /******************************************************************
     * @Name         : Main
     * @Description  : Contains variables of json data of main
     * @Created By   : Cagri Kilic
     * @Created Date : Jan 16, 2023
     * @Modification Log :
     ******************************************************************
     * Version        Developer        Date        Description
     *------------------------------------------------------------
     *
     ******************************************************************/
    public class Main {
        public Double temp;
        public Integer humidity;
    }
    /******************************************************************
  	* @Name         : parse 
  	* @Description  : Parses json data
  	* @Created By   : CagriKilic
  	* @Created Date : Jan 16, 2023
    * @Param json   : String - Data of Http response
    * @Return       : FromJSON - Weather datas

  	******************************************************************/
    private FromJSON parse(String json) {
        return (FromJSON) System.JSON.deserialize(json, FromJSON.class);
    }
}
