-- Gespeicherte Outfits (wird mit Config.AutoCreateTable auch automatisch angelegt)
CREATE TABLE IF NOT EXISTS `pulse_outfits` (
    `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(60)  NOT NULL,
    `name`       VARCHAR(24)  NOT NULL,
    `skin`       LONGTEXT     NOT NULL,
    `icons`      VARCHAR(255) NULL DEFAULT NULL,
    `created_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_identifier` (`identifier`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;
