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
    private List<Contact> primaryContacts;
    private Map<Id, Decimal[]> opportunityAmounts;
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
            String query = 'SELECT StageName, Amount, AccountId FROM Opportunity';
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
    * @Param con    : List<Opportunity> - List of Opportunities 
    
  	******************************************************************/
    public void execute(Database.BatchableContext bc, List<Opportunity> opps) {
        try {
            opportunityAmounts = new Map<Id, Decimal[]>();
            primaryContacts = [
                SELECT Id, Email, Account.Name, AccountId
                FROM Contact
                WHERE Is_Primary_Contact__c = TRUE
            ];

            for (Contact c : primaryContacts) {
                opportunityAmounts.put(c.AccountId, new List<Decimal>{ 0, 0, 0 });
                for (Opportunity o : opps) {
                    if (o.AccountId == c.AccountId) {
                        if (o.StageName == 'Closed Won') {
                            opportunityAmounts.get(c.AccountId)[1] += o.Amount; // sumClosedWonAmounts
                        } else if (o.StageName == 'Closed Lost') {
                            opportunityAmounts.get(c.AccountId)[2] += o.Amount; // sumClosedLostAmounts
                        } else {
                            opportunityAmounts.get(c.AccountId)[0] += o.Amount; // sumOpenAmounts
                        }
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error: ' + e);
        }
    }
    /******************************************************************
  	* @Name         : finish 
  	* @Description  : Sends email to primary contacts
  	* @Created By   : CagriKilic
  	* @Created Date : Jan 12, 2023
    * @Param bc     : Database.BatchableContext - Batchable Context 
    
  	******************************************************************/
    public void finish(Database.BatchableContext bc) {
        try {
            Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();
            for (Contact c : primaryContacts) {
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
                emailTemplate.Body = emailTemplate.body.replace(
                    '{!Account.Name}',
                    c.Account.Name
                );
                emailTemplate.Body = emailTemplate.body.replace(
                    'OpenAmount',
                    String.valueOf(opportunityAmounts.get(c.AccountId)[0])
                );
                emailTemplate.Body = emailTemplate.body.replace(
                    'ClosedWonAmount',
                    String.valueOf(opportunityAmounts.get(c.AccountId)[1])
                );
                emailTemplate.Body = emailTemplate.body.replace(
                    'ClosedLostAmount',
                    String.valueOf(opportunityAmounts.get(c.AccountId)[2])
                );
                message.setTemplateID(emailTemplate.Id);
                message.setWhatId(c.AccountId);
                message.setHtmlBody(emailTemplate.Body);
                message.toAddresses = new List<String>{ c.Email };
                messages.add(message);
                sentEmails++;
            }
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
                if (results[0].success) {
                    System.debug('The email was sent successfully.');
                } else {
                    System.debug('The email failed to send: ' + results[0].errors[0].message);
                }

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
        } catch (Exception e) {
            System.debug('Error: ' + e);
        }
    }
}
