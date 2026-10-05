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
--> statement-breakpoint
CREATE UNIQUE INDEX `allocations_resource_project_month` ON `allocations` (`resource_id`,`project_id`,`month`);--> statement-breakpoint
CREATE TABLE `capacity_adjustments` (
	`id` text PRIMARY KEY NOT NULL,
	`resource_id` text NOT NULL,
	`month` text NOT NULL,
	`leave_hours` real DEFAULT 0 NOT NULL,
	`capacity_override` real,
	FOREIGN KEY (`resource_id`) REFERENCES `resources`(`id`) ON UPDATE no action ON DELETE no action,
	FOREIGN KEY (`month`) REFERENCES `months`(`month`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE UNIQUE INDEX `capacity_resource_month` ON `capacity_adjustments` (`resource_id`,`month`);--> statement-breakpoint
CREATE TABLE `months` (
	`month` text PRIMARY KEY NOT NULL
);
--> statement-breakpoint
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
--> statement-breakpoint
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
--> statement-breakpoint
CREATE TABLE `settings` (
	`id` text PRIMARY KEY NOT NULL,
	`default_rate` real
);
