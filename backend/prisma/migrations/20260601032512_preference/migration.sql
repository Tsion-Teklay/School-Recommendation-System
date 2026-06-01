/*
  Warnings:

  - Made the column `parent_id` on table `preference` required. This step will fail if there are existing NULL values in that column.

*/
-- DropForeignKey
ALTER TABLE `preference` DROP FOREIGN KEY `preference_parent_id_fkey`;

-- AlterTable
ALTER TABLE `parent` MODIFY `latitude` DECIMAL(10, 8) NULL,
    MODIFY `longitude` DECIMAL(11, 8) NULL;

-- AlterTable
ALTER TABLE `preference` MODIFY `parent_id` INTEGER NOT NULL;

-- AddForeignKey
ALTER TABLE `preference` ADD CONSTRAINT `preference_parent_id_fkey` FOREIGN KEY (`parent_id`) REFERENCES `parent`(`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE;
