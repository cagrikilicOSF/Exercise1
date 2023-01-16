/******************************************************************
 * @Name         : EmailSenderScheduler
 * @Description  : Schedule Job of Email to Primary Contact Batch
 * @Created By   : Cagri Kilic
 * @Created Date : Jan 12, 2023
 * @Modification Log :
 ******************************************************************
 * Version        Developer        Date        Description
 *------------------------------------------------------------
 *
 ******************************************************************/
public class EmailSenderScheduler implements Schedulable {
    private final String sch = '0 0 10 ? * *'; //Every Day at 10.00 AM
    //private final String sch = '0 0 13 ? * 5';  //Friday at 1.00 PM
    //private final String sch = '0 0 18 ? * 5L';  //Last Friday of the Month at 06.00 PM

    /******************************************************************
  	* @Name         : execute 
  	* @Description  : Runs Batch Job
  	* @Created By   : CagriKilic
  	* @Created Date : Jan 12, 2023
    * @Param ctx     : SchedulableContext - Schedulable Context
    
  	******************************************************************/
    public void execute(SchedulableContext ctx) {
        EmailToPrimaryContactBatch emailSenderBatch = new EmailToPrimaryContactBatch();
        ID batchprocessid = Database.executeBatch(emailSenderBatch, 100);
    }

    /******************************************************************
  	* @Name         : scheduleMe 
  	* @Description  : Runs Schedule Job
  	* @Created By   : CagriKilic
  	* @Created Date : Jan 12, 2023
    * @Return       : System.schedule - Schedule Job
     
  	******************************************************************/
    public String scheduleMe() {
        EmailSenderScheduler emailScheduler = new EmailSenderScheduler(); 
        return System.schedule('EmailToPrimaryContactBatch Job', sch, emailScheduler);
    }
}
