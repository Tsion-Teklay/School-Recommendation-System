-- AlterTable
ALTER TABLE `school` MODIFY `verification_status` ENUM('verified', 'pending', 'rejected', 'revoked') NOT NULL DEFAULT 'pending';
