-- ----------------------------------------------------------------------
-- Phase 2: schema hardening
--   * Notification.source_type String -> NotificationSourceType enum
--   * ReviewCategoryTag: add FACILITIES + AFFORDABILITY
--   * School: rating + review_count aggregates (Phase 2 wires these to
--     review CRUD; service code does the recompute)
--   * New tables: subscription, verification_request
-- ----------------------------------------------------------------------

-- Existing rows used uppercase strings ("ANNOUNCEMENT", "REPORT"); the new
-- enum stores lowercase values via @map. Lowercase before the column type
-- change so the ALTER doesn't reject existing rows.
UPDATE `notification` SET `source_type` = LOWER(`source_type`);

-- AlterTable
ALTER TABLE `notification` MODIFY `source_type` ENUM('announcement', 'report', 'review', 'school', 'system') NOT NULL;

-- AlterTable
ALTER TABLE `review` MODIFY `category_tag` ENUM('safety', 'teaching_quality', 'facilities', 'affordability', 'other') NOT NULL;

-- AlterTable
ALTER TABLE `school` ADD COLUMN `rating` DECIMAL(3, 2) NOT NULL DEFAULT 0,
    ADD COLUMN `review_count` INTEGER NOT NULL DEFAULT 0;

-- CreateTable
CREATE TABLE `subscription` (
    `subscription_id` INTEGER NOT NULL AUTO_INCREMENT,
    `parent_id` INTEGER NOT NULL,
    `school_id` INTEGER NOT NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `subscription_school_id_idx`(`school_id`),
    UNIQUE INDEX `subscription_parent_id_school_id_key`(`parent_id`, `school_id`),
    PRIMARY KEY (`subscription_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `verification_request` (
    `verification_request_id` INTEGER NOT NULL AUTO_INCREMENT,
    `school_id` INTEGER NOT NULL,
    `submitted_by_id` INTEGER NOT NULL,
    `reviewed_by_id` INTEGER NULL,
    `status` ENUM('pending', 'approved', 'rejected') NOT NULL DEFAULT 'pending',
    `documents` JSON NULL,
    `notes` TEXT NULL,
    `review_notes` TEXT NULL,
    `submitted_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `reviewed_at` DATETIME(3) NULL,

    INDEX `verification_request_school_id_idx`(`school_id`),
    INDEX `verification_request_status_idx`(`status`),
    PRIMARY KEY (`verification_request_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `subscription` ADD CONSTRAINT `subscription_parent_id_fkey` FOREIGN KEY (`parent_id`) REFERENCES `user`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `subscription` ADD CONSTRAINT `subscription_school_id_fkey` FOREIGN KEY (`school_id`) REFERENCES `school`(`school_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `verification_request` ADD CONSTRAINT `verification_request_school_id_fkey` FOREIGN KEY (`school_id`) REFERENCES `school`(`school_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `verification_request` ADD CONSTRAINT `verification_request_submitted_by_id_fkey` FOREIGN KEY (`submitted_by_id`) REFERENCES `user`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `verification_request` ADD CONSTRAINT `verification_request_reviewed_by_id_fkey` FOREIGN KEY (`reviewed_by_id`) REFERENCES `user`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
