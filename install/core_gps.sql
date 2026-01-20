CREATE TABLE IF NOT EXISTS `core_gps_advanced` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `gps_id` varchar(100) NOT NULL,
    `label` varchar(100) NOT NULL,
    `coords` longtext NOT NULL,
    `street` varchar(255) DEFAULT NULL,
    `timestamp` bigint(20) DEFAULT NULL,
    `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
    PRIMARY KEY (`id`),
    KEY `gps_id` (`gps_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table for GPS device registry
CREATE TABLE IF NOT EXISTS `core_gps_advanced_devices` (
    `gps_id` varchar(100) NOT NULL,
    `allow_receive_locations` tinyint(1) NOT NULL DEFAULT 0,
    `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
    PRIMARY KEY (`gps_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
