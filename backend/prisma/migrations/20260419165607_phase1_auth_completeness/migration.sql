-- AlterTable
ALTER TABLE `user` ADD COLUMN `email_verification_expires` DATETIME(3) NULL,
    ADD COLUMN `email_verification_token` VARCHAR(128) NULL,
    ADD COLUMN `email_verified` BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN `password_reset_expires` DATETIME(3) NULL,
    ADD COLUMN `password_reset_token` VARCHAR(128) NULL,
    MODIFY `phone` VARCHAR(15) NULL;

-- CreateIndex
CREATE UNIQUE INDEX `user_email_verification_token_key` ON `user`(`email_verification_token`);

-- CreateIndex
CREATE UNIQUE INDEX `user_password_reset_token_key` ON `user`(`password_reset_token`);
