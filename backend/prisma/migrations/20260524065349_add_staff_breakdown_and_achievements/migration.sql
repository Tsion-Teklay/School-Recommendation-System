-- CreateTable
CREATE TABLE `staff_breakdown` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `school_id` INTEGER NOT NULL,
    `education_level` ENUM('phd', 'masters', 'degree', 'diploma', 'certificate') NOT NULL,
    `count` INTEGER NOT NULL,
    `updated_at` DATETIME(3) NOT NULL,

    INDEX `staff_breakdown_school_id_idx`(`school_id`),
    UNIQUE INDEX `staff_breakdown_school_id_education_level_key`(`school_id`, `education_level`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `achievement` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `school_id` INTEGER NOT NULL,
    `title` VARCHAR(150) NOT NULL,
    `description` TEXT NULL,
    `tier` ENUM('gold', 'silver', 'bronze') NOT NULL,
    `score` INTEGER NOT NULL,
    `year` INTEGER NOT NULL,
    `status` ENUM('pending', 'approved', 'rejected') NOT NULL DEFAULT 'pending',
    `documents` JSON NULL,
    `submitted_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `reviewed_at` DATETIME(3) NULL,
    `reviewed_by_id` INTEGER NULL,
    `review_notes` TEXT NULL,

    INDEX `achievement_school_id_idx`(`school_id`),
    INDEX `achievement_status_idx`(`status`),
    INDEX `achievement_year_idx`(`year`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `staff_breakdown` ADD CONSTRAINT `staff_breakdown_school_id_fkey` FOREIGN KEY (`school_id`) REFERENCES `school`(`school_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `achievement` ADD CONSTRAINT `achievement_school_id_fkey` FOREIGN KEY (`school_id`) REFERENCES `school`(`school_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `achievement` ADD CONSTRAINT `achievement_reviewed_by_id_fkey` FOREIGN KEY (`reviewed_by_id`) REFERENCES `user`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
