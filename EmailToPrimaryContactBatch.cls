/******************************************************************
 * @Name         : EmailToPrimaryContactBatch
 * @Description  : Batch Job of Email to Primary Contact
 * @Created By   : Cagri Kilic
 * @Created Date : Jan 12, 2023
 * @Modification Log :
 ******************************************************************
 * Version        Developer        Date        Description
 *------------------------------------------------------------
 *
 ******************************************************************/
public without sharing class EmailToPrimaryContactBatch implements Database.Batchable<sObject>, Database.Stateful {
    private Integer sentEmails = 0;
    /******************************************************************
  	* @Name         : start 
  	* @Description  : Returns the result of the sent query
  	* @Created By   : CagriKilic
  	* @Created Date : Jan 12, 2023
    * @Param bc     : Database.BatchableContext - Batchable Context
    * @Return       : Database.QueryLocator - Query Locator

  	******************************************************************/
    public Database.QueryLocator start(Database.BatchableContext bc) {
        try {
            String query = 'SELECT Id,Email,Account.Name,AccountId FROM Contact WHERE Is_Primary_Contact__c =True';
            return Database.getQueryLocator(query);
        } catch (QueryException e) {
            System.debug('An error occurred: ' + e.getMessage());
            return null;
        }
    }
    /******************************************************************
  	* @Name         : execute 
  	* @Description  : Processes data from query
  	* @Created By   : CagriKilic
  	* @Created Date : Jan 12, 2023
    * @Param bc     : Database.BatchableContext - Batchable Context
    * @Param con    : List<Contact> - List of Contacts 
    
  	******************************************************************/
    public void execute(Database.BatchableContext bc, List<Contact> con) {
        try {
            Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();
            List<Id> accIds = new List<Id>();
            Decimal[] amountsArr = new List<Decimal>{ 0, 0, 0 };
            for (Contact cnt : con) {
                accIds.add(cnt.AccountId);
            }
            List<Opportunity> opps = [
                SELECT StageName, Amount, AccountId
                FROM Opportunity
                WHERE AccountId IN :accIds
            ];
            for (Contact c : con) {
                for (Opportunity opp : opps) {
                    if (opp.AccountId == c.AccountId) {
                        if (opp.StageName == 'Closed Won') {
                            amountsArr[1] += opp.Amount; // sumClosedWonAmounts
                        } else if (opp.StageName == 'Closed Lost') {
                            amountsArr[2] += opp.Amount; // sumClosedLostAmounts
                        } else {
                            amountsArr[0] += opp.Amount; // sumOpenAmounts
                        }
                    }
                }
                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                message.setTargetObjectId(c.Id);
                message.setSenderDisplayName('Company Support');
                message.setReplyTo('no-reply@company.com');
                message.setUseSignature(false);
                message.setBccSender(false);
                message.setSaveAsActivity(false);
                EmailTemplate emailTemplate = [
                    SELECT
                        Id,
                        Subject,
                        Description,
                        HtmlValue,
                        DeveloperName,
                        Body
                    FROM EmailTemplate
                    WHERE Name = 'emailTemplate'
                ];
                emailTemplate.Body = emailTemplate.body.replace('{!Account.Name}', c.Account.Name);
                emailTemplate.Body = emailTemplate.body.replace('{!Opportunity.Amount}', String.valueOf(amountsArr[0]));
                emailTemplate.Body = emailTemplate.body.replace('{!Opportunity.Amount2}', String.valueOf(amountsArr[1]));
                emailTemplate.Body = emailTemplate.body.replace('{!Opportunity.Amount3}', String.valueOf(amountsArr[2]));
                message.setTemplateID(emailTemplate.Id);
                message.setWhatId(c.AccountId);
                message.setHtmlBody(emailTemplate.Body);
                message.toAddresses = new String[]{ c.Email };
                messages.add(message);
                sentEmails++;
            }
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
            if (results[0].success) {
                System.debug('The email was sent successfully.');
            } else {
                System.debug('The email failed to send: ' + results[0].errors[0].message);
            }
        } catch (Exception e) {
            System.debug('Error: ' + e);
        }
    }
    /******************************************************************
  	* @Name         : finish 
  	* @Description  : Result of batch job operation
  	* @Created By   : CagriKilic
  	* @Created Date : Jan 12, 2023
    * @Param bc     : Database.BatchableContext - Batchable Context 
    
  	******************************************************************/
    public void finish(Database.BatchableContext bc) {
        AsyncApexJob job = [
            SELECT
                Id,
                Status,
                NumberOfErrors,
                JobItemsProcessed,
                TotalJobItems,
                CreatedBy.Email
            FROM AsyncApexJob
            WHERE Id = :bc.getJobId()
        ];
        System.debug(sentEmails + ' Emails sent. Shazam!');
        System.debug('Job: ' + job);
    }
}
