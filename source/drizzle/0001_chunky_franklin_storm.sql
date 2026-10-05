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
--> statement-breakpoint
CREATE UNIQUE INDEX `weekly_resource_project_week` ON `weekly_allocations` (`resource_id`,`project_id`,`week`);