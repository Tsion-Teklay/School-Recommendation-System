-- AlterTable
ALTER TABLE `user` MODIFY `account_status` ENUM('active', 'deactivated', 'self_deactivated') NOT NULL DEFAULT 'active';
