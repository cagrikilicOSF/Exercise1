/**
 * File:        WeatherController_Test.cls
 * Date:        Jan 16, 2023
 * Created By:  Cagri Kilic
 * *************************************************************************
 * Description: WeatherController test class
 * *************************************************************************
 * History:
 * Date:            Modified By:           Description:
 */
@isTest
public with sharing class WeatherController_Test {
    private static Account testAccount;
    /**
     * @author Cagri Kilic
     * @date Jan 16, 2023
     * @description  create test data
     */
    private static void createTestData() {
        testAccount = new Account(
            Name = 'Test Account',
            BillingCity = 'London'
        );
        insert testAccount;
        List<openweatherendpoint__c> cSettings = new List<openweatherendpoint__c>();
        for (Integer i = 0; i < 2; i++) {
            openweatherendpoint__c customSetting = new openweatherendpoint__c();
            if (i == 0) {
                customSetting.Name = 'endpointpart1';
                customSetting.Endpoint_URL__c = 'https://api.openweathermap.org/data/2.5/weather?q=';
            } else {
                customSetting.Name = 'endpointpart2';
                customSetting.Endpoint_URL__c = '&units=metric&appid=3e6dc3c440ec8593b831072f36667c5d';
            }
            cSettings.add(customSetting);
        }
        insert cSettings;
    }
    /**
     * @author Cagri Kilic
     * @date Jan 16, 2023
     * @description Test function of WeatherController class
     */
    @isTest
    static void weatherControllerTest() {
        createTestData();
        Test.startTest();
        Test.setMock(HTTPCalloutMock.class, new WeatherConditionsMock());
        Apexpages.StandardController stdController = new Apexpages.StandardController(
            testAccount
        );
        WeatherController testController = new WeatherController(stdController);
        Test.stopTest();
        System.assert(testController.wrpData.description != null);
        System.assert(testController.wrpData.temp != null);
        System.assert(testController.wrpData.icon != null);
    }
}
