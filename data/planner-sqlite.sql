CREATE TABLE `allocations` (
	`id` text PRIMARY KEY NOT NULL,
	`resource_id` text NOT NULL,
	`project_id` text NOT NULL,
	`month` text NOT NULL,
	`hours` real DEFAULT 0 NOT NULL,
	`actual` real,
	`notes` text DEFAULT '' NOT NULL,
	FOREIGN KEY (`resource_id`) REFERENCES `resources`(`id`) ON UPDATE no action ON DELETE no action,
	FOREIGN KEY (`project_id`) REFERENCES `projects`(`id`) ON UPDATE no action ON DELETE no action,
	FOREIGN KEY (`month`) REFERENCES `months`(`month`) ON UPDATE no action ON DELETE no action
);

CREATE UNIQUE INDEX `allocations_resource_project_month` ON `allocations` (`resource_id`,`project_id`,`month`);
CREATE TABLE `capacity_adjustments` (
	`id` text PRIMARY KEY NOT NULL,
	`resource_id` text NOT NULL,
	`month` text NOT NULL,
	`leave_hours` real DEFAULT 0 NOT NULL,
	`capacity_override` real,
	FOREIGN KEY (`resource_id`) REFERENCES `resources`(`id`) ON UPDATE no action ON DELETE no action,
	FOREIGN KEY (`month`) REFERENCES `months`(`month`) ON UPDATE no action ON DELETE no action
);

CREATE UNIQUE INDEX `capacity_resource_month` ON `capacity_adjustments` (`resource_id`,`month`);
CREATE TABLE `months` (
	`month` text PRIMARY KEY NOT NULL
);

CREATE TABLE `projects` (
	`id` text PRIMARY KEY NOT NULL,
	`name` text NOT NULL,
	`client` text DEFAULT '' NOT NULL,
	`manager` text DEFAULT '' NOT NULL,
	`start_date` text,
	`end_date` text,
	`budget` real,
	`rate` real,
	`billable` integer DEFAULT 1 NOT NULL,
	`status` text DEFAULT 'Active' NOT NULL,
	`notes` text DEFAULT '' NOT NULL
);

CREATE TABLE `resources` (
	`id` text PRIMARY KEY NOT NULL,
	`name` text NOT NULL,
	`role` text DEFAULT 'Delivery' NOT NULL,
	`location` text DEFAULT '' NOT NULL,
	`weekly_hours` real DEFAULT 40 NOT NULL,
	`goal` real DEFAULT 0.75 NOT NULL,
	`active` integer DEFAULT 1 NOT NULL,
	`eligible` integer DEFAULT 1 NOT NULL,
	`notes` text DEFAULT '' NOT NULL
);

CREATE TABLE `settings` (
	`id` text PRIMARY KEY NOT NULL,
	`default_rate` real
);

CREATE TABLE `weekly_allocations` (
	`id` text PRIMARY KEY NOT NULL,
	`resource_id` text NOT NULL,
	`project_id` text NOT NULL,
	`week` text NOT NULL,
	`hours` real DEFAULT 0 NOT NULL,
	`actual` real,
	`notes` text DEFAULT '' NOT NULL,
	FOREIGN KEY (`resource_id`) REFERENCES `resources`(`id`) ON UPDATE no action ON DELETE no action,
	FOREIGN KEY (`project_id`) REFERENCES `projects`(`id`) ON UPDATE no action ON DELETE no action
);

CREATE UNIQUE INDEX `weekly_resource_project_week` ON `weekly_allocations` (`resource_id`,`project_id`,`week`);
BEGIN TRANSACTION;
INSERT INTO resources (id,name,role,location,weekly_hours,goal,active,eligible,notes) VALUES ('R001','Simon','Delivery','',40,0.75,1,1,'Capacity assumed at 40 hours per week.');
INSERT INTO resources (id,name,role,location,weekly_hours,goal,active,eligible,notes) VALUES ('R002','Adam','Delivery','',40,0.75,1,1,'Capacity assumed at 40 hours per week.');
INSERT INTO resources (id,name,role,location,weekly_hours,goal,active,eligible,notes) VALUES ('R003','Vicky','Delivery','',40,0.75,1,1,'Capacity assumed at 40 hours per week.');
INSERT INTO resources (id,name,role,location,weekly_hours,goal,active,eligible,notes) VALUES ('R004','Cathi','Delivery','',40,0.75,1,1,'Capacity assumed at 40 hours per week.');
INSERT INTO resources (id,name,role,location,weekly_hours,goal,active,eligible,notes) VALUES ('R005','Wamik','Delivery','',40,0.75,1,1,'Capacity assumed at 40 hours per week.');
INSERT INTO resources (id,name,role,location,weekly_hours,goal,active,eligible,notes) VALUES ('R006','Sandeep','Delivery','',40,0.75,1,1,'Capacity assumed at 40 hours per week.');
INSERT INTO resources (id,name,role,location,weekly_hours,goal,active,eligible,notes) VALUES ('R007','Stefano','Delivery','',40,0.75,1,1,'Capacity assumed at 40 hours per week.');
INSERT INTO resources (id,name,role,location,weekly_hours,goal,active,eligible,notes) VALUES ('R008','Hail','Delivery','',40,0.75,1,1,'Capacity assumed at 40 hours per week.');
INSERT INTO resources (id,name,role,location,weekly_hours,goal,active,eligible,notes) VALUES ('R009','NEW BC','Delivery','',40,0.75,1,0,'Recruiting placeholder.');
INSERT INTO resources (id,name,role,location,weekly_hours,goal,active,eligible,notes) VALUES ('R010','Perry','Delivery','',20,0.75,1,1,'Capacity assumed at 40 hours per week.');
INSERT INTO resources (id,name,role,location,weekly_hours,goal,active,eligible,notes) VALUES ('R011','Vamshi','Delivery','',40,0.75,1,1,'Capacity assumed at 40 hours per week.');
INSERT INTO resources (id,name,role,location,weekly_hours,goal,active,eligible,notes) VALUES ('R012','Vashudha','Delivery','',40,0.75,1,1,'Capacity assumed at 40 hours per week.');
INSERT INTO resources (id,name,role,location,weekly_hours,goal,active,eligible,notes) VALUES ('R013','Arun','Delivery','',40,0.75,1,1,'Capacity assumed at 40 hours per week.');
INSERT INTO resources (id,name,role,location,weekly_hours,goal,active,eligible,notes) VALUES ('R014','Sanjoy','Delivery','',40,0.75,1,1,'Capacity assumed at 40 hours per week.');
INSERT INTO resources (id,name,role,location,weekly_hours,goal,active,eligible,notes) VALUES ('R015','Mahesh','Delivery','',40,0.75,1,1,'Capacity assumed at 40 hours per week.');
INSERT INTO resources (id,name,role,location,weekly_hours,goal,active,eligible,notes) VALUES ('R016','Lance','Delivery','',40,0.75,1,1,'Capacity assumed at 40 hours per week.');
INSERT INTO resources (id,name,role,location,weekly_hours,goal,active,eligible,notes) VALUES ('R017','Samuta','Delivery','',40,0.75,1,1,'Capacity assumed at 40 hours per week.');
INSERT INTO resources (id,name,role,location,weekly_hours,goal,active,eligible,notes) VALUES ('R018','Shameer','Delivery','',40,0.75,1,1,'Capacity assumed at 40 hours per week.');
INSERT INTO resources (id,name,role,location,weekly_hours,goal,active,eligible,notes) VALUES ('R019','Unassigned row 10','Delivery','',40,0.75,1,0,'Name absent in September screenshot. Confirm resource.');
INSERT INTO resources (id,name,role,location,weekly_hours,goal,active,eligible,notes) VALUES ('R020','Unassigned row 21','Delivery','',40,0.75,1,0,'Name absent in September screenshot. Confirm resource.');
INSERT INTO resources (id,name,role,location,weekly_hours,goal,active,eligible,notes) VALUES ('import-resource-kartheek','Kartheek','','',40,0.75,1,1,'Added from KnowERP_Utilization_WE 10102026.xlsx. Source utilization uses 40-hour weekly capacity; default 75% planning goal.');
INSERT INTO resources (id,name,role,location,weekly_hours,goal,active,eligible,notes) VALUES ('import-resource-vikrant','Vikrant','','',40,0.75,1,1,'Added from KnowERP_Utilization_WE 10102026.xlsx. Source utilization uses 40-hour weekly capacity; default 75% planning goal.');
INSERT INTO projects (id,name,client,manager,start_date,end_date,budget,rate,billable,status,notes) VALUES ('3c35cec2-5df5-4582-ae6c-bf8f26396c16','Infors','','','2026-10-01','2026-10-16',40,NULL,1,'Active','');
INSERT INTO projects (id,name,client,manager,start_date,end_date,budget,rate,billable,status,notes) VALUES ('432afd08-5446-4d9b-99e8-d7c51e6292c5','Macrobond','','','2026-09-29','2026-10-09',40,NULL,1,'Active','');
INSERT INTO projects (id,name,client,manager,start_date,end_date,budget,rate,billable,status,notes) VALUES ('P001','EASTERN','','','2026-09-14','2026-11-27',300,NULL,1,'Active','September reference. Dates and budgets need confirmation.');
INSERT INTO projects (id,name,client,manager,start_date,end_date,budget,rate,billable,status,notes) VALUES ('P002','JMP','','','2026-01-02','2027-01-01',200,NULL,1,'Active','September reference. Dates and budgets need confirmation.');
INSERT INTO projects (id,name,client,manager,start_date,end_date,budget,rate,billable,status,notes) VALUES ('P003','AsuraExt Spt','','','2026-08-03','2027-07-30',20,NULL,1,'Active','September reference. Dates and budgets need confirmation.');
INSERT INTO projects (id,name,client,manager,start_date,end_date,budget,rate,billable,status,notes) VALUES ('P004','Effiency','','','2026-07-02','2026-12-31',300,NULL,1,'Active','September reference. Dates and budgets need confirmation.');
INSERT INTO projects (id,name,client,manager,start_date,end_date,budget,rate,billable,status,notes) VALUES ('P005','Yakult','','',NULL,NULL,400,NULL,1,'Active','September reference. Dates and budgets need confirmation.');
INSERT INTO projects (id,name,client,manager,start_date,end_date,budget,rate,billable,status,notes) VALUES ('P006','BC Gains','','',NULL,NULL,100,NULL,1,'Active','September reference. Dates and budgets need confirmation.');
INSERT INTO projects (id,name,client,manager,start_date,end_date,budget,rate,billable,status,notes) VALUES ('P007','Simple Support','','',NULL,NULL,NULL,NULL,1,'Active','September reference. Dates and budgets need confirmation.');
INSERT INTO projects (id,name,client,manager,start_date,end_date,budget,rate,billable,status,notes) VALUES ('P008','OPC - BC','','',NULL,NULL,100,NULL,1,'Active','September reference. Dates and budgets need confirmation.');
INSERT INTO projects (id,name,client,manager,start_date,end_date,budget,rate,billable,status,notes) VALUES ('P009','Interpipe','','','2026-09-14','2026-10-23',160,NULL,1,'Active','September reference. Dates and budgets need confirmation.');
INSERT INTO projects (id,name,client,manager,start_date,end_date,budget,rate,billable,status,notes) VALUES ('a33366e8-5877-4fb3-b808-c04dd1808fb7','Buttara','','','2026-10-01','2026-10-30',60,NULL,1,'Active','');
INSERT INTO projects (id,name,client,manager,start_date,end_date,budget,rate,billable,status,notes) VALUES ('import-advanced-turf-20261005','Advanced Turf','','','2026-08-03','2026-10-30',120,NULL,1,'Active','Imported from KnowERP_Utilization_WE 10102026.xlsx. Development phase. Project dates were not supplied and need confirmation.');
INSERT INTO months (month) VALUES ('2026-01');
INSERT INTO months (month) VALUES ('2026-07');
INSERT INTO months (month) VALUES ('2026-08');
INSERT INTO months (month) VALUES ('2026-09');
INSERT INTO months (month) VALUES ('2026-10');
INSERT INTO months (month) VALUES ('2026-11');
INSERT INTO months (month) VALUES ('2026-12');
INSERT INTO months (month) VALUES ('2027-01');
INSERT INTO months (month) VALUES ('2027-07');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('A1','R001','P004','2026-09',12,NULL,'Imported September screenshot. Weekly hours are estimates.');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('A2','R001','P008','2026-09',20,NULL,'Imported September screenshot. Weekly hours are estimates.');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('A3','R002','P001','2026-09',60,NULL,'Imported September screenshot. Weekly hours are estimates.');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('A4','R002','P006','2026-09',20,NULL,'Imported September screenshot. Weekly hours are estimates.');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('A5','R003','P004','2026-09',60,NULL,'Imported September screenshot. Weekly hours are estimates.');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('A6','R003','P005','2026-09',40,NULL,'Imported September screenshot. Weekly hours are estimates.');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('A7','R003','P006','2026-09',20,NULL,'Imported September screenshot. Weekly hours are estimates.');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('A8','R004','P002','2026-09',40,NULL,'Imported September screenshot. Weekly hours are estimates.');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('A9','R004','P004','2026-09',80,NULL,'Imported September screenshot. Weekly hours are estimates.');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('A10','R005','P002','2026-09',10,NULL,'Imported September screenshot. Weekly hours are estimates.');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('A11','R005','P004','2026-09',40,NULL,'Imported September screenshot. Weekly hours are estimates.');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('A12','R006','P001','2026-09',20,NULL,'Imported September screenshot. Weekly hours are estimates.');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('A13','R006','P003','2026-09',40,NULL,'Imported September screenshot. Weekly hours are estimates.');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('A14','R006','P004','2026-09',40,NULL,'Imported September screenshot. Weekly hours are estimates.');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('A15','R006','P008','2026-09',40,NULL,'Imported September screenshot. Weekly hours are estimates.');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('A16','R008','P007','2026-09',20,NULL,'Imported September screenshot. Weekly hours are estimates.');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('A19','R010','P001','2026-09',20,NULL,'Imported September screenshot. Weekly hours are estimates.');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('A20','R010','P004','2026-09',20,NULL,'Imported September screenshot. Weekly hours are estimates.');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('A21','R010','P005','2026-09',20,NULL,'Imported September screenshot. Weekly hours are estimates.');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('A22','R010','P008','2026-09',10,NULL,'Imported September screenshot. Weekly hours are estimates.');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('A23','R012','P009','2026-09',80,NULL,'Imported September screenshot. Weekly hours are estimates.');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('A24','R014','P001','2026-09',40,NULL,'Imported September screenshot. Weekly hours are estimates.');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('A25','R014','P005','2026-09',100,NULL,'Imported September screenshot. Weekly hours are estimates.');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('A26','R014','P006','2026-09',40,NULL,'Imported September screenshot. Weekly hours are estimates.');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('A27','R014','P008','2026-09',80,NULL,'Imported September screenshot. Weekly hours are estimates.');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('A28','R015','P001','2026-09',80,NULL,'Imported September screenshot. Weekly hours are estimates.');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('A29','R015','P005','2026-09',80,NULL,'Imported September screenshot. Weekly hours are estimates.');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('A30','R018','P002','2026-09',80,NULL,'Imported September screenshot. Weekly hours are estimates.');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('A17','R019','P005','2026-09',40,NULL,'Imported September screenshot. Weekly hours are estimates.');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('A18','R019','P008','2026-09',80,NULL,'Imported September screenshot. Weekly hours are estimates.');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('A31','R020','P008','2026-09',60,NULL,'Imported September screenshot. Weekly hours are estimates.');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('f70b306e-977c-4496-9115-8a41b8c44641','R001','3c35cec2-5df5-4582-ae6c-bf8f26396c16','2026-10',20,NULL,'');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('b99c6e8c-667d-41f6-8088-0621c3c50889','R001','432afd08-5446-4d9b-99e8-d7c51e6292c5','2026-10',20,NULL,'');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('8b662288-bb2a-483f-a383-dd75d561fa42','R001','P004','2026-10',80,NULL,'');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('ed83b6ec-37e1-43de-a607-5a213778cb56','R002','a33366e8-5877-4fb3-b808-c04dd1808fb7','2026-10',10,NULL,'');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('cec663ae-ddfb-4ccc-9a67-dc02bd2802bc','R003','3c35cec2-5df5-4582-ae6c-bf8f26396c16','2026-10',6,NULL,'');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('42e6e6d7-94e7-40f8-a8f6-21f5eea4c03b','R003','432afd08-5446-4d9b-99e8-d7c51e6292c5','2026-10',6,NULL,'');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('a0b2255f-4555-4236-8520-fe088bf8dabd','R003','P001','2026-10',40,NULL,'');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('ed90c50d-9731-4cf7-8dd6-794e63f8481a','R003','P002','2026-10',20,NULL,'');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('b829adf8-d8a7-49e6-8d3b-37797b8beea2','R003','P004','2026-10',40,NULL,'');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('426f20c9-5e43-43aa-a237-d581af168f0b','R003','P005','2026-10',40,NULL,'');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('03032ce5-b872-4d9d-b6e0-b5737fdd381c','R003','P006','2026-10',10,NULL,'');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('822d536a-e974-463d-9542-38a702c2efd9','R003','P008','2026-10',10,NULL,'');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('4ef71660-3afd-4b93-a247-f93d543ac04d','R004','P002','2026-10',40,NULL,'');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('f0119ace-9056-4f25-b820-40bdfb5eb3ee','R004','P004','2026-10',60,NULL,'');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('3c5efa25-e239-4aad-8e91-e615040833c8','R005','P002','2026-10',40,NULL,'');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('3675a4be-b598-4419-8ba2-b07bf1e5b736','R005','P004','2026-10',40,NULL,'');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('eb67c958-753d-4e49-a41b-ab73b10b1feb','R005','P005','2026-10',40,NULL,'');
INSERT INTO allocations (id,resource_id,project_id,month,hours,actual,notes) VALUES ('290e8c99-51a4-48f8-abd9-0276c4b4f7f1','R015','P005','2026-10',160,NULL,'');
INSERT INTO settings (id,default_rate) VALUES ('default',145);
INSERT INTO weekly_allocations (id,resource_id,project_id,week,hours,actual,notes) VALUES ('1189e419-2a92-486c-84fa-7c045677ab7b','R003','3c35cec2-5df5-4582-ae6c-bf8f26396c16','2026-09-28',2,NULL,'');
INSERT INTO weekly_allocations (id,resource_id,project_id,week,hours,actual,notes) VALUES ('5d449489-ce41-4998-9b28-b2c542853eac','R003','P002','2026-09-28',10.75,NULL,'');
INSERT INTO weekly_allocations (id,resource_id,project_id,week,hours,actual,notes) VALUES ('80850da3-67a3-40c6-9397-cbcc210c49b3','R004','P002','2026-09-28',17.75,NULL,'');
INSERT INTO weekly_allocations (id,resource_id,project_id,week,hours,actual,notes) VALUES ('ddaf111c-e751-4be8-9dff-e032ee575837','R005','P002','2026-09-28',13.75,NULL,'');
INSERT INTO weekly_allocations (id,resource_id,project_id,week,hours,actual,notes) VALUES ('ddf1cfec-78e4-4dc0-b9a4-4f4319aa157d','R006','P002','2026-09-28',13.75,NULL,'');
INSERT INTO weekly_allocations (id,resource_id,project_id,week,hours,actual,notes) VALUES ('1bdc7f40-5432-4146-b865-97ff2a0d0092','R010','3c35cec2-5df5-4582-ae6c-bf8f26396c16','2026-09-28',1,NULL,'');
INSERT INTO weekly_allocations (id,resource_id,project_id,week,hours,actual,notes) VALUES ('a15d2a11-d15d-41a2-ac37-9ccf21855dd1','R014','432afd08-5446-4d9b-99e8-d7c51e6292c5','2026-09-28',20,NULL,'');
INSERT INTO weekly_allocations (id,resource_id,project_id,week,hours,actual,notes) VALUES ('26fc1f88-3f8b-4cdc-a9bf-925324794824','R016','3c35cec2-5df5-4582-ae6c-bf8f26396c16','2026-09-28',1.5,NULL,'');
INSERT INTO weekly_allocations (id,resource_id,project_id,week,hours,actual,notes) VALUES ('24f1c49b-f98d-4807-920e-719630e469bc','R001','3c35cec2-5df5-4582-ae6c-bf8f26396c16','2026-10-05',16.5,NULL,'Source: KnowERP_Utilization_WE 10102026.xlsx; week ending 2026-10-09.
3 - 1 Hour Working Sessions to cover the last of the topics (3 hrs)
Write Up of Topics covered WE 10/2/2026 (12 hrs)
Internal Review and Sign Off of Recommendations (1 hrs)
Daily Stand Up''s (0.5 hrs)');
INSERT INTO weekly_allocations (id,resource_id,project_id,week,hours,actual,notes) VALUES ('ab3cf576-83bf-4684-b8bc-0d58cdf96562','R001','P004','2026-10-05',7.75,NULL,'Source: KnowERP_Utilization_WE 10102026.xlsx; week ending 2026-10-09.
FDD''s - Expected back from the Client no later than 10/8/2026 - Anticipating Follow-up (1 hrs)
Requirements for Project - Tuesday (1 hrs)
Requirements for Service - Tuesday (1 hrs)
Draft & Internal review and sign off FDD for Project - Thursday (1 hrs)
Draft & Internal review and sign off FDD for Service - Thursday (1 hrs)
Blue Bison - Integration TDD (1 hrs)
Daily Stand Up''s (1.25 hrs)
Prep and Attend Client Status Meeting (0.5 hrs)');
INSERT INTO weekly_allocations (id,resource_id,project_id,week,hours,actual,notes) VALUES ('c01d17d9-fd33-4746-a01b-0380343d2091','R002','a33366e8-5877-4fb3-b808-c04dd1808fb7','2026-10-05',3,NULL,'Source: KnowERP_Utilization_WE 10102026.xlsx; week ending 2026-10-09.
Internal Review of Write and Compile Estimate (1 hrs)
PM (2 hrs)');
INSERT INTO weekly_allocations (id,resource_id,project_id,week,hours,actual,notes) VALUES ('e56809a1-c034-45f6-ad17-9bb105df7269','R003','3c35cec2-5df5-4582-ae6c-bf8f26396c16','2026-10-05',2,NULL,'Source: KnowERP_Utilization_WE 10102026.xlsx; week ending 2026-10-09.
Write Up of Topics covered WE 10/2/2026 (2 hrs)');
INSERT INTO weekly_allocations (id,resource_id,project_id,week,hours,actual,notes) VALUES ('f5e76d94-0024-4e50-a898-400c088ccf8f','R003','P001','2026-10-05',3.25,NULL,'Source: KnowERP_Utilization_WE 10102026.xlsx; week ending 2026-10-09.
Daily Stand Up''s (1.25 hrs)
Prep and Attend Client Status Meeting (2 hrs)');
INSERT INTO weekly_allocations (id,resource_id,project_id,week,hours,actual,notes) VALUES ('c57f99ce-f42b-431f-bad2-65ccdee093f0','R003','P002','2026-10-05',10.25,NULL,'Source: KnowERP_Utilization_WE 10102026.xlsx; week ending 2026-10-09.
Cut Over Planning (4 hrs)
Daily Stand Up''s (1.25 hrs)
Prep and Attend Client Status Meeting (2 hrs)
PM Time (3 hrs)');
INSERT INTO weekly_allocations (id,resource_id,project_id,week,hours,actual,notes) VALUES ('f19c72e0-ad65-4595-9d0e-942071016381','R003','P004','2026-10-05',8,NULL,'Source: KnowERP_Utilization_WE 10102026.xlsx; week ending 2026-10-09.
Prep and Attend Client Status Meeting (2 hrs)
PM Time (6 hrs)');
INSERT INTO weekly_allocations (id,resource_id,project_id,week,hours,actual,notes) VALUES ('a35c7c71-20af-4a3d-9391-6d716911f12f','R003','P005','2026-10-05',7.25,NULL,'Source: KnowERP_Utilization_WE 10102026.xlsx; week ending 2026-10-09.
Dialy Stand Ups (1.25 hrs)
Prep and Attend Client Status Meeting (2 hrs)
PM Time (4 hrs)');
INSERT INTO weekly_allocations (id,resource_id,project_id,week,hours,actual,notes) VALUES ('aac94c04-3b8b-4f9b-ae60-150b7fabda69','R003','P008','2026-10-05',5.25,NULL,'Source: KnowERP_Utilization_WE 10102026.xlsx; week ending 2026-10-09.
Daily Stand Ups (1.25 hrs)
Prep and Attend Client Status Meeting (2 hrs)
PM Time (2 hrs)');
INSERT INTO weekly_allocations (id,resource_id,project_id,week,hours,actual,notes) VALUES ('75f7018f-cbf1-4d26-84cc-b8362e48669d','R003','P009','2026-10-05',4.25,NULL,'Source: KnowERP_Utilization_WE 10102026.xlsx; week ending 2026-10-09.
Issue Resolution (2 hrs)
Daily Stand Ups (1.25 hrs)
PM - Status Report (1 hrs)');
INSERT INTO weekly_allocations (id,resource_id,project_id,week,hours,actual,notes) VALUES ('52dac3bc-04c8-44e8-b2d0-bfb080bfd7da','R003','a33366e8-5877-4fb3-b808-c04dd1808fb7','2026-10-05',5,NULL,'Source: KnowERP_Utilization_WE 10102026.xlsx; week ending 2026-10-09.
Vicky to write-up phase 2 from the recorded session (2 hrs)
Internal Review of Write and Compile Estimate (2 hrs)
PM (1 hrs)');
INSERT INTO weekly_allocations (id,resource_id,project_id,week,hours,actual,notes) VALUES ('fdeb1ae7-6f8f-492f-8388-33fb64f558e7','R003','import-advanced-turf-20261005','2026-10-05',3,NULL,'Source: KnowERP_Utilization_WE 10102026.xlsx; week ending 2026-10-09.
Internal Review Meeting (1 hrs)
Client Review Meeting and Sign Off (2 hrs)');
INSERT INTO weekly_allocations (id,resource_id,project_id,week,hours,actual,notes) VALUES ('ab33c1e5-28f3-418e-8588-bdec96f3d003','R004','P002','2026-10-05',17.75,NULL,'Source: KnowERP_Utilization_WE 10102026.xlsx; week ending 2026-10-09.
Bug - Functional Testing (4 hrs)
Punchlist Item Resolution (8 hrs)
Cut Over Planning (4 hrs)
Daily Stand Up''s (1.25 hrs)
Prep and Attend Client Status Meeting (0.5 hrs)');
INSERT INTO weekly_allocations (id,resource_id,project_id,week,hours,actual,notes) VALUES ('1b0ad5ae-fcbf-44f0-a97d-52c9df820558','R004','P004','2026-10-05',20.75,NULL,'Source: KnowERP_Utilization_WE 10102026.xlsx; week ending 2026-10-09.
FDD''s - Expected back from the Client no later than 10/8/2026 - Anticipating Follow-up (1 hrs)
Requirements for Project - Tuesday (1 hrs)
Requirements for Service - Tuesday (1 hrs)
Draft & Internal review and sign off FDD for Project - Thursday (3 hrs)
Draft & Internal review and sign off FDD for Service - Thursday (3 hrs)
Blue Bison - Integration TDD (2 hrs)
Prepare UAT Scripts (8 hrs)
Daily Stand Up''s (1.25 hrs)
Prep and Attend Client Status Meeting (0.5 hrs)');
INSERT INTO weekly_allocations (id,resource_id,project_id,week,hours,actual,notes) VALUES ('17716a7c-2f2d-4fa6-88b4-5d850bbf1ea9','R005','P002','2026-10-05',13.75,NULL,'Source: KnowERP_Utilization_WE 10102026.xlsx; week ending 2026-10-09.
Punchlist Item Resolution (8 hrs)
Cut Over Planning (4 hrs)
Daily Stand Up''s (1.25 hrs)
Prep and Attend Client Status Meeting (0.5 hrs)');
INSERT INTO weekly_allocations (id,resource_id,project_id,week,hours,actual,notes) VALUES ('feace5bd-2b76-46af-be58-c6185a03f885','R005','P005','2026-10-05',9.25,NULL,'Source: KnowERP_Utilization_WE 10102026.xlsx; week ending 2026-10-09.
Validate 2024, 2025 and 2026 data is ready for Client Review (4 hrs)
Validate the entire BC Environment is ready for UAT (2 hrs)
UAT with the Client and Sign Off (2 hrs)
Dialy Stand Ups (1.25 hrs)');
INSERT INTO weekly_allocations (id,resource_id,project_id,week,hours,actual,notes) VALUES ('df4153f4-520e-42f8-a2fe-b60eddee792b','R005','P008','2026-10-05',2.75,NULL,'Source: KnowERP_Utilization_WE 10102026.xlsx; week ending 2026-10-09.
Working session - Sign off on CRP; Review Cut Over Plan (1 hrs)
Daily Stand Ups (1.25 hrs)
Prep and Attend Client Status Meeting (0.5 hrs)');
INSERT INTO weekly_allocations (id,resource_id,project_id,week,hours,actual,notes) VALUES ('194702e2-4d8d-4921-917b-c7ca405c562d','R006','P001','2026-10-05',6.25,NULL,'Source: KnowERP_Utilization_WE 10102026.xlsx; week ending 2026-10-09.
Draft Agenda for this weeks Working Session on PO and SO (1 hrs)
Attend Working Session with Client (1 hrs)
Begin drafting FDD from the PO and SO working session (2 hrs)
Daily Stand Up''s (1.25 hrs)
Prep and Attend Client Status Meeting (1 hrs)');
INSERT INTO weekly_allocations (id,resource_id,project_id,week,hours,actual,notes) VALUES ('9ed4df87-5f7f-4d1e-ad16-baae81e2bcc7','R006','P002','2026-10-05',13.75,NULL,'Source: KnowERP_Utilization_WE 10102026.xlsx; week ending 2026-10-09.
Punchlist Item Resolution (8 hrs)
Cut Over Planning (4 hrs)
Daily Stand Up''s (1.25 hrs)
Prep and Attend Client Status Meeting (0.5 hrs)');
INSERT INTO weekly_allocations (id,resource_id,project_id,week,hours,actual,notes) VALUES ('35e95d15-0a34-4488-ad34-1fe86e4f10d0','R010','3c35cec2-5df5-4582-ae6c-bf8f26396c16','2026-10-05',1,NULL,'Source: KnowERP_Utilization_WE 10102026.xlsx; week ending 2026-10-09.
Internal Review and Sign Off of Recommendations (1 hrs)');
INSERT INTO weekly_allocations (id,resource_id,project_id,week,hours,actual,notes) VALUES ('dada2357-7d76-4b7d-9cb7-b9a357779f87','R010','P005','2026-10-05',2,NULL,'Source: KnowERP_Utilization_WE 10102026.xlsx; week ending 2026-10-09.
UAT with the Client and Sign Off (2 hrs)');
INSERT INTO weekly_allocations (id,resource_id,project_id,week,hours,actual,notes) VALUES ('6e88778b-2552-4639-bf2d-49d183eb6440','R010','a33366e8-5877-4fb3-b808-c04dd1808fb7','2026-10-05',1,NULL,'Source: KnowERP_Utilization_WE 10102026.xlsx; week ending 2026-10-09.
Internal Review of Write and Compile Estimate (1 hrs)');
INSERT INTO weekly_allocations (id,resource_id,project_id,week,hours,actual,notes) VALUES ('d1b463d3-911d-4537-997e-40e3779a20b0','R010','import-advanced-turf-20261005','2026-10-05',1,NULL,'Source: KnowERP_Utilization_WE 10102026.xlsx; week ending 2026-10-09.
Internal Review Meeting (1 hrs)');
INSERT INTO weekly_allocations (id,resource_id,project_id,week,hours,actual,notes) VALUES ('81497083-ee6a-4802-afb7-4c18e6120e48','R011','a33366e8-5877-4fb3-b808-c04dd1808fb7','2026-10-05',2,NULL,'Source: KnowERP_Utilization_WE 10102026.xlsx; week ending 2026-10-09.
Internal Review of Write and Compile Estimate (2 hrs)');
INSERT INTO weekly_allocations (id,resource_id,project_id,week,hours,actual,notes) VALUES ('e42f2b8d-946b-4ee2-932c-ea7c60781a21','R014','432afd08-5446-4d9b-99e8-d7c51e6292c5','2026-10-05',11.5,NULL,'Source: KnowERP_Utilization_WE 10102026.xlsx; week ending 2026-10-09.
Kickoff with Internal Team (0.5 hrs)
Coordinate Working Sessions - Collaborate on Agenda and Emails to Client to Schedule (1 hrs)
Prep and Attend Working Sessions (6 hrs)
Begin to draft Assessment Documents from Working session (4 hrs)');
INSERT INTO weekly_allocations (id,resource_id,project_id,week,hours,actual,notes) VALUES ('1fec671e-0ee2-4603-bbb0-8e8f942ccc5c','R014','P005','2026-10-05',13.25,NULL,'Source: KnowERP_Utilization_WE 10102026.xlsx; week ending 2026-10-09.
Complete User and Access Setup in Sandbox (4 hrs)
Validate 2024, 2025 and 2026 data is ready for Client Review (4 hrs)
Validate the entire BC Environment is ready for UAT (2 hrs)
UAT with the Client and Sign Off (2 hrs)
Dialy Stand Ups (1.25 hrs)');
INSERT INTO weekly_allocations (id,resource_id,project_id,week,hours,actual,notes) VALUES ('5d04defc-b05b-4945-bd3e-20efc2f102df','R014','import-advanced-turf-20261005','2026-10-05',19,NULL,'Source: KnowERP_Utilization_WE 10102026.xlsx; week ending 2026-10-09.
Snowflake Requirements and TDD (16 hrs)
Internal Review Meeting (1 hrs)
Client Review Meeting and Sign Off (2 hrs)');
INSERT INTO weekly_allocations (id,resource_id,project_id,week,hours,actual,notes) VALUES ('0120dbe4-f210-459c-9c52-f7065f9bdb01','R015','P008','2026-10-05',2.75,NULL,'Source: KnowERP_Utilization_WE 10102026.xlsx; week ending 2026-10-09.
Working session - Sign off on CRP; Review Cut Over Plan (1 hrs)
Daily Stand Ups (1.25 hrs)
Prep and Attend Client Status Meeting (0.5 hrs)');
INSERT INTO weekly_allocations (id,resource_id,project_id,week,hours,actual,notes) VALUES ('f3e4ac32-bd79-4816-9e99-56f433621894','R015','P009','2026-10-05',34.25,NULL,'Source: KnowERP_Utilization_WE 10102026.xlsx; week ending 2026-10-09.
Issue Resolution (32 hrs)
Daily Stand Ups (1.25 hrs)
PM - Status Report (1 hrs)');
INSERT INTO weekly_allocations (id,resource_id,project_id,week,hours,actual,notes) VALUES ('fbfcd9a4-c34b-40f1-865a-ec716aafefec','R016','3c35cec2-5df5-4582-ae6c-bf8f26396c16','2026-10-05',1.5,NULL,'Source: KnowERP_Utilization_WE 10102026.xlsx; week ending 2026-10-09.
Internal Review and Sign Off of Recommendations (1 hrs)
Daily Stand Up''s (0.5 hrs)');
INSERT INTO weekly_allocations (id,resource_id,project_id,week,hours,actual,notes) VALUES ('d88349ec-4ba7-4e7b-b33a-1ff49870fade','R016','432afd08-5446-4d9b-99e8-d7c51e6292c5','2026-10-05',4.5,NULL,'Source: KnowERP_Utilization_WE 10102026.xlsx; week ending 2026-10-09.
Setup the project in Planner (1 hrs)
Kickoff with Internal Team (1 hrs)
Coordinate Working Sessions - Collaborate on Agenda and Emails to Client to Schedule (1 hrs)
Daily Stand Ups (0.5 hrs)
PM - Status Report (1 hrs)');
INSERT INTO weekly_allocations (id,resource_id,project_id,week,hours,actual,notes) VALUES ('58480678-14b4-49c3-b894-224d53fb9d03','R018','P002','2026-10-05',12,NULL,'Source: KnowERP_Utilization_WE 10102026.xlsx; week ending 2026-10-09.
Bug - Assessment (4 hrs)
Bug - Fix and Technical Testing (8 hrs)');
INSERT INTO weekly_allocations (id,resource_id,project_id,week,hours,actual,notes) VALUES ('dd81e612-7e28-4187-95f2-85f354c34500','import-resource-kartheek','P008','2026-10-05',1.75,NULL,'Source: KnowERP_Utilization_WE 10102026.xlsx; week ending 2026-10-09.
Daily Stand Ups (1.25 hrs)
Prep and Attend Client Status Meeting (0.5 hrs)');
INSERT INTO weekly_allocations (id,resource_id,project_id,week,hours,actual,notes) VALUES ('9c85132a-d681-499c-9890-852be7c968b1','import-resource-vikrant','P001','2026-10-05',4.25,NULL,'Source: KnowERP_Utilization_WE 10102026.xlsx; week ending 2026-10-09.
Draft Agenda for this weeks Working Session on PO and SO (1 hrs)
Attend Working Session with Client (1 hrs)
Daily Stand Up''s (1.25 hrs)
Prep and Attend Client Status Meeting (1 hrs)');
COMMIT;
