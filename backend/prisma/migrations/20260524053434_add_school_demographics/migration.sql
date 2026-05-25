/*
  Warnings:

  - You are about to drop the column `national_exam_score` on the `school` table. All the data in the column will be lost.
  - You are about to drop the column `passing_rate` on the `school` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE `school` DROP COLUMN `national_exam_score`,
    DROP COLUMN `passing_rate`;

-- CreateTable
CREATE TABLE `school_demographics` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `school_id` INTEGER NOT NULL,
    `academic_year` INTEGER NOT NULL,
    `total_students` INTEGER NOT NULL,
    `girls_count` INTEGER NOT NULL,
    `boys_count` INTEGER NOT NULL,
    `passing_rate` DECIMAL(5, 2) NOT NULL,
    `national_exam_score` DECIMAL(5, 2) NOT NULL,
    `submitted_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `school_demographics_school_id_idx`(`school_id`),
    INDEX `school_demographics_academic_year_idx`(`academic_year`),
    UNIQUE INDEX `school_demographics_school_id_academic_year_key`(`school_id`, `academic_year`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `school_demographics` ADD CONSTRAINT `school_demographics_school_id_fkey` FOREIGN KEY (`school_id`) REFERENCES `school`(`school_id`) ON DELETE RESTRICT ON UPDATE CASCADE;
