-- Make tier and score nullable in achievement table
ALTER TABLE `achievement` MODIFY COLUMN `tier` VARCHAR(50) NULL,
MODIFY COLUMN `score` INT NULL;

-- Add total achievement score to school table
ALTER TABLE `school` ADD COLUMN `total_achievement_score` INT NOT NULL DEFAULT 0;