/*
  Warnings:

  - You are about to drop the column `address` on the `school` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE `discussion_forum` ADD COLUMN `moderationStatus` VARCHAR(191) NOT NULL DEFAULT 'approved',
    ADD COLUMN `toxicityScore` DOUBLE NULL;

-- AlterTable
ALTER TABLE `moe_officer` ADD COLUMN `sub_city` ENUM('addis_ketema', 'akali_kalti', 'arada', 'bole', 'gulele', 'kolfe_keranio', 'kirkos', 'lideta', 'nifas_silk_lafto', 'yekka') NULL;

-- AlterTable
ALTER TABLE `recommendation_history` ADD COLUMN `features` JSON NULL;

-- AlterTable
ALTER TABLE `recommendation_preference_criteria` ADD COLUMN `school_level` ENUM('pre_primary', 'primary', 'secondary') NULL,
    ADD COLUMN `school_type` ENUM('private', 'government', 'church') NULL;

-- AlterTable
ALTER TABLE `school` DROP COLUMN `address`,
    ADD COLUMN `street_name` VARCHAR(100) NULL,
    ADD COLUMN `sub_city` VARCHAR(50) NULL,
    ADD COLUMN `woreda` VARCHAR(20) NULL;

-- CreateIndex
CREATE INDEX `moe_officer_sub_city_idx` ON `moe_officer`(`sub_city`);

-- CreateIndex
CREATE INDEX `school_sub_city_idx` ON `school`(`sub_city`);
