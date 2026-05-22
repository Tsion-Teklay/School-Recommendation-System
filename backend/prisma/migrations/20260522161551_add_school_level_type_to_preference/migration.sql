-- AlterTable
ALTER TABLE `preference` ADD COLUMN `school_level` ENUM('pre_primary', 'primary', 'secondary') NULL,
    ADD COLUMN `school_type` ENUM('private', 'government', 'church') NULL;
