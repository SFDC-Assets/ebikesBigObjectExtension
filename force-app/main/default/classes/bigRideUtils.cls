public with sharing class bigRideUtils {
    
    @AuraEnabled(cacheable=true)
    public static List<Big_Ride__b> getCustomerRecentRideRecords(string contactID){
        List<Big_Ride__b> rideList = [SELECT contact__c, rental_unit__c, start_location_lat__c, start_location_long__c,
                                        end_location_lat__c, end_location_long__c, start_time__c, end_time__c, trip_id__c
                                        FROM Big_Ride__b
                                        WHERE Contact__c = :contactID ORDER BY contact__c asc, start_time__c limit 25];
        return rideList;
    }
    
}
