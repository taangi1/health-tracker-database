-- 1)
-- Show users that registered an account 
-- but have not registered the device to an account
SELECT username, 
      first_name, 
      last_name, 
      gender,
      email, 
      registration_date
FROM users
WHERE user_id NOT IN (SELECT DISTINCT user_id FROM devices)
ORDER BY username;

-- 2)
-- Show the users that have more than one device registered
-- to their account
SELECT user_id, 
      COUNT(*) AS number_of_devices
FROM devices
GROUP BY user_id
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC;

-- 3)
-- Show users without devices but with set goals.
SELECT username,
      first_name,
      last_name,
      email
FROM users
WHERE user_id NOT IN (SELECT DISTINCT user_id FROM devices)
AND user_id IN (SELECT DISTINCT user_id FROM goals)
ORDER BY username;

-- 4)
-- Get the average heart rate for a user.
SELECT u.username, 
      ROUND(AVG(ml.metric_value), 2) as avg_heart_rate, 
      date(ml.metric_timestamp) as `date`
FROM metrics_log ml
LEFT JOIN devices d ON ml.device_id = d.device_id
INNER JOIN users u ON u.user_id = d.user_id
WHERE ml.metric_id = 1
GROUP BY u.user_id, date(ml.metric_timestamp)
ORDER BY u.username;

-- 5)
-- Show the most popular activity that users choose (top 5)
SELECT et.exercise_name,
      COUNT(el.exercise_id) AS number_of_logs
FROM exercises_log el
LEFT JOIN exercise_type et ON el.exercise_id = et.exercise_id
GROUP BY el.exercise_id
ORDER BY COUNT(el.exercise_id) DESC
LIMIT 5;

-- 6)
-- Show if the goal in steps of a user has been achieved
SELECT u.username, 
      g.target_value AS target_steps, 
      SUM(ml.metric_value) AS actual_steps,
      date(g.goal_start_date) as goal_date,
      CASE WHEN g.target_value <= SUM(ml.metric_value) THEN 'Achieved' ELSE 'Not achieved' END as is_goal_achieved
FROM goals g
LEFT JOIN users u ON g.user_id = u.user_id
LEFT JOIN devices d ON g.user_id = d.user_id
LEFT JOIN metrics_log ml ON ml.device_id = d.device_id
                        AND ml.metric_id = g.metric_id
                        AND date(g.goal_start_date) = date(ml.metric_timestamp)
WHERE g.metric_id = 2
GROUP BY g.user_id, g.goal_id, date(ml.metric_timestamp)
ORDER BY u.username, date(g.goal_start_date);

-- 7)
-- Show for each user their exercises and time spent to complete
SELECT u.username,
      et.exercise_name,
      el.exercise_value,
      et.exercise_unit,
      CAST(((julianday(el.end_time) - julianday(el.start_time))*24*60) AS INTEGER) AS minutes_to_finish
FROM exercises_log el
LEFT JOIN exercise_type et ON el.exercise_id = et.exercise_id
LEFT JOIN devices d ON d.device_id = el.device_id
LEFT JOIN users u ON d.user_id = u.user_id
ORDER BY u.username, et.exercise_name;

-- 8)
-- Show exercise type that took the most time to complete (top 5)
SELECT et.exercise_name,
      (el.exercise_value) AS avg_exercise_value,
      et.exercise_unit,
      CAST(((
            MAX(julianday(el.end_time) - julianday(el.start_time)))*24*60) 
      AS INTEGER) AS minutes_to_finish_average
FROM exercises_log el
LEFT JOIN exercise_type et ON el.exercise_id = et.exercise_id
GROUP BY et.exercise_name
ORDER BY minutes_to_finish_average DESC
LIMIT 5;

-- 9)
-- For each user show their most frequent exercise
WITH exercise_counts AS
(
      SELECT u.username, 
            et.exercise_name, 
            COUNT(*) AS number_of_exercises
      FROM exercises_log el
      LEFT JOIN devices d ON el.device_id = d.device_id
      LEFT JOIN users u ON u.user_id = d.user_id
      LEFT JOIN exercise_type et ON et.exercise_id = el.exercise_id
      GROUP BY u.username, et.exercise_name
)
SELECT *
FROM exercise_counts
WHERE (username, number_of_exercises) IN (
      SELECT username, MAX(number_of_exercises)
      FROM exercise_counts
      GROUP BY username
)
ORDER BY number_of_exercises DESC;

-- 10)
-- Show sleep duration for each day for each user
-- All users sleep from 22:00 of previous day up to 08:00 of current day for simplicity.
-- Because of that we need to join the sleep of previous day with the sleep of current day.
WITH prev_day AS
(
SELECT d.user_id, 
       date(ml.metric_timestamp) as sleep_date,
       SUM(ml.metric_value)/60 AS total_sleep_hours
FROM metrics_log ml
LEFT JOIN devices d ON ml.device_id = d.device_id
WHERE ml.metric_id=3
AND ml.device_id IN ( -- Select only one device per user.
      SELECT device_id
      FROM devices
      GROUP BY user_id
)
AND strftime('%H', ml.metric_timestamp) >= '22' -- Select sum of hours of sleep where timestamp from 22 hours upto 24.
GROUP BY d.user_id, sleep_date
),
cur_day AS
(
SELECT d.user_id, 
       date(ml.metric_timestamp) AS sleep_date, 
       SUM(ml.metric_value)/60 AS total_sleep_hours
FROM metrics_log ml
LEFT JOIN devices d ON ml.device_id = d.device_id
WHERE ml.metric_id=3
AND ml.device_id IN ( -- Select only one device per user.
      SELECT device_id
      FROM devices
      GROUP BY user_id
)
AND strftime('%H', ml.metric_timestamp) < '08' -- Select morning sleep hours
GROUP BY d.user_id, sleep_date
)
SELECT u.username,
      u.gender,
      cd.sleep_date,
      ROUND(cd.total_sleep_hours + pd.total_sleep_hours, 2) as total_sleep_hours
FROM cur_day cd
LEFT JOIN prev_day pd ON cd.sleep_date = date(pd.sleep_date, '+1 day') -- Join current day with previous day sleep hours.
AND cd.user_id = pd.user_id
INNER JOIN users u ON cd.user_id = u.user_id
ORDER BY u.username, cd.sleep_date;

-- 11)
-- Select all metric readings during 14 and 15 may for 5th device_id
SELECT 
    mt.metric_name,
    ml.metric_value,
    ml.metric_timestamp
FROM 
    metrics_log ml
JOIN 
    metric_type mt ON ml.metric_id = mt.metric_id
WHERE 
    ml.device_id = 5
    AND ml.metric_timestamp BETWEEN '2025-05-14' AND '2025-05-15';

-- 12)
-- For user bwallace show the highest heart rate between 12 and 13 hours of 15th of May 2025
SELECT ml.metric_value, 
      ml.metric_timestamp
FROM metrics_log ml
LEFT JOIN metric_type mt ON ml.metric_id = mt.metric_id
WHERE metric_timestamp BETWEEN '2025-05-15 12:00:00' AND '2025-05-15 13:00:00'
      AND mt.metric_name = 'Heart Rate'
      AND ml.device_id = (SELECT device_id
                          FROM devices
                          WHERE user_id = (SELECT user_id FROM users WHERE username = 'bwallace'))
ORDER BY ml.metric_value DESC
LIMIT 1;

-- 13)
-- For user cody67 select their heart rate during push-ups exercise
SELECT ml.metric_value, 
      ml.metric_timestamp AS time_collected
FROM metrics_log ml
LEFT JOIN exercises_log el ON ml.device_id = el.device_id
                           AND ml.metric_timestamp BETWEEN el.start_time AND el.end_time
LEFT JOIN exercise_type et ON et.exercise_id = el.exercise_id
WHERE ml.device_id = (SELECT device_id
                      FROM devices
                      WHERE user_id = (SELECT user_id FROM users WHERE username = 'cody67'))
      AND et.exercise_name = 'push-ups'
      AND ml.metric_id = (SELECT metric_id FROM metric_type WHERE metric_name = 'Heart Rate');