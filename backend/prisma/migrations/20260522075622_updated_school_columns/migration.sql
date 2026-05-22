/*
  Warnings:

  - You are about to alter the column `target_id` on the `discussion_forum` table. The data in that column could be lost. The data in that column will be cast from `VarChar(191)` to `Int`.
  - The primary key for the `recommended_school` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - You are about to drop the column `recommended_school_id` on the `recommended_school` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE `discussion_forum` MODIFY `target_id` INTEGER NULL;

-- AlterTable
ALTER TABLE `recommendation_history` MODIFY `interaction_result` ENUM('opened', 'ignored', 'followed') NOT NULL;

-- AlterTable
ALTER TABLE `recommended_school` DROP PRIMARY KEY,
    DROP COLUMN `recommended_school_id`,
    ADD COLUMN `features` JSON NULL,
    ADD COLUMN `interactionResult` VARCHAR(191) NULL,
    ADD PRIMARY KEY (`recommendation_id`, `school_id`);
