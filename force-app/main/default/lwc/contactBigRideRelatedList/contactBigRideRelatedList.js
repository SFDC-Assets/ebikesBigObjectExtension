import { LightningElement, api, wire, track } from 'lwc';
import getCustomerRecentRideRecords from '@salesforce/apex/bigRideUtils.getCustomRideRecords';

const rideColumns = [
    {label: 'Customer', type: 'url', fieldName: 'contactURL', typeAttributes:{label:{fieldName:'ContactName'}}},
    {label: 'Start Time', fieldName: 'Start_Time', type: 'date-local'},
    {label: 'End Time', fieldName: 'End_Time', type: 'date-local'},
    {label: 'Rental Unit ID', fieldName: 'unitURL', type:'url', typeAttributes:{label:{fieldName:'Rental_UnitName'}}},
    {label: 'Trip ID', fieldName: 'Trip_ID'}
];

export default class ContactBigRideRelatedList extends LightningElement {
    @api recordId;
    @track rideRecords;
    @track error;
    @track rideColumns = rideColumns;

    @wire(getCustomerRecentRideRecords, {contactID: '$recordId'})
    handleRideRecords(data, error){
        if(data){
            console.log('data');
            console.log(data);
            this.rideRecords = data;
            this.error = undefined;
        }else if(error){
            this.rideRecords = undefined;
            this.error = error;
        }
    }
    
}