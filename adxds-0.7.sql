-- MySQL Workbench Forward Engineering

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

-- -----------------------------------------------------
-- Schema adx-dw
-- -----------------------------------------------------

-- -----------------------------------------------------
-- Schema adx-dw
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `adx-dw` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci ;
USE `adx-dw` ;

-- -----------------------------------------------------
-- Table `adx-dw`.`event`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `adx-dw`.`event` ;

CREATE TABLE IF NOT EXISTS `adx-dw`.`event` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `ref` VARCHAR(100) NOT NULL COMMENT 'Reference given to the event',
  PRIMARY KEY (`id`))
ENGINE = InnoDB
COMMENT = 'Correlated observations are grouped into events';

CREATE UNIQUE INDEX `event_ref_UNIQUE` ON `adx-dw`.`event` (`ref` ASC);


-- -----------------------------------------------------
-- Table `adx-dw`.`obstype`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `adx-dw`.`obstype` ;

CREATE TABLE IF NOT EXISTS `adx-dw`.`obstype` (
  `id` TINYINT UNSIGNED NOT NULL,
  `label` VARCHAR(20) NOT NULL COMMENT 'Observation type’s code: LAND, AIR, SEA, SPACE,...',
  `description` VARCHAR(1000) NOT NULL COMMENT 'Small description of the observation type',
  PRIMARY KEY (`id`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = DEFAULT
COMMENT = 'Reference table containing available observation types';

CREATE UNIQUE INDEX `o_type_label_UNIQUE` ON `adx-dw`.`obstype` (`label` ASC);


-- -----------------------------------------------------
-- Table `adx-dw`.`obs`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `adx-dw`.`obs` ;

CREATE TABLE IF NOT EXISTS `adx-dw`.`obs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `obstype_id` TINYINT UNSIGNED NOT NULL COMMENT 'Observation type',
  `event_id` BIGINT UNSIGNED NULL COMMENT 'Related event',
  `start` TIMESTAMP NOT NULL COMMENT 'Start time of the observation',
  `end` TIMESTAMP NULL COMMENT 'End time of the observation',
  `narrative` VARCHAR(10000) NULL COMMENT 'Narrative of the observation by the observer or the sensor operator reporting the observation ',
  `inst_anomalies` VARCHAR(1000) NULL COMMENT 'Description of eventual instrumentation anomalies during the observation',
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_obs_obstype`
    FOREIGN KEY (`obstype_id`)
    REFERENCES `adx-dw`.`obstype` (`id`)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  CONSTRAINT `fk_obs_event`
    FOREIGN KEY (`event_id`)
    REFERENCES `adx-dw`.`event` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE)
ENGINE = InnoDB
COMMENT = 'Core entity in an ADX-DS system. Represents reported UAP observations of any kind';

CREATE INDEX `fk_obs_obstype_idx` ON `adx-dw`.`obs` (`obstype_id` ASC);

CREATE INDEX `fk_obs_event_idx` ON `adx-dw`.`obs` (`event_id` ASC);

CREATE INDEX `start_end_idx` ON `adx-dw`.`obs` (`start` ASC, `end` ASC);

CREATE INDEX `end_idx` ON `adx-dw`.`obs` (`end` ASC);


-- -----------------------------------------------------
-- Table `adx-dw`.`landobs_meta`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `adx-dw`.`landobs_meta` ;

CREATE TABLE IF NOT EXISTS `adx-dw`.`landobs_meta` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `obs_id` BIGINT UNSIGNED NOT NULL COMMENT 'Observation to which this data is related to',
  `lat` DOUBLE NOT NULL COMMENT 'Geographic latitude (in decimal degrees) of the observer',
  `lon` VARCHAR(100) NOT NULL COMMENT 'Geographic longitude (in decimal degrees) of the observer',
  `altitude` DOUBLE UNSIGNED NOT NULL COMMENT 'Altitude above sea level (in meters) of the observer',
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_landobs_obs`
    FOREIGN KEY (`obs_id`)
    REFERENCES `adx-dw`.`obs` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB
COMMENT = 'Metadata for a land observation, where observers remain still or incur in negligible displacement';

CREATE INDEX `fk_landobs_obs_idx` ON `adx-dw`.`landobs_meta` (`obs_id` ASC);


-- -----------------------------------------------------
-- Table `adx-dw`.`flight_type`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `adx-dw`.`flight_type` ;

CREATE TABLE IF NOT EXISTS `adx-dw`.`flight_type` (
  `id` TINYINT UNSIGNED NOT NULL,
  `label` VARCHAR(100) NOT NULL COMMENT 'Label of the flight type',
  PRIMARY KEY (`id`))
ENGINE = InnoDB
COMMENT = 'Reference table of flight types (commercial, military, freight, etc.)';

CREATE UNIQUE INDEX `flight_type_label_UNIQUE` ON `adx-dw`.`flight_type` (`label` ASC);


-- -----------------------------------------------------
-- Table `adx-dw`.`airobs_meta`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `adx-dw`.`airobs_meta` ;

CREATE TABLE IF NOT EXISTS `adx-dw`.`airobs_meta` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `obs_id` BIGINT UNSIGNED NOT NULL COMMENT 'Observation to which this data is related to',
  `type` TINYINT UNSIGNED NOT NULL COMMENT 'Type of operation ( civil / military / freight / passenger / special)',
  `aircraft` VARCHAR(100) NULL COMMENT 'Aircraft model and manufacturer',
  `tail_num` VARCHAR(100) NULL COMMENT 'Tail number of the aircraft',
  `operator` VARCHAR(100) NULL COMMENT 'Organization operating the aircraft if any',
  `flight_num` VARCHAR(100) NULL COMMENT 'Flight Number ',
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_airobs_obs`
    FOREIGN KEY (`obs_id`)
    REFERENCES `adx-dw`.`obs` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_airobs_flight_type`
    FOREIGN KEY (`type`)
    REFERENCES `adx-dw`.`flight_type` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB;

CREATE INDEX `fk_airobs_obs_idx` ON `adx-dw`.`airobs_meta` (`obs_id` ASC);

CREATE INDEX `fk_airobs_flight_type_idx` ON `adx-dw`.`airobs_meta` (`type` ASC);


-- -----------------------------------------------------
-- Table `adx-dw`.`seaobs_meta`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `adx-dw`.`seaobs_meta` ;

CREATE TABLE IF NOT EXISTS `adx-dw`.`seaobs_meta` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `obs_id` BIGINT UNSIGNED NOT NULL,
  `vessel_name` VARCHAR(100) NOT NULL,
  `country_flagged` VARCHAR(100) NOT NULL,
  `operator` VARCHAR(100) NOT NULL,
  `hin` VARCHAR(14) NULL COMMENT 'Hull Identification Number',
  `mmsi` CHAR(9) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_seaobs_obs`
    FOREIGN KEY (`obs_id`)
    REFERENCES `adx-dw`.`obs` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB;

CREATE INDEX `fk_seaobs_obs_idx` ON `adx-dw`.`seaobs_meta` (`obs_id` ASC);


-- -----------------------------------------------------
-- Table `adx-dw`.`spaceobs_meta`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `adx-dw`.`spaceobs_meta` ;

CREATE TABLE IF NOT EXISTS `adx-dw`.`spaceobs_meta` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `obs_id` BIGINT UNSIGNED NOT NULL,
  `spacecraft` POINT NOT NULL,
  `operator` VARCHAR(255) NOT NULL,
  `cospar_id` VARCHAR(255) NULL,
  `nssdca_id` VARCHAR(255) NULL,
  `tle` VARCHAR(100) NULL,
  `iod_file` BLOB NULL COMMENT 'IOD standard format to describe visual observation of satellite object',
  `ccsds_file` BLOB NULL COMMENT 'File for CCSD Format data files',
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_spaceobs_meta_obs1`
    FOREIGN KEY (`obs_id`)
    REFERENCES `adx-dw`.`obs` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB;

CREATE UNIQUE INDEX `id_UNIQUE` ON `adx-dw`.`spaceobs_meta` (`id` ASC);

CREATE INDEX `fk_spaceobs_obs_idx` ON `adx-dw`.`spaceobs_meta` (`obs_id` ASC);


-- -----------------------------------------------------
-- Table `adx-dw`.`observer`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `adx-dw`.`observer` ;

CREATE TABLE IF NOT EXISTS `adx-dw`.`observer` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `obs_id` BIGINT UNSIGNED NOT NULL COMMENT 'Id of the observation this observer is related to',
  `first_name` VARCHAR(100) NULL,
  `middle_name` CHAR(1) NULL,
  `last_name` VARCHAR(100) NULL,
  `yob` YEAR NULL,
  `education_level` VARCHAR(100) NULL COMMENT 'Highest level of education that the observer has acheived',
  `address` VARCHAR(500) NULL,
  `zip` VARCHAR(100) NULL,
  `city` VARCHAR(100) NULL,
  `state` VARCHAR(100) NULL,
  `country` VARCHAR(100) NULL COMMENT 'Country of residence',
  `individual` TINYINT UNSIGNED NULL DEFAULT 1 COMMENT 'Is the observer an individual not affiliated with an ADX partner organisation',
  `occupation` VARCHAR(100) NULL COMMENT 'Occupation of the observer',
  `years_of_experience` TINYINT UNSIGNED NULL COMMENT 'Years of experience in the occupation/role at the time of observation ',
  `position_title` VARCHAR(100) NULL COMMENT 'Title or rank of the observer at the time of the observation ',
  `organization` VARCHAR(100) NULL COMMENT 'Name of organization the observer belongs to',
  `organization_sub_group1` VARCHAR(100) NULL COMMENT 'Sub group (1) inside the organization',
  `organization_sub_group2` VARCHAR(100) NULL COMMENT 'Sub group (2) inside the organization',
  `trained_observer` TINYINT UNSIGNED NULL DEFAULT 0 COMMENT 'Has the observer been trained to identify anthropomorphic and natural phenomenon in their domain',
  `email` VARCHAR(320) NULL,
  `phone` VARCHAR(100) NULL,
  `supporting_doc` VARCHAR(100) NULL COMMENT 'Supporting documentation files around the credentials or contact information of the observer',
  `verified` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Has the identity of the observer been verified by ADX',
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_observer_obs`
    FOREIGN KEY (`obs_id`)
    REFERENCES `adx-dw`.`obs` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB
COMMENT = 'Demographic data about observers';

CREATE INDEX `fk_observer_obs_idx` ON `adx-dw`.`observer` (`obs_id` ASC);

CREATE INDEX `observer_organization_idx` ON `adx-dw`.`observer` (`organization`(50) ASC);

CREATE INDEX `observer_email_idx` ON `adx-dw`.`observer` (`email`(50) ASC);


-- -----------------------------------------------------
-- Table `adx-dw`.`object_shape`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `adx-dw`.`object_shape` ;

CREATE TABLE IF NOT EXISTS `adx-dw`.`object_shape` (
  `id` TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `label` VARCHAR(50) NOT NULL COMMENT 'Name of the shape',
  `description` VARCHAR(100) NOT NULL COMMENT 'Brief description of the shape',
  PRIMARY KEY (`id`))
ENGINE = InnoDB
COMMENT = 'Contains available object shapes';

CREATE UNIQUE INDEX `object_shape_label_UNIQUE` ON `adx-dw`.`object_shape` (`label` ASC);


-- -----------------------------------------------------
-- Table `adx-dw`.`object`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `adx-dw`.`object` ;

CREATE TABLE IF NOT EXISTS `adx-dw`.`object` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `obs_id` BIGINT UNSIGNED NOT NULL COMMENT 'Observation this object relates to',
  `shape_id` TINYINT UNSIGNED NOT NULL COMMENT 'Shape of the object, from the available shapes in object_shape table',
  `shape_desc` VARCHAR(1000) NULL COMMENT 'Description of the object\'s shape if not one in the object_shape table',
  `height` DOUBLE UNSIGNED NULL COMMENT 'Estimated height of the object (in meters) ',
  `length` DOUBLE UNSIGNED NULL COMMENT 'Estimated length of the object (in meters) ',
  `width` DOUBLE UNSIGNED NULL COMMENT 'Estimated width of the object (in meters) ',
  `color` VARCHAR(6) NULL COMMENT 'Perceived color of the object (in HEX notation)',
  `opacity` DOUBLE UNSIGNED NULL COMMENT 'Was the object opaque or transparent (percentage from 0 to 100) ',
  `luminosity` ENUM('0', '1', '2') NULL COMMENT 'Was the object emitting visible light (0=no light, 1=fade light, 2=bright light)',
  `light_pattern` VARCHAR(1000) NULL COMMENT 'Description of eventual light patterns (free text)',
  `surface` VARCHAR(1000) NULL COMMENT 'Description of the aspect of the surface (brilliant, matte, rugosity, dotted, metallic…)',
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_object_obs`
    FOREIGN KEY (`obs_id`)
    REFERENCES `adx-dw`.`obs` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_object_shape`
    FOREIGN KEY (`shape_id`)
    REFERENCES `adx-dw`.`object_shape` (`id`)
    ON DELETE RESTRICT
    ON UPDATE CASCADE)
ENGINE = InnoDB
COMMENT = 'Actual objects seen during observations';

CREATE INDEX `fk_object_obs_idx` ON `adx-dw`.`object` (`obs_id` ASC);

CREATE INDEX `fk_object_shape_idx` ON `adx-dw`.`object` (`shape_id` ASC);


-- -----------------------------------------------------
-- Table `adx-dw`.`object_tracking`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `adx-dw`.`object_tracking` ;

CREATE TABLE IF NOT EXISTS `adx-dw`.`object_tracking` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `object_id` BIGINT UNSIGNED NOT NULL COMMENT 'Position of the object relative to the observer at a given time',
  `time` DATETIME NOT NULL COMMENT 'Time of an object’s given position',
  `elevation` DOUBLE UNSIGNED NOT NULL COMMENT 'Elevation of the object (in decimal degrees) relative to the observer’s horizon [-90.0, 90.0]',
  `rel_bearing` DOUBLE UNSIGNED NULL COMMENT 'Bearing of the object (in decimal degrees) relative to the observer’s heading',
  `abs_bearing` DOUBLE NOT NULL COMMENT 'Magnetic or compass bearing (in decimal degrees) of the object',
  `lat` DOUBLE NULL,
  `lon` DOUBLE NULL,
  `altitude` DOUBLE NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_position_object`
    FOREIGN KEY (`object_id`)
    REFERENCES `adx-dw`.`object` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB;

CREATE INDEX `fk_position_object_idx` ON `adx-dw`.`object_tracking` (`object_id` ASC);

CREATE INDEX `tracking_time_idx` ON `adx-dw`.`object_tracking` (`time` ASC);


-- -----------------------------------------------------
-- Table `adx-dw`.`sensor_type`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `adx-dw`.`sensor_type` ;

CREATE TABLE IF NOT EXISTS `adx-dw`.`sensor_type` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `label` VARCHAR(100) NOT NULL,
  `description` VARCHAR(1000) NOT NULL COMMENT 'Reference table of available sensor types',
  PRIMARY KEY (`id`))
ENGINE = InnoDB
COMMENT = 'Reference table with sensor types';

CREATE UNIQUE INDEX `sensor_type_label_UNIQUE` ON `adx-dw`.`sensor_type` (`label` ASC);


-- -----------------------------------------------------
-- Table `adx-dw`.`sensor`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `adx-dw`.`sensor` ;

CREATE TABLE IF NOT EXISTS `adx-dw`.`sensor` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Sensors involved in observations',
  `sensor_type_id` BIGINT UNSIGNED NOT NULL COMMENT 'The sensor type provided in the sensor_type table',
  `model` VARCHAR(200) NOT NULL COMMENT 'Model of the sensor',
  `manufacturer` VARCHAR(200) NOT NULL COMMENT 'Manufacturer of the sensor',
  `operated_by` VARCHAR(200) NOT NULL COMMENT 'Entity operating the sensor',
  `serial_number` VARCHAR(200) NOT NULL COMMENT 'The serial number',
  `lat` DOUBLE NOT NULL COMMENT 'Geographic coordinates (in decimal degrees)',
  `lon` DOUBLE NOT NULL,
  `altitude` DOUBLE NOT NULL COMMENT 'Altitude above sea level (in meters)',
  `mobile` TINYINT UNSIGNED NOT NULL COMMENT 'Whether or not a sensor is mobile or portable',
  `range_min` DOUBLE UNSIGNED NULL COMMENT 'Minimum and maximum range ',
  `range_max` DOUBLE UNSIGNED NULL,
  `precision` VARCHAR(200) NULL,
  `other` VARCHAR(1000) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_sensor_sensor_type`
    FOREIGN KEY (`sensor_type_id`)
    REFERENCES `adx-dw`.`sensor_type` (`id`)
    ON DELETE RESTRICT
    ON UPDATE CASCADE)
ENGINE = InnoDB
COMMENT = 'List of sensors reporting output related to observations';

CREATE INDEX `fk_sensor_sensor_type_idx` ON `adx-dw`.`sensor` (`sensor_type_id` ASC);


-- -----------------------------------------------------
-- Table `adx-dw`.`sensor_output`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `adx-dw`.`sensor_output` ;

CREATE TABLE IF NOT EXISTS `adx-dw`.`sensor_output` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Output data from sensors collected during an observation',
  `obs_id` BIGINT UNSIGNED NOT NULL COMMENT 'Observation a sensor output relates to',
  `sensor_id` BIGINT UNSIGNED NOT NULL COMMENT 'Sensor providing the output',
  `output_format` VARCHAR(100) NOT NULL COMMENT 'Output format',
  `link` VARCHAR(500) NOT NULL COMMENT 'URL of the output file',
  `copyright` VARCHAR(300) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_sensor_output_sensor`
    FOREIGN KEY (`sensor_id`)
    REFERENCES `adx-dw`.`sensor` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_sensor_output_obs`
    FOREIGN KEY (`obs_id`)
    REFERENCES `adx-dw`.`obs` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB
COMMENT = 'Supporting files from sensors';

CREATE INDEX `fk_sensor_output_sensor_idx` ON `adx-dw`.`sensor_output` (`sensor_id` ASC);

CREATE INDEX `fk_sensor_output_obs_idx` ON `adx-dw`.`sensor_output` (`obs_id` ASC);


-- -----------------------------------------------------
-- Table `adx-dw`.`analysis`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `adx-dw`.`analysis` ;

CREATE TABLE IF NOT EXISTS `adx-dw`.`analysis` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `obs_id` BIGINT UNSIGNED NOT NULL COMMENT 'Observation related to the analysis',
  `organization` VARCHAR(100) NOT NULL COMMENT 'Organization that produced the analysis',
  `author` VARCHAR(200) NOT NULL COMMENT 'Authors of the analysis',
  `title` VARCHAR(200) NOT NULL COMMENT 'Title of the analysis',
  `publication` VARCHAR(200) NOT NULL COMMENT 'Name of the publication where the analysis was published ',
  `publication_date` DATE NOT NULL COMMENT 'Date of the original publication',
  `link` VARCHAR(200) NOT NULL COMMENT 'URL of the analysis file',
  `copyright` VARCHAR(300) NULL COMMENT 'copyright information regarding the analysis ',
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_analysis_obs`
    FOREIGN KEY (`obs_id`)
    REFERENCES `adx-dw`.`obs` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB
COMMENT = 'Published analysis related to an observation';

CREATE INDEX `fk_analysis_obs_idx` ON `adx-dw`.`analysis` (`obs_id` ASC);

CREATE INDEX `analysis_organization_idx` ON `adx-dw`.`analysis` (`organization` ASC);

CREATE INDEX `analysis_author_idx` ON `adx-dw`.`analysis` (`author` ASC, `publication_date` ASC);

CREATE INDEX `analysis_pubdate_idx` ON `adx-dw`.`analysis` (`publication_date` ASC);

CREATE INDEX `analysis_title_idx` ON `adx-dw`.`analysis` (`title` ASC);


-- -----------------------------------------------------
-- Table `adx-dw`.`weather_condition`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `adx-dw`.`weather_condition` ;

CREATE TABLE IF NOT EXISTS `adx-dw`.`weather_condition` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `obs_id` BIGINT UNSIGNED NOT NULL COMMENT 'Observation id',
  `visibility` SMALLINT UNSIGNED NULL COMMENT 'Estimated visibility, in m/s',
  `wind_speed` TINYINT UNSIGNED NULL COMMENT 'Wind speed in m/s',
  `wind_direction` SMALLINT UNSIGNED NULL COMMENT 'Wind direction represents the direction, in compass degrees, from which the wind originates',
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_weather_obs`
    FOREIGN KEY (`obs_id`)
    REFERENCES `adx-dw`.`obs` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB
COMMENT = 'Weather conditions at observation time';

CREATE INDEX `fk_weather_obs_idx` ON `adx-dw`.`weather_condition` (`obs_id` ASC);


-- -----------------------------------------------------
-- Table `adx-dw`.`meta_position`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `adx-dw`.`meta_position` ;

CREATE TABLE IF NOT EXISTS `adx-dw`.`meta_position` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `airobs_meta_id` BIGINT UNSIGNED NULL,
  `seaobs_meta_id` BIGINT UNSIGNED NULL,
  `time` DATETIME NOT NULL COMMENT 'Time of the position',
  `lat` DOUBLE NOT NULL COMMENT 'Latitude (in decimal degrees)',
  `lon` DOUBLE NOT NULL COMMENT 'Longitude (in decimal degrees)',
  `altitude` DOUBLE UNSIGNED NOT NULL COMMENT 'Altitude above sea level (in meters)',
  `heading` DOUBLE UNSIGNED NOT NULL COMMENT 'Aircraft compass bearing (in decimal degrees)',
  `ground_speed` DOUBLE UNSIGNED NOT NULL COMMENT 'Aircraft groundspeed',
  `sun_rel_bearing` DOUBLE NOT NULL COMMENT 'Relative bearing of the sun (in decimal degrees) regarding the aircraft heading',
  `sun_elevation` DOUBLE NOT NULL COMMENT 'Elevation of the sun (in decimal degrees) regarding the aircraft horizon',
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_position_airobs`
    FOREIGN KEY (`airobs_meta_id`)
    REFERENCES `adx-dw`.`airobs_meta` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_position_seaobs`
    FOREIGN KEY (`seaobs_meta_id`)
    REFERENCES `adx-dw`.`seaobs_meta` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB
COMMENT = 'Flight position at given instants in time';

CREATE INDEX `fk_position_airobs_idx` ON `adx-dw`.`meta_position` (`airobs_meta_id` ASC);

CREATE INDEX `fk_position_seaobs_idx` ON `adx-dw`.`meta_position` (`seaobs_meta_id` ASC);


-- -----------------------------------------------------
-- Table `adx-dw`.`attachment_type`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `adx-dw`.`attachment_type` ;

CREATE TABLE IF NOT EXISTS `adx-dw`.`attachment_type` (
  `id` TINYINT UNSIGNED NOT NULL,
  `label` VARCHAR(100) NOT NULL COMMENT 'Label of the available attachment types',
  PRIMARY KEY (`id`))
ENGINE = InnoDB
COMMENT = 'Reference table of available attachment types';

CREATE UNIQUE INDEX `attachment_label_UNIQUE` ON `adx-dw`.`attachment_type` (`label` ASC);


-- -----------------------------------------------------
-- Table `adx-dw`.`attachment`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `adx-dw`.`attachment` ;

CREATE TABLE IF NOT EXISTS `adx-dw`.`attachment` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `obs_id` BIGINT UNSIGNED NOT NULL,
  `attachment_type_id` TINYINT UNSIGNED NOT NULL,
  `data` BLOB NULL COMMENT 'Attachment data, if self contained in the database',
  `link` VARCHAR(1000) NULL COMMENT 'Link to the attachment data, if stored externally',
  `copyright` VARCHAR(300) NULL COMMENT 'Copyright owner',
  `license` VARCHAR(300) NULL COMMENT 'Applicable usage license',
  `credit` VARCHAR(300) NULL COMMENT 'Person or organization to give credit for the attachment. If blank, copyright owner should be given credit',
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_attachment_obs`
    FOREIGN KEY (`obs_id`)
    REFERENCES `adx-dw`.`obs` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_attachment_type`
    FOREIGN KEY (`attachment_type_id`)
    REFERENCES `adx-dw`.`attachment_type` (`id`)
    ON DELETE RESTRICT
    ON UPDATE CASCADE)
ENGINE = InnoDB
COMMENT = 'Any observation related attachments';

CREATE INDEX `fk_attachment_obs_idx` ON `adx-dw`.`attachment` (`obs_id` ASC);

CREATE INDEX `fk_attachment_type_idx` ON `adx-dw`.`attachment` (`attachment_type_id` ASC);


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
