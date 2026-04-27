-- ----------------------------------------------------------------------
-- Phase 4: announcement.school_id + relation
--   Adds an optional FK from announcement -> school. Drives targeted
--   fan-out: SCHOOL_ADMIN announcements set this column and notify only
--   that school's subscribers; MoE announcements leave it NULL and
--   continue to broadcast to all parents.
-- ----------------------------------------------------------------------

-- AlterTable
ALTER TABLE `announcement` ADD COLUMN `school_id` INTEGER NULL;

-- CreateIndex
CREATE INDEX `announcement_school_id_idx` ON `announcement`(`school_id`);

-- AddForeignKey
ALTER TABLE `announcement` ADD CONSTRAINT `announcement_school_id_fkey` FOREIGN KEY (`school_id`) REFERENCES `school`(`school_id`) ON DELETE SET NULL ON UPDATE CASCADE;
