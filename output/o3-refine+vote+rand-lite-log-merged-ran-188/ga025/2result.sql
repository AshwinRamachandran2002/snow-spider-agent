WITH september_events AS (
  -- keep only September-2018 data to speed things up
  SELECT
    `user_pseudo_id`,
    `event_name`,
    `event_date`
  FROM `firebase-public-project.analytics_153293282.events_201809*`
),

/* 1. first_open date (only those whose first_open happened in Sep-2018) */
first_open AS (
  SELECT
    `user_pseudo_id`,
    MIN( PARSE_DATE('%Y%m%d', `event_date`) ) AS fo_date
  FROM september_events
  WHERE `event_name` = 'first_open'
  GROUP BY `user_pseudo_id`
),

/* 2. uninstall (app_remove) date for the same user in Sep-2018 */
uninstall AS (
  SELECT
    `user_pseudo_id`,
    MIN( PARSE_DATE('%Y%m%d', `event_date`) ) AS uninstall_date
  FROM september_events
  WHERE `event_name` = 'app_remove'
  GROUP BY `user_pseudo_id`
),

/* 3. users that uninstalled within 7-days of first_open                      */
qualified AS (
  SELECT
    f.`user_pseudo_id`,
    f.fo_date
  FROM first_open f
  JOIN uninstall u
    ON u.`user_pseudo_id` = f.`user_pseudo_id`
  WHERE DATE_DIFF(u.uninstall_date, f.fo_date, DAY) BETWEEN 0 AND 7
),

/* 4. among the qualified users, who had at least one crash (app_exception)   */
crashed AS (
  SELECT DISTINCT q.`user_pseudo_id`
  FROM qualified q
  JOIN september_events e
    ON e.`user_pseudo_id` = q.`user_pseudo_id`
  WHERE e.`event_name` = 'app_exception'
    AND PARSE_DATE('%Y%m%d', e.`event_date`)
        BETWEEN q.fo_date AND DATE_ADD(q.fo_date, INTERVAL 7 DAY)
)

/* 5. percentage of qualified users that experienced a crash                  */
SELECT
  COUNT(DISTINCT crashed.`user_pseudo_id`) * 100.0
  / COUNT(DISTINCT qualified.`user_pseudo_id`) AS pct_users_with_crash
FROM qualified
LEFT JOIN crashed
  ON crashed.`user_pseudo_id` = qualified.`user_pseudo_id`;