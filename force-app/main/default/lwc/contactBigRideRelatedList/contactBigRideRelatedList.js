import { LightningElement, api, wire, track } from 'lwc';
import getCustomerRecentRideRecords from '@salesforce/apex/bigRideUtils.getCustomerRecentRideRecords';

const rideColumns = [
    {label: 'Customer', fieldName: 'Contact__c'},
    {label: 'Start Time', fieldName: 'Start_Time__c', type: 'date-local'},
    {label: 'End Time', fieldName: 'End_Time__c', type: 'date-local'},
    {label: 'Rental Unit ID', fieldName: 'Rental_Unit__c'},
    //{label: 'Start Latitude', fieldName: 'Start_Location_Lat__c'},
    //{label: 'Start Longitude', fieldName: 'Start_Location_Long__c'},
    //{label: 'End Latitude', fieldName: 'End_Location_Lat__c'},
    //{label: 'End Longitude', fieldName: 'End_Location_Long__c'},
    {label: 'Trip ID', fieldName: 'Trip_ID__c'}
];

export default class ContactBigRideRelatedList extends LightningElement {
    @api recordId;
    @track rideRecords;
    @track error;
    @track rideColumns = rideColumns;

    @wire(getCustomerRecentRideRecords, {contactID: '$recordId'})
    handleRideRecords(data, error){
        if(data){
            this.rideRecords = data;
            this.error = undefined;
        }else if(error){
            this.rideRecords = undefined;
            this.error = error;
        }
    }
    
}