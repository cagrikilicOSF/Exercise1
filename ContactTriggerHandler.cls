/******************************************************************
 * @Name         : ContactTriggerHandler
 * @Description  : Methods of Contact Trigger
 * @Created By   : Cagri Kilic
 * @Created Date : Jan 06, 2023
 * @Modification Log :
 ******************************************************************
 * Version        Developer        Date        Description
 *------------------------------------------------------------
 *
 ******************************************************************/
public with sharing class ContactTriggerHandler {
    /******************************************************************
     * @Name         : validatePrimaryBeforeInsert
     * @Description  : Method of Before Insert Trigger
     * @Created By   : CagriKilic
     * @Created Date : Jan 06, 2023
     * @Param con    : List<Contact> - Contact list
     ******************************************************************/
    public void validatePrimaryBeforeInsert(List<Contact> con) {
        try {
            List<Contact> oldContact = [
                SELECT Id, Name, Is_Primary_Contact__c, AccountId
                FROM Contact
                WHERE Is_Primary_Contact__c = TRUE
            ];
            for (Contact c : oldContact) {
                for (Contact cnt : con) {
                    if (
                        c.AccountId == cnt.AccountId &&
                        cnt.Is_Primary_Contact__c == true
                    ) {
                        cnt.Is_Primary_Contact__c.addError(
                            'The contact cannot be created because there is an already existing primary contact!'
                        );
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error: ' + e);
        }
    }
    /******************************************************************
     * @Name         : processPrimaryAfterInsert
     * @Description  : Method of After Insert Trigger
     * @Created By   : CagriKilic
     * @Created Date : Jan 06, 2023
     * @Param con    : List<Contact> - Contact list
     ******************************************************************/
    public void processPrimaryAfterInsert(List<Contact> con) {
        try {
            List<Id> conIds = new List<Id>();
            for (Contact c : con) {
                if (c.Is_Primary_Contact__c == true) {
                    conIds.add(c.Id);
                }
            }
            if (System.IsBatch() == false && System.isFuture() == false) {
                processPrimaryAfterInsertAndUpdateAsync(conIds);
            }
        } catch (Exception e) {
            System.debug('Error: ' + e);
        }
    }
    /******************************************************************
     * @Name         : processPrimaryAfterInsertAndUpdateAsync
     * @Description  : Async Method of After Insert and Update Trigger
     * @Created By   : CagriKilic
     * @Created Date : Jan 06, 2023
     * @Param con    : List<Id> - Contact Ids
     ******************************************************************/
    @future
    private static void processPrimaryAfterInsertAndUpdateAsync(List<Id> conIds) {
        try {
            List<Contact> consToUpdate = new List<Contact>();
            List<Contact> insertedContacts = [
                SELECT
                    Primary_Contact_Phone__c,
                    Is_Primary_Contact__c,
                    AccountId,
                    Phone
                FROM Contact
                WHERE Id IN :conIds
            ];

            List<Contact> oldContact = [
                SELECT Id, Name, Is_Primary_Contact__c, AccountId
                FROM Contact
                WHERE Is_Primary_Contact__c = FALSE
            ];
            for (Contact cnt : insertedContacts) {
                for (Contact c : oldContact) {
                    if (c.AccountId == cnt.AccountId) {
                        c.Primary_Contact_Phone__c = cnt.Phone;
                        consToUpdate.add(c);
                        if (!consToUpdate.contains(cnt)) {
                            cnt.Primary_Contact_Phone__c = cnt.Phone;
                            consToUpdate.add(cnt);
                        }
                    }
                }
            }

            Database.update(consToUpdate, false);
        } catch (Exception e) {
            System.debug('Error: ' + e);
        }
    }
    /******************************************************************
     * @Name         : validatePrimaryBeforeUpdate
     * @Description  : Method of Before Update Trigger
     * @Created By   : CagriKilic
     * @Created Date : Jan 06, 2023
     * @Param con    : List<Contact> - Contact list
     ******************************************************************/
    public void validatePrimaryBeforeUpdate(List<Contact> con) {
        try {
            List<Contact> oldContact = [
                SELECT Id, Name, Is_Primary_Contact__c, AccountId
                FROM Contact
                WHERE Is_Primary_Contact__c = TRUE
            ];
            for (Contact c : oldContact) {
                for (Contact cnt : con) {
                    if (
                        c.AccountId == cnt.AccountId &&
                        cnt.Is_Primary_Contact__c == true &&
                        c.Id != cnt.Id
                    ) {
                        cnt.Is_Primary_Contact__c.addError(
                            'The contact cannot be updated because there is an already existing primary contact!'
                        );
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error: ' + e);
        }
    }
    /******************************************************************
     * @Name         : processPrimaryAfterUpdate
     * @Description  : Method of After Update Trigger
     * @Created By   : CagriKilic
     * @Created Date : Jan 06, 2023
     * @Param con    : List<Contact> - Contact list
     ******************************************************************/
    public void processPrimaryAfterUpdate(List<Contact> con) {
        try {
            List<Id> conIds = new List<Id>();
            for (Contact c : con) {
                if (c.Is_Primary_Contact__c == true) {
                    conIds.add(c.Id);
                }
            }
            if (System.IsBatch() == false && System.isFuture() == false) {
                processPrimaryAfterInsertAndUpdateAsync(conIds);
            }
        } catch (Exception e) {
            System.debug('Error: ' + e);
        }
    }
}
