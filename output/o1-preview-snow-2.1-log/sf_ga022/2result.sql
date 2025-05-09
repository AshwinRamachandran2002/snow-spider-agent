WITH cohort AS (
  SELECT DISTINCT "user_pseudo_id"
  FROM (
    SELECT "user_pseudo_id", "user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180901"
    UNION ALL
    SELECT "user_pseudo_id", "user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180902"
    UNION ALL
    SELECT "user_pseudo_id", "user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180903"
    UNION ALL
    SELECT "user_pseudo_id", "user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180904"
    UNION ALL
    SELECT "user_pseudo_id", "user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180905"
    UNION ALL
    SELECT "user_pseudo_id", "user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180906"
    UNION ALL
    SELECT "user_pseudo_id", "user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180907"
  ) AS temp
  WHERE "user_first_touch_timestamp" BETWEEN 1535731200000000 AND 1536335999000000
),
events AS (
  SELECT
    "user_pseudo_id",
    CASE
      WHEN TO_DATE("event_date", 'YYYYMMDD') BETWEEN '2018-09-08'::DATE AND '2018-09-14'::DATE THEN 'Week 1'
      WHEN TO_DATE("event_date", 'YYYYMMDD') BETWEEN '2018-09-15'::DATE AND '2018-09-21'::DATE THEN 'Week 2'
      WHEN TO_DATE("event_date", 'YYYYMMDD') BETWEEN '2018-09-22'::DATE AND '2018-09-28'::DATE THEN 'Week 3'
      ELSE NULL
    END AS "Week"
  FROM (
    SELECT "user_pseudo_id", "event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180908"
    UNION ALL
    SELECT "user_pseudo_id", "event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180909"
    UNION ALL
    SELECT "user_pseudo_id", "event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180910"
    UNION ALL
    SELECT "user_pseudo_id", "event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180911"
    UNION ALL
    SELECT "user_pseudo_id", "event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180912"
    UNION ALL
    SELECT "user_pseudo_id", "event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180913"
    UNION ALL
    SELECT "user_pseudo_id", "event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180914"
    UNION ALL
    SELECT "user_pseudo_id", "event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180915"
    UNION ALL
    SELECT "user_pseudo_id", "event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180916"
    UNION ALL
    SELECT "user_pseudo_id", "event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180917"
    UNION ALL
    SELECT "user_pseudo_id", "event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180918"
    UNION ALL
    SELECT "user_pseudo_id", "event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180919"
    UNION ALL
    SELECT "user_pseudo_id", "event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180920"
    UNION ALL
    SELECT "user_pseudo_id", "event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180921"
    UNION ALL
    SELECT "user_pseudo_id", "event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180922"
    UNION ALL
    SELECT "user_pseudo_id", "event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180923"
    UNION ALL
    SELECT "user_pseudo_id", "event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180924"
    UNION ALL
    SELECT "user_pseudo_id", "event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180925"
    UNION ALL
    SELECT "user_pseudo_id", "event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180926"
    UNION ALL
    SELECT "user_pseudo_id", "event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180927"
    UNION ALL
    SELECT "user_pseudo_id", "event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180928"
  ) AS temp
  WHERE "user_pseudo_id" IN (SELECT "user_pseudo_id" FROM cohort)
)
SELECT
  "Week",
  ROUND(COUNT(DISTINCT "user_pseudo_id") * 100.0 / (SELECT COUNT(*) FROM cohort), 4) AS "Retention_Rate"
FROM events
WHERE "Week" IS NOT NULL
GROUP BY "Week"
ORDER BY "Week";