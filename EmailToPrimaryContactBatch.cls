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
    private Map<Id, Map<String, Decimal>> opportunityAmounts;
    private static final String STAGE_OPEN = 'Open';
    private static final String STAGE_CLOSED_WON = 'Closed Won';
    private static final String STAGE_CLOSED_LOST = 'Closed Lost';
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
            String query = 'SELECT StageName, Amount, AccountId FROM Opportunity WHERE LastModifiedDate = THIS_MONTH';
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
            opportunityAmounts = new Map<Id, Map<String, Decimal>>();
            String stageName;
            for (Opportunity o : opps) {
                if (o.StageName != STAGE_CLOSED_LOST && o.StageName != STAGE_CLOSED_WON) {
                    stageName = STAGE_OPEN;
                } else {
                    stageName = o.StageName;
                }
                if (opportunityAmounts.containsKey(o.AccountId)) {
                    opportunityAmounts.get(o.AccountId)
                        .put(stageName, opportunityAmounts.get(o.AccountId).get(stageName) + o.Amount);
                } else {
                    opportunityAmounts.put(o.AccountId,
                        new Map<String, Decimal>{
                            STAGE_OPEN => 0,
                            STAGE_CLOSED_LOST => 0,
                            STAGE_CLOSED_WON => 0
                        }
                    );
                    opportunityAmounts.get(o.AccountId)
                        .put(stageName, opportunityAmounts.get(o.AccountId).get(stageName) + o.Amount);
                }
            }
        } catch (Exception e) {
            System.debug('Error: ' + e);
        }
    }
    /******************************************************************
  	* @Name         : finish 
  	* @Description  : Finds primary contacts and shows job result
  	* @Created By   : CagriKilic
  	* @Created Date : Jan 12, 2023
    * @Param bc     : Database.BatchableContext - Batchable Context 
    
  	******************************************************************/
    public void finish(Database.BatchableContext bc) {
        try {
            Set<Id> accIds = new Set<Id>(opportunityAmounts.keySet());
            List<Contact> primaryContacts = [
                SELECT Id, Email, Account.Name, AccountId
                FROM Contact
                WHERE Is_Primary_Contact__c = TRUE AND AccountId IN :accIds
            ];
            sentMesssages(primaryContacts);
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

    /******************************************************************
  	* @Name         : sentMesssages 
  	* @Description  : Sends email to primary contacts
  	* @Created By   : CagriKilic
  	* @Created Date : Jan 13, 2023
    * @Param bc     : List<Contact> - List of contacts
    
  	******************************************************************/
    private void sentMesssages(List<Contact> cList) {
        try {
            Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();
            EmailTemplate emailTemplate = [
                SELECT Id, Subject, Description, HtmlValue, DeveloperName, Body
                FROM EmailTemplate
                WHERE Name = 'emailTemplate'
            ];
            for (Contact c : cList) {
                String body = emailTemplate.body;
                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                message.setTargetObjectId(c.Id);
                message.setSenderDisplayName('Company Support');
                message.setReplyTo('no-reply@company.com');
                message.setUseSignature(false);
                message.setBccSender(false);
                message.setSaveAsActivity(false);
                body = body.replace('{!Account.Name}', c.Account.Name);
                body = body.replace(
                    'OpenAmount',
                    String.valueOf(opportunityAmounts.get(c.AccountId).get('Open'))
                );
                body = body.replace(
                    'ClosedWonAmount',
                    String.valueOf(opportunityAmounts.get(c.AccountId).get('Closed Won'))
                );
                body = body.replace(
                    'ClosedLostAmount',
                    String.valueOf(opportunityAmounts.get(c.AccountId).get('Closed Lost'))
                );
                message.setTemplateID(emailTemplate.Id);
                message.setWhatId(c.AccountId);
                message.setHtmlBody(body);
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
        } catch (Exception e) {
            System.debug('Error: ' + e);
        }
    }
}