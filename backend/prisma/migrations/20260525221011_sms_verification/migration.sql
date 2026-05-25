/*
  Warnings:

  - You are about to alter the column `tier` on the `achievement` table. The data in that column could be lost. The data in that column will be cast from `VarChar(50)` to `Enum(EnumId(17))`.
  - A unique constraint covering the columns `[phone_verification_token]` on the table `user` will be added. If there are existing duplicate values, this will fail.
  - Made the column `sub_city` on table `moe_officer` required. This step will fail if there are existing NULL values in that column.

*/
-- AlterTable
ALTER TABLE `achievement` MODIFY `tier` ENUM('gold', 'silver', 'bronze') NULL;

-- AlterTable
ALTER TABLE `moe_officer` MODIFY `sub_city` ENUM('addis_ketema', 'akali_kalti', 'arada', 'bole', 'gulele', 'kolfe_keranio', 'kirkos', 'lideta', 'nifas_silk_lafto', 'yekka') NOT NULL;

-- AlterTable
ALTER TABLE `school` MODIFY `latitude` DECIMAL(10, 8) NULL,
    MODIFY `longitude` DECIMAL(11, 8) NULL;

-- AlterTable
ALTER TABLE `user` ADD COLUMN `phone_verification_expires` DATETIME(3) NULL,
    ADD COLUMN `phone_verification_token` VARCHAR(128) NULL,
    ADD COLUMN `phone_verified` BOOLEAN NOT NULL DEFAULT false;

-- CreateIndex
CREATE UNIQUE INDEX `user_phone_verification_token_key` ON `user`(`phone_verification_token`);

-- RedefineIndex
CREATE INDEX `school_revoked_by_id_fkey` ON `school`(`revoked_by_id`);
DROP INDEX `school_revoked_by_id_idx` ON `school`;
