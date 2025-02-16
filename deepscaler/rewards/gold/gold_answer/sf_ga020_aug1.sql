-- Task: List the user IDs and their first engagement dates for users who first engaged between August 1 and August 15, 2018. Limit the result to 100 users.

WITH initial_events AS (
  SELECT
    "user_pseudo_id",
    "event_timestamp"
  FROM (
    SELECT
      "user_pseudo_id",
      "event_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180801"
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180802"
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180803"
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180804"
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180805"
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180806"
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180807"
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180808"
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180809"
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180810"
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180811"
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180812"
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180813"
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180814"
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180815"
  ) t
),
user_first_engagement AS (
  SELECT
    "user_pseudo_id",
    MIN("event_timestamp") AS "first_engagement_timestamp"
  FROM initial_events
  GROUP BY "user_pseudo_id"
),
cohort_users AS (
  SELECT
    "user_pseudo_id",
    TO_DATE(TO_TIMESTAMP_LTZ("first_engagement_timestamp" / 1e6)) AS first_engagement_date
  FROM user_first_engagement
  WHERE TO_DATE(TO_TIMESTAMP_LTZ("first_engagement_timestamp" / 1e6)) BETWEEN '2018-08-01' AND '2018-08-15'
)
SELECT
  "user_pseudo_id",
  first_engagement_date
FROM cohort_users
LIMIT 100;