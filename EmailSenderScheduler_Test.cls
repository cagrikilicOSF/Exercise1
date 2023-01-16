/**
 * File:        EmailSenderScheduler_Test.cls
 * Date:        Jan 13, 2023
 * Created By:  Cagri Kilic
 * *************************************************************************
 * Description: EmailSenderScheduler test class
 * *************************************************************************
 * History:
 * Date:            Modified By:           Description:
 */
@isTest
public with sharing class EmailSenderScheduler_Test {
    /**
     * @author Cagri Kilic
     * @date Jan 13, 2023
     * @description EmailSenderScheduler class's test function
     */
    @isTest
    static void emailSenderSchedulerTest() {
        String CRON_EXP = '0 0 10 ? * *'; //Every Day at 10.00 AM
        Test.startTest();
        EmailSenderScheduler scheduleObject = new EmailSenderScheduler();
        String jobId = scheduleObject.scheduleMe();
        CronTrigger ct = [
            SELECT Id, CronExpression, TimesTriggered, NextFireTime
            FROM CronTrigger
            WHERE id = :jobId
        ];
        System.assertEquals(CRON_EXP, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        System.assert(Date.today() < ct.NextFireTime);
        Test.stopTest();
    }
}
