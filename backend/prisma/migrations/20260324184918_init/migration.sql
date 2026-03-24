-- CreateTable
CREATE TABLE `user` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `full_name` VARCHAR(100) NOT NULL,
    `email` VARCHAR(100) NOT NULL,
    `phone` VARCHAR(15) NOT NULL,
    `password` VARCHAR(255) NOT NULL,
    `account_status` ENUM('active', 'deactivated') NOT NULL DEFAULT 'active',
    `role` ENUM('parent', 'school_admin', 'moe_officer', 'moderator') NOT NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    UNIQUE INDEX `user_email_key`(`email`),
    UNIQUE INDEX `user_phone_key`(`phone`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `school` (
    `school_id` INTEGER NOT NULL AUTO_INCREMENT,
    `admin_id` INTEGER NOT NULL,
    `school_name` VARCHAR(150) NOT NULL,
    `address` VARCHAR(255) NOT NULL,
    `contact_email` VARCHAR(100) NOT NULL,
    `contact_phone` VARCHAR(15) NOT NULL,
    `curriculum` ENUM('local', 'international') NOT NULL,
    `tuition_fee` DECIMAL(10, 2) NOT NULL,
    `facilities` TEXT NULL,
    `verification_status` ENUM('verified', 'pending', 'rejected') NOT NULL DEFAULT 'pending',
    `latitude` DECIMAL(10, 8) NOT NULL,
    `longitude` DECIMAL(11, 8) NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    INDEX `school_school_name_idx`(`school_name`),
    INDEX `school_curriculum_idx`(`curriculum`),
    INDEX `school_verification_status_idx`(`verification_status`),
    PRIMARY KEY (`school_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `review` (
    `review_id` INTEGER NOT NULL AUTO_INCREMENT,
    `parent_id` INTEGER NOT NULL,
    `school_id` INTEGER NOT NULL,
    `rating` INTEGER NOT NULL,
    `comment` TEXT NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,
    `category_tag` ENUM('safety', 'teaching_quality', 'other') NOT NULL,

    PRIMARY KEY (`review_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `announcement` (
    `announcement_id` INTEGER NOT NULL AUTO_INCREMENT,
    `publisher_id` INTEGER NOT NULL,
    `publisher_type` ENUM('moe', 'school_admin') NOT NULL,
    `title` VARCHAR(150) NOT NULL,
    `content` TEXT NOT NULL,
    `img_url` VARCHAR(255) NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,
    `category` ENUM('admissions', 'policy', 'fee', 'other') NOT NULL,
    `attachments` VARCHAR(255) NULL,
    `date_posted` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `urgency_level` ENUM('normal', 'high', 'emergency') NOT NULL DEFAULT 'normal',

    PRIMARY KEY (`announcement_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `report` (
    `report_id` INTEGER NOT NULL AUTO_INCREMENT,
    `reporter_id` INTEGER NOT NULL,
    `target_type` ENUM('review', 'school', 'announcement') NOT NULL,
    `target_id` INTEGER NOT NULL,
    `reason` VARCHAR(255) NOT NULL,
    `status` ENUM('pending', 'reviewed', 'resolved') NOT NULL DEFAULT 'pending',
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    PRIMARY KEY (`report_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `parent` (
    `user_id` INTEGER NOT NULL,
    `address` VARCHAR(255) NOT NULL,
    `latitude` DECIMAL(10, 8) NOT NULL,
    `longitude` DECIMAL(11, 8) NOT NULL,

    PRIMARY KEY (`user_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `facility_images` (
    `facility_image_id` INTEGER NOT NULL AUTO_INCREMENT,
    `school_id` INTEGER NOT NULL,
    `image_url` VARCHAR(255) NOT NULL,

    PRIMARY KEY (`facility_image_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `moe_officer` (
    `user_id` INTEGER NOT NULL,
    `officer_role` VARCHAR(255) NOT NULL,

    PRIMARY KEY (`user_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `discussion_forum` (
    `post_id` INTEGER NOT NULL AUTO_INCREMENT,
    `author_id` INTEGER NOT NULL,
    `content` TEXT NOT NULL,
    `timestamp` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `thread_id` INTEGER NULL,
    `is_edited` BOOLEAN NOT NULL DEFAULT false,

    PRIMARY KEY (`post_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `favorite` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `parent_id` INTEGER NOT NULL,
    `school_id` INTEGER NOT NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `favorite_parent_id_school_id_key`(`parent_id`, `school_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `recommendation_history` (
    `recommendation_id` INTEGER NOT NULL AUTO_INCREMENT,
    `parent_id` INTEGER NOT NULL,
    `generated_on` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `interaction_result` ENUM('opened', 'ignored') NOT NULL,

    PRIMARY KEY (`recommendation_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `comparison` (
    `comparison_id` INTEGER NOT NULL AUTO_INCREMENT,
    `parent_id` INTEGER NOT NULL,
    `metrics_used` TEXT NOT NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    PRIMARY KEY (`comparison_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `analytics` (
    `data_id` INTEGER NOT NULL AUTO_INCREMENT,
    `school_id` INTEGER NOT NULL,
    `metric_type` VARCHAR(255) NOT NULL,
    `metric_value` DECIMAL(10, 2) NOT NULL,
    `academic_year` INTEGER NOT NULL,
    `source` VARCHAR(255) NOT NULL,

    PRIMARY KEY (`data_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `moderator_action` (
    `action_id` INTEGER NOT NULL AUTO_INCREMENT,
    `moderator_id` INTEGER NOT NULL,
    `report_id` INTEGER NOT NULL,
    `action_type` VARCHAR(255) NOT NULL,
    `notes` TEXT NULL,
    `action_date` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    PRIMARY KEY (`action_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `notification` (
    `notification_id` INTEGER NOT NULL AUTO_INCREMENT,
    `recipient_id` INTEGER NOT NULL,
    `recipient_type` ENUM('parent', 'school_admin', 'moe') NOT NULL,
    `message` TEXT NOT NULL,
    `source_type` VARCHAR(191) NOT NULL,
    `source_id` INTEGER NOT NULL,
    `is_read` BOOLEAN NOT NULL DEFAULT false,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `notification_recipient_id_idx`(`recipient_id`),
    PRIMARY KEY (`notification_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `school_update` (
    `update_id` INTEGER NOT NULL AUTO_INCREMENT,
    `school_id` INTEGER NOT NULL,
    `title` VARCHAR(255) NOT NULL,
    `description` TEXT NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    PRIMARY KEY (`update_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `preference` (
    `preference_id` INTEGER NOT NULL AUTO_INCREMENT,
    `parent_id` INTEGER NOT NULL,
    `min_budget` DECIMAL(10, 2) NOT NULL,
    `max_budget` DECIMAL(10, 2) NOT NULL,
    `curriculum` ENUM('local', 'international') NOT NULL,
    `distance` INTEGER NOT NULL,

    UNIQUE INDEX `preference_parent_id_key`(`parent_id`),
    PRIMARY KEY (`preference_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `recommended_school` (
    `recommended_school_id` INTEGER NOT NULL AUTO_INCREMENT,
    `recommendation_id` INTEGER NOT NULL,
    `school_id` INTEGER NOT NULL,

    PRIMARY KEY (`recommended_school_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `recommendation_preference_criteria` (
    `preference_criteria_id` INTEGER NOT NULL AUTO_INCREMENT,
    `recommendation_id` INTEGER NOT NULL,
    `min_budget` DECIMAL(10, 2) NOT NULL,
    `max_budget` DECIMAL(10, 2) NOT NULL,
    `curriculum` ENUM('local', 'international') NOT NULL,
    `distance` INTEGER NOT NULL,

    PRIMARY KEY (`preference_criteria_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `comparison_school` (
    `comparison_school_id` INTEGER NOT NULL AUTO_INCREMENT,
    `comparison_id` INTEGER NOT NULL,
    `school_id` INTEGER NOT NULL,

    PRIMARY KEY (`comparison_school_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `school` ADD CONSTRAINT `school_admin_id_fkey` FOREIGN KEY (`admin_id`) REFERENCES `user`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `review` ADD CONSTRAINT `review_parent_id_fkey` FOREIGN KEY (`parent_id`) REFERENCES `user`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `review` ADD CONSTRAINT `review_school_id_fkey` FOREIGN KEY (`school_id`) REFERENCES `school`(`school_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `announcement` ADD CONSTRAINT `announcement_publisher_id_fkey` FOREIGN KEY (`publisher_id`) REFERENCES `user`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `report` ADD CONSTRAINT `report_reporter_id_fkey` FOREIGN KEY (`reporter_id`) REFERENCES `user`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `parent` ADD CONSTRAINT `parent_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `user`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `facility_images` ADD CONSTRAINT `facility_images_school_id_fkey` FOREIGN KEY (`school_id`) REFERENCES `school`(`school_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `moe_officer` ADD CONSTRAINT `moe_officer_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `user`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `discussion_forum` ADD CONSTRAINT `discussion_forum_author_id_fkey` FOREIGN KEY (`author_id`) REFERENCES `user`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `discussion_forum` ADD CONSTRAINT `discussion_forum_thread_id_fkey` FOREIGN KEY (`thread_id`) REFERENCES `discussion_forum`(`post_id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `favorite` ADD CONSTRAINT `favorite_parent_id_fkey` FOREIGN KEY (`parent_id`) REFERENCES `user`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `favorite` ADD CONSTRAINT `favorite_school_id_fkey` FOREIGN KEY (`school_id`) REFERENCES `school`(`school_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `recommendation_history` ADD CONSTRAINT `recommendation_history_parent_id_fkey` FOREIGN KEY (`parent_id`) REFERENCES `user`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `comparison` ADD CONSTRAINT `comparison_parent_id_fkey` FOREIGN KEY (`parent_id`) REFERENCES `user`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `analytics` ADD CONSTRAINT `analytics_school_id_fkey` FOREIGN KEY (`school_id`) REFERENCES `school`(`school_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `moderator_action` ADD CONSTRAINT `moderator_action_moderator_id_fkey` FOREIGN KEY (`moderator_id`) REFERENCES `user`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `moderator_action` ADD CONSTRAINT `moderator_action_report_id_fkey` FOREIGN KEY (`report_id`) REFERENCES `report`(`report_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `notification` ADD CONSTRAINT `notification_recipient_id_fkey` FOREIGN KEY (`recipient_id`) REFERENCES `user`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `school_update` ADD CONSTRAINT `school_update_school_id_fkey` FOREIGN KEY (`school_id`) REFERENCES `school`(`school_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `preference` ADD CONSTRAINT `preference_parent_id_fkey` FOREIGN KEY (`parent_id`) REFERENCES `parent`(`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `recommended_school` ADD CONSTRAINT `recommended_school_recommendation_id_fkey` FOREIGN KEY (`recommendation_id`) REFERENCES `recommendation_history`(`recommendation_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `recommended_school` ADD CONSTRAINT `recommended_school_school_id_fkey` FOREIGN KEY (`school_id`) REFERENCES `school`(`school_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `recommendation_preference_criteria` ADD CONSTRAINT `recommendation_preference_criteria_recommendation_id_fkey` FOREIGN KEY (`recommendation_id`) REFERENCES `recommendation_history`(`recommendation_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `comparison_school` ADD CONSTRAINT `comparison_school_comparison_id_fkey` FOREIGN KEY (`comparison_id`) REFERENCES `comparison`(`comparison_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `comparison_school` ADD CONSTRAINT `comparison_school_school_id_fkey` FOREIGN KEY (`school_id`) REFERENCES `school`(`school_id`) ON DELETE RESTRICT ON UPDATE CASCADE;
