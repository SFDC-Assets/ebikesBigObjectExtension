# Custom Big Objects additive to the Ebikes repo _(ebikesBigObjectExtension)_

[![Salesforce API v48.0](https://img.shields.io/badge/Salesforce%20API-v48.0-blue.svg)]()
[![Lightning Experience Required](https://img.shields.io/badge/Lightning%20Experience-Required-informational.svg)]()
[![User License Platform](https://img.shields.io/badge/User%20License-Platform-032e61.svg)]()
[![Apex Test Coverage 0](https://img.shields.io/badge/Apex%20Test%20Coverage-0-red.svg)]()

>An extension of [Trailhead Apps' Ebikes Repo](https://github.com/trailheadapps/ebikes-lwc) adding a Big Object usecase through a rental bike IoT scenario.

Hopefully this helps people 'get' Big Objects a bit better, vs external stores. We've got a rental ride object as a Custom Big Object(CBO), a custom UI component to do real-time queries against it, and some async SOQL jobs to show off the power of the data pipeline it provides us. Also a ton of quick scripts to execute it all quickly and easily.

## Table of Contents
<!-- Optional if doc is less than 100 lines total 
    Link to all sections, start with the next one, don't include anything above. Capture all ## headings, optional to get ### and ####, you do you.
-->
- [Custom Big Objects additive to the Ebikes repo _(ebikesBigObjectExtension)_](#custom-big-objects-additive-to-the-ebikes-repo-ebikesbigobjectextension)
  - [Table of Contents](#table-of-contents)
  - [Background](#background)
  - [Install](#install)
    - [Dependencies](#dependencies)
  - [Extra Sections](#extra-sections)
    - [Security / Limitations](#security--limitations)
  - [Maintainers](#maintainers)
  - [Contributing](#contributing)
  - [License](#license)

## Background

Custom Big Objects are still criminally underused. Salesforce Objects have a purpose, and are insanely flexible - but at certain scales you will see major performance implications as with any relational database. A multi-tenant processing logic tier isn't going to infinitely scale either, further complicating the processing of this data. CBO solves both problems, especially when keeping data close to Salesforce.

## Install

1. Set up your environment. Follow the steps in the [Quick Start: Lightning Web Components](https://trailhead.salesforce.com/content/learn/projects/quick-start-lightning-web-components/) Trailhead project. The steps include:

-   Enable Dev Hub in your Trailhead Playground
-   Install Salesforce CLI
-   Install Visual Studio Code
-   Install the Visual Studio Code Salesforce extensions, including the Lightning Web Components extension

2. If you haven't already done so, authenticate with your hub org and provide it with an alias (**myhuborg** in the command below):

```
sfdx force:auth:web:login -d -a myhuborg
```

3. Clone the repository:

```
git clone https://github.com/trailheadapps/ebikes-lwc
cd ebikes-lwc
```

4. Create a scratch org and provide it with an alias (**ebikes** in the command below) - in order to work with Async SOQL, you need to ensure your config file (if you are weird and don't use the one included with this repository) has 'FieldAuditTrail' listed in the 'features' array. If that doesn't make sense, just use the file I gave you:
```
sfdx force:org:create -s -f config/project-scratch-def.json -a ebikes
```

5. Push the app to your scratch org:

```
sfdx force:source:push
```

6. Assign the **ebikes** permission set to the default user:

```
sfdx force:user:permset:assign -n ebikes
```

7. Load sample data:

```
sfdx force:data:tree:import --plan ./data/sample-data-plan.json
```

8. Get your password generated, so you can use workbench to check on things every now and then.
```
sfdx force:user:password:generate
```
If you need your password in the future, run `sfdx force:user:display`.

9. Generate Big Object rows for Big_Ride__b. This will create 10 jobs in your apex queue, each to generate 10,000 rows in the big object Big_Ride__b. It will probably take awhile. 
```
sfdx:force:apex:execute -f config/rentalLoad.apex
```
To check your job statuses, go into Setup->Apex Jobs, and you should see all the newly created jobs listed. You'll know you're good to go when they all say 'Completed'. Expect maybe 10m?

10. Run your first async SOQL job. This will extract all Big_Ride__b rows where startDate is within 2019, and insert into an SObject called 'Async_Ride__c'. If you want to change that date for whatever reason, it's in the asyncRideLoader.apex file (which is in this repository, not a class loaded to Salesforce)
```
sfdx force:apex:execute -f config/asyncRideLoader.apex
```
So this is going to be our first Async SOQL job. Let's explain what we're doing - This job will do an extract of all Rides taken in the last year - and then bringing it into an SObject called Async_Ride__c. Why? Async SOQL jobs allow us to query outside the bounds of indexes - so I can ask for much more, and deposit that chunk in either another Big Object or an SObject. 

We're getting the year's worth of data so we can calculate the operational hours of every rental unit during that time. We'll just add up and increment a value on the related rental_unit. Easy Apex, but this is how we do that across a datastore that might include BILLIONS of rows - that Apex would time out otherwise. 

It's unfortunately not *super* simple to get the status of an Async SOQL job, and they'll take minutes for sure. While we're waiting, it's time to...

1.  Open up the app and make some clicks with all this code
```
sfdx force:org:open
```

12. Add the Big Object related list to the contact page.
Go to the Contact record page for any record, and hit the gear -> Edit Page. In App Builder, drag and drop the custom LWC component 'bigRideRelatedList' onto the page. Big Objects don't operate exactly like SObjects do - so you need a custom component in order to do a related list. This component is doing a synchronous SOQL query, just like any other, at the Big_Ride__b object and pulling back the Contact's most recent 25 rides. 

13.  (Optional) Let's learn a bit about the Custom Big Object(CBO) that's here, and also some supporting SObject cast while we wait.
Setup -> Big Objects -> Big_Ride__b will show you the definition of the CBO we're working with here. It's a fairly simple flat table, and you can get to it using SOQL just like a custom object. You'll note at the bottom of the page though is the 'Index', made up of Contact, Start_Time__c. We defined this index the way we did because in looking at usecases we decided the most common request you're gonna get for a customer is to ask about a recent trip/trips. Due to how we physically store data in CBO - we need a pre-defined index to be able to get to data we want, otherwise you'd be searching forever, and the call would time out. If you want a real-world analogy, try to remember the days of Dewey Decimal systems in libraries. 

 The SOQL's WHERE clause has to follow the flow of the index - so, using the index built for this particular CBO, you'd have to at least filter by Contact, and then if you wanted further, filter by Start_Time__c. You can't skip Contact, and just filter by Start_Time__c, but you also can't get ranges of Contact's either (greater/less than). This needs to be planned for when using a Big Object.

 You'll notice we have lookup fields - and that's interesting because...it's not an SObject. These will enable two things beyond just doing a simple text field, but come with one major caveat. It'll do validation at **write-time** just like SObjects to ensure that the value is a valid one, and it will allow us to do joins in Async SOQL jobs - which can be a massive advantage to using them. The caveat - note the bolded write-time above - if you were to look a ride up to a Contact, and then delete that Contact - nothing will check or validate the CBO Record(s) looking up to that Contact. You will need to act on your own to maintain consistency with the CBO table, which depending on how you built your index could mean a simple SOQL/DML statement, or a complete Async SOQL job. Furthermore - orphaned records are essentially corrupted, and you won't be able to write them to an SObject or other CBO's lookup field due to it being a newly invalidated value. The fun of distributed data.

14.   Check the Async_Ride__c object to see if it's full yet
You can easily check it with the list view on the tab. Flip to All. It'll either be empty or big. No inbetween here. Once you see data in here, run
```
sfdx force:apex:execute -f config/batchHoursRunner.apex
```
This is gonna create a batch job to take the ride records you added, calculate the hour differential between Start/End times on that row, and then add/aggregate onto the related Rental_Unit__c. 

In Setup, you'll find the batch jobs in ...the batch job page. I forget where this is just search :D

15. Time for more Async SOQL - you can run this even if the batch apex isn't done yet.
```
sfdx force:apex:execute -f config/asyncAggLoader.apex
```
This Async SOQL job will do an aggregate function (COUNT()) and JOIN that with related Rental_Unit__c records and their related products - this is a big deal. We're counting the total number of rides and trying to connect Contacts to Products, so we can tell our Sales folk what type of rides our people like - Better STILL, this is going to be accessible from SF reports and dashboards. Because it's in an sObject. YUUP.

Ok, now that THIS is in, your reports will magically work. Which reports? There's one on the contact layout, showing the most common model of bike this person's ridden (so sales can pitch em a bike). This gets a bit further into the value of Async SOQL on CBO, vs Postgres or an external storage. You can perform a fairly complicated set of jobs with just a single API call, and let the system figure it out. Once it's in SObject form, you can then do whatever you want with it there, using the same tools you're used to.

### Dependencies
* The [Trailhead Apps' Ebikes Repo](https://github.com/trailheadapps/ebikes-lwc) - but that is included already in this repo as are their install instructions.

## Extra Sections
### Security / Limitations
Few major things to understand with CBO
* CBO is not the same database as an SObject - which means you are not within the same atomic transaction, nor do we do aggressive validation of consistency between both stores. Big important thing there to keep from corrupting data.
* CBO does not have per-row permissions. Use your Apex or existing SObject row limitations as a means to control access and queries to CBO rows. Once you pull in CBO rows via Async SOQL to SObjects, place new row limitations on those as necessary.
* Other stuff I forgot.

## Maintainers
[Cowie](https://github.com/cowie)

## Contributing
<!--Give instructions on how to contribute to this repository. Where do I ask questions? Do you accept PRs? What are the requirements to contribute? Don't be a jerk. Use issues if you can.-->

Always looking for more usecases from anyone. Build ya code and add it in a pull req.
Oh if y'all want to do my test code for me too, it's cool. Just sayin'.

## License
[MIT](LICENSE) © CDG
