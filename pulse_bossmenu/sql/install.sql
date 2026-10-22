-- Wird beim Start auch automatisch angelegt.

CREATE TABLE IF NOT EXISTS `pulse_bossmenu_logs` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `job` VARCHAR(50) NOT NULL,
    `kind` VARCHAR(20) NOT NULL,
    `text` VARCHAR(255) NOT NULL,
    `who` VARCHAR(100) NULL DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`), KEY `idx_job` (`job`, `id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE IF NOT EXISTS `pulse_bossmenu_transactions` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `job` VARCHAR(50) NOT NULL,
    `type` ENUM('in', 'out') NOT NULL,
    `amount` INT UNSIGNED NOT NULL,
    `note` VARCHAR(100) NULL DEFAULT NULL,
    `who` VARCHAR(100) NULL DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`), KEY `idx_job` (`job`, `id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE IF NOT EXISTS `pulse_bossmenu_settings` (
    `job` VARCHAR(50) NOT NULL,
    `data` LONGTEXT NOT NULL,
    PRIMARY KEY (`job`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE IF NOT EXISTS `pulse_bossmenu_members` (
    `identifier` VARCHAR(60) NOT NULL,
    `job` VARCHAR(50) NOT NULL,
    `hired_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`identifier`, `job`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE IF NOT EXISTS `pulse_bossmenu_locations` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `job` VARCHAR(50) NOT NULL,
    `x` FLOAT NOT NULL,
    `y` FLOAT NOT NULL,
    `z` FLOAT NOT NULL,
    `created_by` VARCHAR(100) NULL DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`), KEY `idx_job` (`job`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;
