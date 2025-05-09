WITH cohort_users AS (
  SELECT DISTINCT "user_pseudo_id"
  FROM (
    -- Week 0: July 2, 2018 - July 8, 2018
    SELECT "user_pseudo_id", "user_first_touch_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180702"
    UNION ALL
    SELECT "user_pseudo_id", "user_first_touch_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180703"
    UNION ALL
    SELECT "user_pseudo_id", "user_first_touch_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180704"
    UNION ALL
    SELECT "user_pseudo_id", "user_first_touch_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180705"
    UNION ALL
    SELECT "user_pseudo_id", "user_first_touch_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180706"
    UNION ALL
    SELECT "user_pseudo_id", "user_first_touch_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180707"
    UNION ALL
    SELECT "user_pseudo_id", "user_first_touch_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180708"
  ) AS t
  WHERE "user_first_touch_timestamp" >= DATE_PART(EPOCH_MICROSECOND, TIMESTAMP '2018-07-02')
    AND "user_first_touch_timestamp" < DATE_PART(EPOCH_MICROSECOND, TIMESTAMP '2018-07-09')
),
events AS (
  SELECT "user_pseudo_id", DATE_TRUNC('week', TO_TIMESTAMP_NTZ("event_timestamp" / 1e6)) AS "event_week"
  FROM (
    -- Week 1: July 9, 2018 - July 15, 2018
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180709"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180710"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180711"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180712"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180713"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180714"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180715"
    UNION ALL
    -- Week 2: July 16, 2018 - July 22, 2018
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180716"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180717"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180718"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180719"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180720"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180721"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180722"
    UNION ALL
    -- Week 3: July 23, 2018 - July 29, 2018
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180723"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180724"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180725"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180726"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180727"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180728"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180729"
    UNION ALL
    -- Week 4: July 30, 2018 - August 5, 2018
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180730"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180731"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180801"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180802"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180803"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180804"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180805"
  ) AS e
  WHERE TO_TIMESTAMP_NTZ("event_timestamp" / 1e6) < TIMESTAMP '2018-10-03'
    AND "user_pseudo_id" IN (SELECT "user_pseudo_id" FROM cohort_users)
)
SELECT
  'Week 0' AS "Week",
  COUNT(*) AS "Number_of_Users"
FROM cohort_users
UNION ALL
SELECT
  'Week 1' AS "Week",
  COUNT(DISTINCT "user_pseudo_id") AS "Number_of_Users"
FROM events
WHERE "event_week" = DATE_TRUNC('week', TIMESTAMP '2018-07-09')
UNION ALL
SELECT
  'Week 2' AS "Week",
  COUNT(DISTINCT "user_pseudo_id") AS "Number_of_Users"
FROM events
WHERE "event_week" = DATE_TRUNC('week', TIMESTAMP '2018-07-16')
UNION ALL
SELECT
  'Week 3' AS "Week",
  COUNT(DISTINCT "user_pseudo_id") AS "Number_of_Users"
FROM events
WHERE "event_week" = DATE_TRUNC('week', TIMESTAMP '2018-07-23')
UNION ALL
SELECT
  'Week 4' AS "Week",
  COUNT(DISTINCT "user_pseudo_id") AS "Number_of_Users"
FROM events
WHERE "event_week" = DATE_TRUNC('week', TIMESTAMP '2018-07-30')
ORDER BY "Week";