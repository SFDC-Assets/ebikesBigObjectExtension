trigger asyncRideUtils on Async_Ride__c (before insert) {
    for(Async_ride__c ar : trigger.new){
        ar.end_location__latitude__s = ar.end_location_lat__c;
        ar.end_location__longitude__s = ar.end_location_long__c;
        ar.start_location__latitude__s = ar.start_location_lat__c;
        ar.start_location__longitude__s = ar.start_location_long__c;
    }
}