-- Phase 5 migration: forum + moderation typed actions.
--
-- 1. Extend `report.target_type` enum with FORUM_POST so users can report
--    forum posts in addition to schools/reviews/announcements.
-- 2. Extend `notification.source_type` with FORUM_POST + MODERATION so the
--    notification fan-out can reference forum posts and moderator actions
--    (e.g. WARN_USER / BAN_USER / REMOVE_CONTENT messages).
-- 3. Convert `moderator_action.action_type` from a free-form VARCHAR to a
--    typed enum. Existing rows are normalized to lowercase first; any value
--    that doesn't match the new enum is collapsed to `dismiss` (safe default
--    — DISMISS has no side effects on referenced content/users).

-- 1. report.target_type — add FORUM_POST
ALTER TABLE `report`
  MODIFY `target_type` ENUM('review', 'school', 'announcement', 'forum_post') NOT NULL;

-- 2. notification.source_type — add FORUM_POST + MODERATION
ALTER TABLE `notification`
  MODIFY `source_type` ENUM('announcement', 'report', 'review', 'school', 'system', 'forum_post', 'moderation') NOT NULL;

-- 3a. Normalize existing moderator_action rows so they fit the new enum.
UPDATE `moderator_action`
   SET `action_type` = LOWER(`action_type`);
UPDATE `moderator_action`
   SET `action_type` = 'dismiss'
 WHERE `action_type` NOT IN ('dismiss', 'remove_content', 'warn_user', 'ban_user');

-- 3b. Convert the column to the typed enum.
ALTER TABLE `moderator_action`
  MODIFY `action_type` ENUM('dismiss', 'remove_content', 'warn_user', 'ban_user') NOT NULL;
