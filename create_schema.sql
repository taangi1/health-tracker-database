PRAGMA foreign_keys = ON; -- Enable referential integrity

-- DROP TABLE goals;
-- DROP TABLE exercises_log;
-- DROP TABLE exercise_type;
-- DROP TABLE metrics_log;
-- DROP TABLE metric_type;
-- DROP TABLE users;
-- DROP TABLE devices;

CREATE TABLE users (
  -- PK
  user_id INTEGER PRIMARY KEY AUTOINCREMENT,

  first_name VARCHAR(64) NULL,
  last_name VARCHAR(64) NULL,
  date_of_birth DATE NULL,
  registration_date DATE NOT NULL,
  gender VARCHAR(14) CHECK(gender IN ('Male', 'Female', 'PreferNotToSay')) NOT NULL,
  username VARCHAR(64) UNIQUE NOT NULL,
  email VARCHAR(64) UNIQUE NOT NULL -- User registers using email
);

CREATE TABLE devices (
  -- PK
  device_id INTEGER PRIMARY KEY AUTOINCREMENT,
  -- FK
  user_id INTEGER NOT NULL,

  device_type VARCHAR(64) NOT NULL,
  device_model VARCHAR(64) NOT NULL,
  firmware_version VARCHAR(64) NOT NULL,
  warranty_expire_date DATE NOT NULL,
  last_sync_date DATE,

  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE -- If User is deleted also delete the device
);

-- Lookup table
CREATE TABLE metric_type (
  -- PK
  metric_id INTEGER PRIMARY KEY AUTOINCREMENT,

  metric_name VARCHAR(64) UNIQUE NOT NULL,
  metric_unit VARCHAR(64) NOT NULL,
  metric_description VARCHAR(64),

  CHECK (metric_unit IN ('bpm', 'time', 'mmHg', 'calories', 'steps', 'kg', '%'))
);

CREATE TABLE metrics_log (
  -- PK
  metric_log_id INTEGER PRIMARY KEY AUTOINCREMENT,
  -- FK
  metric_id INTEGER NOT NULL,
  device_id INTEGER NOT NULL,

  metric_value INTEGER NOT NULL,
  metric_timestamp DATETIME NOT NULL,

  FOREIGN KEY (device_id) REFERENCES devices(device_id) ON DELETE CASCADE, -- If a device is deleted, its readings are also deleted
  FOREIGN KEY (metric_id) REFERENCES metric_type(metric_id) ON DELETE RESTRICT -- Prevent deleting a metric type if readings exist
  
);

CREATE TABLE exercise_type (
  -- PK
  exercise_id INTEGER PRIMARY KEY AUTOINCREMENT,

  exercise_name VARCHAR(64) UNIQUE NOT NULL,
  exercise_unit VARCHAR(64) NOT NULL,
  exercise_description VARCHAR(64)
);

CREATE TABLE exercises_log (
  -- PK
  exercise_log_id INTEGER PRIMARY KEY AUTOINCREMENT,
  -- FK
  exercise_id INTEGER NOT NULL,
  device_id INTEGER NOT NULL,

  exercise_value INTEGER NOT NULL,
  start_time DATETIME NOT NULL,
  end_time DATETIME NOT NULL,

  FOREIGN KEY (device_id) REFERENCES devices(device_id) ON DELETE CASCADE, -- If a device is deleted, its readings are also deleted
  FOREIGN KEY (exercise_id) REFERENCES exercise_type(exercise_id) ON DELETE RESTRICT, -- Prevent deleting an exercise type if readings exist
  CHECK (end_time > start_time)
);

CREATE TABLE goals (
  -- PK
  goal_id INTEGER PRIMARY KEY AUTOINCREMENT,
  -- FK
  user_id INTEGER NOT NULL,
  metric_id INTEGER NULL,
  exercise_id INTEGER NULL,

  target_type VARCHAR(20) NOT NULL,
  target_value FLOAT NOT NULL,
  goal_start_date DATETIME NOT NULL,
  -- goal_end_date DATETIME NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  FOREIGN KEY (exercise_id) REFERENCES exercise_type(exercise_id) ON DELETE RESTRICT, -- Prevent deleting an exercise type if goal exists
  FOREIGN KEY (metric_id) REFERENCES metric_type(metric_id) ON DELETE RESTRICT, -- Prevent deleting an exercise type if goal exists

  CHECK (target_type IN ('HealthMetric', 'Exercise')),
  CONSTRAINT chk_goal_target CHECK (
      (target_type = 'HealthMetric' AND metric_id IS NOT NULL AND exercise_id IS NULL) OR
      (target_type = 'Exercise' AND metric_id IS NULL AND exercise_id IS NOT NULL)
  )
);