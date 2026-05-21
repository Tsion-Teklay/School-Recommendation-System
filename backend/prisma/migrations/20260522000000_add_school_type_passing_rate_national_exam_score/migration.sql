-- AlterTable
ALTER TABLE `school`
  ADD COLUMN `school_type` ENUM('private', 'government', 'church') NULL,
  ADD COLUMN `passing_rate` DECIMAL(5,2) NULL,
  ADD COLUMN `national_exam_score` DECIMAL(5,2) NULL;
