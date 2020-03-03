public with sharing class bikeDataUtil {
    
    public static void makeRentalBikes(integer numberOfBikes, string status){
        //get list of bike product types
        //lets do a random distribution, all of status = status

        List<Rental_Unit__c> rentalInsertList = new list<Rental_Unit__c>();
        List<Product__c> bikeModels = [select id from product__c];
        integer chosenIndex = 0;
        for(integer x=0;x<numberOfBikes;x++){
            //randomly gen the product id
            chosenIndex = Integer.ValueOf(Math.rint(Math.random() * bikeModels.size()));
            if(chosenIndex == bikeModels.size()) chosenIndex--;
            Rental_Unit__c newUnit = new Rental_Unit__c(product__c=bikeModels[chosenIndex].id, unit_status__c=status);
            rentalInsertList.add(newUnit);
        }
        insert rentalInsertList;
    }

    public static void makeSObjectRides(Integer numberOfRides){
        List<Rental_Ride__c> newRideRecords = new List<Rental_Ride__c>();
        List<Rental_Unit__c> rentalUnits = [select id from Rental_Unit__c];
        List<Contact> contacts = [select id from Contact];
        Integer rentalIndex, contactIndex;
        for(Integer x=0;x<numberOfRides;x++){
            rentalIndex = Integer.ValueOf(Math.rint(Math.random()*rentalUnits.size()));
            contactIndex = Integer.ValueOf(Math.rint(Math.random()*contacts.size()));
            if(rentalIndex == rentalUnits.size()) rentalIndex--;
            if(contactIndex == contacts.size()) contactIndex--;
            newRideRecords.add(bikeDataUtil.generateRideRecord(contacts[contactIndex].id, rentalUnits[rentalIndex].id));
        }
        insert newRideRecords;
    }

    public static void makeBObjectRides(Integer numberOfRides){
        List<Big_Ride__b> newRideRecords = new List<Big_Ride__b>();
        List<Rental_Unit__c> rentalUnits = [select id from Rental_Unit__c];
        List<Contact> contacts = [select id from Contact];
        Integer rentalIndex, contactIndex;
        for(Integer x=0;x<numberOfRides;x++){
            rentalIndex = Integer.ValueOf(Math.rint(Math.random()*rentalUnits.size()));
            contactIndex = Integer.ValueOf(Math.rint(Math.random()*contacts.size()));
            if(rentalIndex == rentalUnits.size()) rentalIndex--;
            if(contactIndex == contacts.size()) contactIndex--;
            newRideRecords.add(bikeDataUtil.generateBigRide(contacts[contactIndex].id, rentalUnits[rentalIndex].id));
        }
        system.debug('HERE WE GO');
        Database.insertImmediate(newRideRecords);
    }

    public static void makePredictableBRides(Integer numberOfRides){
        List<Big_Ride__b> newRideRecords = new List<Big_Ride__b>();
        for(Integer x=0;x<numberOfRides;x++){
            string contactID = '0030R000010wUydQAE';
            string rentalID = 'a040R000002euPeQAI';
            Big_Ride__b newBike = bikeDataUtil.generateBigRide(contactID, rentalID);
            //newBike.Trip_ID__c = '1234567890123456789012345678901234567890123456789012345678901234567890';
            newRideRecords.add(newBike);
            //newRideRecords.add(bikeDataUtil.generateBigRide(contactID, rentalID));
        }
        system.debug('HERE WE GO');
        List<Database.SaveResult> srs = Database.insertImmediate(newRideRecords);
        for(Database.SaveResult sr : srs){
            if(sr.isSuccess())
            {
                system.debug('We did it ' + sr.getId());
            }else{
                for(Database.Error err : sr.getErrors()){
                    system.debug('shit blew up');
                    system.debug(err.getStatusCode() + ':' + err.getMessage());
                    system.debug('fields that affected - ' + err.getFields());
                }
            }
        }
    }

    //I dont wanna re-remember this stupid algorithm every time
    private static Decimal randBetween(Decimal lowerBound, Decimal upperBound){
        Decimal range = Math.abs(upperBound-lowerBound);
        return (Math.random() * range + lowerBound);
    }

    private static Rental_Ride__c generateRideRecord(string contactID, string RentalID){
        Rental_Ride__c ride = new Rental_Ride__c(Contact__c=contactID,
                                                 Rental_Unit__c=rentalID);
        //generate random location
        //+- up to .1 degree
        Decimal startLatitude = randBetween(19.50139, 64.85694);
        Decimal endLatitude = randBetween(startLatitude-.1, startLatitude+.1);
        Decimal startLongitude= randBetween(-161.75583, -68.01197);
        Decimal endLongitude = randBetween(startLongitude-.1, startLongitude+.1);
        ride.start_location__latitude__s = startLatitude;
        ride.start_location__longitude__s = startLongitude;
        ride.end_location__latitude__s = endLatitude;
        ride.end_location__longitude__s = endLongitude;
        
        //generate random time
        //+ up to 2 hours
        DateTime startTime = DateTime.newInstance(
            (Long)Math.floor(randBetween(1514764800801.0,1585699200801.0))
        );
        DateTime endTime = startTime.addSeconds(Integer.valueOf(randBetween(108, 10800)));
        ride.start_Time__c = startTime;
        ride.end_Time__c = endTime;
        return ride;
    }
    private static Big_Ride__b generateBigRide(string contactID, string RentalID){
        Big_Ride__b ride = new Big_Ride__b(contact__c=contactID, rental_unit__c=rentalID);
        Decimal startLatitude = randBetween(19.50139, 64.85694);
        Decimal endLatitude = randBetween(startLatitude-.1, startLatitude+.1);
        Decimal startLongitude= randBetween(-161.75583, -68.01197);
        Decimal endLongitude = randBetween(startLongitude-.1, startLongitude+.1);
        ride.start_location_lat__c = startLatitude;
        ride.start_location_long__c = startLongitude;
        ride.end_location_lat__c = endLatitude;
        ride.end_location_long__c = endLongitude;
        DateTime startTime = DateTime.newInstance(
            (Long)Math.floor(randBetween(1514764800801.0,1585699200801.0))
        );
        DateTime endTime = startTime.addSeconds(Integer.valueOf(randBetween(108, 10800)));
        ride.start_time__c = startTime;
        ride.end_time__c = endTime;
        ride.trip_id__c = generateTripUUID();
        system.debug(ride);
        return ride;
    }
    
    private static string generateTripUUID(){
        Blob b = Crypto.generateAesKey(128);
        String h = EncodingUtil.convertToHex(b);
        String guid = h.SubString(0,8) + '-' + h.SubString(8,12) + '-' + h.substring(12, 16) + '-' + h.substring(16, 20) + '-' + h.substring(20);
        return guid;
    }
    
}



