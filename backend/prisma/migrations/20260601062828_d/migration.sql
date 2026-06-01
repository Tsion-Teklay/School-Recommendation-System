-- AlterTable
ALTER TABLE `achievement` MODIFY `documents` LONGTEXT NULL;

-- AlterTable
ALTER TABLE `preference` MODIFY `min_budget` DECIMAL(10, 2) NULL,
    MODIFY `max_budget` DECIMAL(10, 2) NULL,
    MODIFY `curriculum` ENUM('local', 'international') NULL,
    MODIFY `distance` INTEGER NULL;

-- AlterTable
ALTER TABLE `recommendation_history` MODIFY `features` LONGTEXT NULL;

-- AlterTable
ALTER TABLE `recommended_school` MODIFY `features` LONGTEXT NULL;

-- AlterTable
ALTER TABLE `verification_request` MODIFY `documents` LONGTEXT NULL;
