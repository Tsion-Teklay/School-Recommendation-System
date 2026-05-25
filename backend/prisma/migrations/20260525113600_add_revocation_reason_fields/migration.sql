-- Add revocation reason fields to school table
ALTER TABLE `school` ADD COLUMN `revoked_at` DATETIME(3) NULL,
ADD COLUMN `revoked_by_id` INT NULL,
ADD COLUMN `revocation_reason` TEXT NULL;

-- Add foreign key constraint for revoked_by_id
ALTER TABLE `school` ADD CONSTRAINT `school_revoked_by_id_fkey` FOREIGN KEY (`revoked_by_id`) REFERENCES `user`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- Add index for revoked_by_id for performance
CREATE INDEX `school_revoked_by_id_idx` ON `school`(`revoked_by_id`);