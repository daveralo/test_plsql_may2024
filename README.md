# Solution Challenge PL/SQL
## Must Have
### Data Model
Please consider that your reply for each point should include an explanation and corresponding sql code 
1. Primary key definition and any other constraint or index suggestion

R/ I think it is necesary to create primary key all tables, because it identifies each row of a table. It gets a unique index for each primary key column that helps with faster access. Like this:

ALTER TABLE ITEM
ADD CONSTRAINT pk_item PRIMARY KEY (ITEM);

ALTER TABLE LOC
ADD CONSTRAINT pk_loc PRIMARY KEY (LOC);

ALTER TABLE ITEM_LOC_SOH
ADD CONSTRAINT pk_item_loc_soh PRIMARY KEY (ITEM,LOC);
(With this I had a problem, I got this error: 
ORA-01536: space quota exceeded for tablespace 'APEX_BIGFILE_INSTANCE_TBS2')

And it is also necessary to create foreign keys:

ALTER TABLE ITEM_LOC_SOH ADD CONSTRAINT ITEM_FK
Foreign Key (ITEM) REFERENCES ITEM (ITEM);

ALTER TABLE ITEM_LOC_SOH ADD CONSTRAINT LOC_FK
Foreign Key (LOC) REFERENCES LOC (LOC);

2. Your suggestion for table data management and data access considering the application usage, for example, partition...

R/ For large tables, for example, ITEM_LOC_SOH it can be useful to partition by LOC because accessing by LOC and having the data segmented allows for faster access.

3. Your suggestion to avoid row contention at table level parameter because of high level of concurrency

R/ For enviroments with many concurrent users submitting transactiones is a good idea to choice a isolation level like "Read Committed Isolation". The SET ISOLATION statement allows a user to change the isolation level for the user's connection.
You can also adjust the value of Initrans. Initrans is a physical attribute that determines the initial number of concurrent transaction entries allocated within each data block for a the table.

4. Create a view that can be used at screen level to show only the required fields

R/ Which are the required fields? I create this view with the fields that I think is good for an Item query.

CREATE VIEW itemsview AS 
SELECT i.Item, i.Item_Desc, l.Loc, l.Loc_Desc, ils.Dept, ils.Unit_Cost, ils.Stock_On_Hand
FROM ITEM i, LOC l, ITEM_LOC_SOH ils
WHERE i.Item = ils.Item
AND l.Loc = ils.Loc


5. Create a new table that associates user to existing dept(s)

R/ If a user can have several DEPTs it should be a table with a relationship from n to n:

create table USER_DEPT(
    user varchar2(25) not null,
    dept number(4) not null,
);

ALTER TABLE USER_DEPT
ADD CONSTRAINT pk_user_dept PRIMARY KEY (user,dept);

ALTER TABLE USER_DEPT ADD CONSTRAINT USER_DEPT_FK1
Foreign Key (USER) REFERENCES USER (USER);

ALTER TABLE USER_DEPT ADD CONSTRAINT USER_DEPT_FK2
Foreign Key (DEPT) REFERENCES DEPT (DEPT);


### PLSQL Development
6. Create a package with procedure or function that can be invoked by store or all stores to save the item_loc_soh to a new table that will contain the same information plus the stock value per item/loc (unit_cost*stock_on_hand)

R/ First I Created the table STOCKVALUE_PER_ITEMLOC

  CREATE TABLE "STOCKVALUE_PER_ITEMLOC" 
   (	"ITEM" VARCHAR2(25) NOT NULL ENABLE, 
	"LOC" NUMBER(10,0) NOT NULL ENABLE, 
	"DEPT" NUMBER(4,0) NOT NULL ENABLE, 
	"UNIT_COST" NUMBER(20,4) NOT NULL ENABLE, 
	"STOCK_ON_HAND" NUMBER(12,4) NOT NULL ENABLE,
    "STOCK_VALUE" NUMBER(22,4) NOT NULL ENABLE
   ) ;

  ALTER TABLE STOCKVALUE_PER_ITEMLOC
  ADD CONSTRAINT pk_stockvalue_per_itemloc PRIMARY KEY (ITEM,LOC);

  ALTER TABLE "STOCKVALUE_PER_ITEMLOC" ADD CONSTRAINT "ITEM_FK_2" FOREIGN KEY ("ITEM") REFERENCES "ITEM" ("ITEM") ENABLE;
  ALTER TABLE "STOCKVALUE_PER_ITEMLOC" ADD CONSTRAINT "LOC_FK_2" FOREIGN KEY ("LOC") REFERENCES "LOC" ("LOC") ENABLE;

The package code is located in the repository, the package is called PACK_ITEMS

7. Create a data filter mechanism that can be used at screen level to filter out the data that user can see accordingly to dept association (created previously)

R/ The question was not clear to me. However, I understand it as a query that filters only the DEPT items that the user has assigned, so it could be:

SELECT i.Item, i.Item_Desc, l.Loc, l.Loc_Desc, ils.Dept, ils.Unit_Cost, ils.Stock_On_Hand
FROM ITEM i, LOC l, ITEM_LOC_SOH ils
WHERE i.Item = ils.Item
AND l.Loc = ils.Loc
AND EXISTS(SELECT 1
           FROM USER_DEPT
           WHERE Dept = ils.Dept
           AND User = :p_user)

8. Create a pipeline function to be used in the location list of values (drop down)

R/  I created location_list function in the package PACK_ITEMS, and the way to execute is:

select * from TABLE(PACK_ITEMS.location_list())    

## Should Have
### Performance
9. Looking into the following explain plan what should be your recommendation and implementation to improve the existing data model. Please share your solution in sql and the corresponding explain plan of that solution. Please take in consideration the way that user will use the app.

R/ When I tried to generate explain plan I got error ORA-01536: space quota exceeded for tablespace 'APEX_BIGFILE_INSTANCE_TBS2'

But I think I would create an index by LOC and DEPT, because is one of the most frecuently query, and you put it in the Context:
 - the access to the application data is per store/warehouse
 - one of the attributes that most store/warehouse users search is by dept

 create index IDX1_ITEM_LOC_SOH on ITEM_LOC_SOH (LOC,DEPT);


 10. Run the previous method that was created on 6. for all the stores from item_loc_soh to the history table. The entire migration should not take more than 10s to run (don't use parallel hint to solve it :)) 

R/ At first I made a traditional Loop, then I changed it to BULK COLLECT to improve performance. BULK COLLECT reduces context switches between SQL and PL/SQL engine and allows SQL engine to fetch the records at once. And in transactions where we only have a cursor and an insert of the data it works very fast.

 11. Please have a look into the AWR report (AWR.html) in attachment and let us know what is the problem that the AWR is highlighting and potential solution.

R/ I don't have enough experience as a DBA or in a AWR report, but I generally met with the DBAs and we reviewed these types of reports and looked for solutions together, for example creating indexes, separating tablespaces, redoing programs, statistics on indexes or in tables, among others.


## Nice to have
### Performance
11. Create a program (plsql and/or java, or any other language) that can extract to a flat file (csv), 1 file per location: the item, department unit cost, stock on hand quantity and stock value.
Creating the 1000 files should take less than 30s.

R/ I created generate_files_per_location procedure in the package PACK_ITEMS.
I had problems generating files in the Workspace because I did not have permissions to use a directory, however I generated the program in PL/SQL.

