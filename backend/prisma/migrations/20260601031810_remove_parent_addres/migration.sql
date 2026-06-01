-- DropForeignKey
ALTER TABLE `preference` DROP FOREIGN KEY `preference_parent_id_fkey`;

-- AlterTable
ALTER TABLE `preference` MODIFY `parent_id` INTEGER NULL;

-- AddForeignKey
ALTER TABLE `preference` ADD CONSTRAINT `preference_parent_id_fkey` FOREIGN KEY (`parent_id`) REFERENCES `parent`(`user_id`) ON DELETE SET NULL ON UPDATE CASCADE;
