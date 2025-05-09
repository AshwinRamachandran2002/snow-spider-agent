WITH first_engaged_users AS
(
  SELECT DISTINCT "user_pseudo_id", TO_DATE(TO_TIMESTAMP_NTZ("user_first_touch_timestamp" / 1e6)) AS "first_engagement_date"
  FROM
  (
    SELECT "user_pseudo_id", "user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180801
    UNION ALL
    SELECT "user_pseudo_id", "user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180802
    UNION ALL
    SELECT "user_pseudo_id", "user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180803
    UNION ALL
    SELECT "user_pseudo_id", "user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180804
    UNION ALL
    SELECT "user_pseudo_id", "user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180805
    UNION ALL
    SELECT "user_pseudo_id", "user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180806
    UNION ALL
    SELECT "user_pseudo_id", "user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180807
    UNION ALL
    SELECT "user_pseudo_id", "user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180808
    UNION ALL
    SELECT "user_pseudo_id", "user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180809
    UNION ALL
    SELECT "user_pseudo_id", "user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180810
    UNION ALL
    SELECT "user_pseudo_id", "user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180811
    UNION ALL
    SELECT "user_pseudo_id", "user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180812
    UNION ALL
    SELECT "user_pseudo_id", "user_first_touch_timestamp"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180813
  ) t
  WHERE TO_DATE(TO_TIMESTAMP_NTZ("user_first_touch_timestamp" / 1e6)) BETWEEN '2018-08-01' AND '2018-08-15'
),

quickplay_event_types AS
(
  SELECT DISTINCT t."user_pseudo_id", t."event_name" AS "quickplay_event_type"
  FROM
  (
    SELECT "user_pseudo_id", "event_name"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180801
    UNION ALL
    SELECT "user_pseudo_id", "event_name"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180802
    UNION ALL
    SELECT "user_pseudo_id", "event_name"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180803
    UNION ALL
    SELECT "user_pseudo_id", "event_name"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180804
    UNION ALL
    SELECT "user_pseudo_id", "event_name"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180805
    UNION ALL
    SELECT "user_pseudo_id", "event_name"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180806
    UNION ALL
    SELECT "user_pseudo_id", "event_name"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180807
    UNION ALL
    SELECT "user_pseudo_id", "event_name"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180808
    UNION ALL
    SELECT "user_pseudo_id", "event_name"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180809
    UNION ALL
    SELECT "user_pseudo_id", "event_name"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180810
    UNION ALL
    SELECT "user_pseudo_id", "event_name"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180811
    UNION ALL
    SELECT "user_pseudo_id", "event_name"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180812
    UNION ALL
    SELECT "user_pseudo_id", "event_name"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180813
  ) t
  WHERE t."event_name" LIKE '%quickplay%'
),

session_start_events AS
(
  SELECT "user_pseudo_id", TO_DATE(TO_TIMESTAMP_NTZ("event_timestamp" / 1e6)) AS "event_date"
  FROM
  (
    SELECT "user_pseudo_id", "event_timestamp", "event_name"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180808
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp", "event_name"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180809
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp", "event_name"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180810
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp", "event_name"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180811
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp", "event_name"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180812
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp", "event_name"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180813
  ) t
  WHERE t."event_name" = 'session_start'
)

SELECT qet."quickplay_event_type",
       ROUND((COUNT(DISTINCT ss."user_pseudo_id") * 100.0) / NULLIF(COUNT(DISTINCT qet."user_pseudo_id"), 0), 4) AS user_retention_rate
FROM quickplay_event_types qet
JOIN first_engaged_users feu ON qet."user_pseudo_id" = feu."user_pseudo_id"
LEFT JOIN session_start_events ss ON ss."user_pseudo_id" = qet."user_pseudo_id"
  AND ss."event_date" BETWEEN DATEADD('day', 7, feu."first_engagement_date") AND DATEADD('day', 13, feu."first_engagement_date")
GROUP BY qet."quickplay_event_type"
ORDER BY user_retention_rate ASC
LIMIT 1;