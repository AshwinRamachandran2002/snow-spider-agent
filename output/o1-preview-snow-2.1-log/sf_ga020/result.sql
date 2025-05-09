WITH initial_events AS (
  SELECT
    "user_pseudo_id",
    "event_timestamp",
    "event_date",
    "event_name"
  FROM (
    SELECT
      "user_pseudo_id",
      "event_timestamp",
      "event_date",
      "event_name"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180801
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp",
      "event_date",
      "event_name"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180802
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp",
      "event_date",
      "event_name"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180803
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp",
      "event_date",
      "event_name"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180804
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp",
      "event_date",
      "event_name"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180805
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp",
      "event_date",
      "event_name"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180806
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp",
      "event_date",
      "event_name"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180807
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp",
      "event_date",
      "event_name"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180808
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp",
      "event_date",
      "event_name"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180809
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp",
      "event_date",
      "event_name"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180810
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp",
      "event_date",
      "event_name"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180811
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp",
      "event_date",
      "event_name"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180812
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp",
      "event_date",
      "event_name"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180813
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp",
      "event_date",
      "event_name"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180814
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp",
      "event_date",
      "event_name"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180815
  ) t
),
user_first_engagement AS (
  SELECT
    "user_pseudo_id",
    MIN("event_timestamp") AS first_engagement_timestamp
  FROM initial_events
  GROUP BY "user_pseudo_id"
),
cohort_users AS (
  SELECT
    ufe."user_pseudo_id",
    ufe.first_engagement_timestamp,
    TO_TIMESTAMP_LTZ(ufe.first_engagement_timestamp / 1e6) AS first_engagement_time,
    TO_DATE(TO_TIMESTAMP_LTZ(ufe.first_engagement_timestamp / 1e6)) AS first_engagement_date,
    DATEADD('day', 7, TO_TIMESTAMP_LTZ(ufe.first_engagement_timestamp / 1e6)) AS week2_start_time,
    DATEADD('day', 14, TO_TIMESTAMP_LTZ(ufe.first_engagement_timestamp / 1e6)) AS week2_end_time
  FROM user_first_engagement ufe
  WHERE TO_DATE(TO_TIMESTAMP_LTZ(ufe.first_engagement_timestamp / 1e6)) BETWEEN '2018-08-01' AND '2018-08-15'
),
user_event_types AS (
  SELECT DISTINCT
    ufe."user_pseudo_id",
    e."event_name"
  FROM initial_events e
  JOIN cohort_users ufe
    ON e."user_pseudo_id" = ufe."user_pseudo_id"
    AND e."event_date" = TO_CHAR(ufe.first_engagement_date, 'YYYYMMDD')
    AND e."event_name" IN ('level_complete_quickplay', 'level_start_quickplay', 'level_end_quickplay', 'level_fail_quickplay', 'level_retry_quickplay', 'level_reset_quickplay')
),
week2_events AS (
  SELECT
    "user_pseudo_id",
    "event_timestamp"
  FROM (
    SELECT
      "user_pseudo_id",
      "event_timestamp"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180808
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180809
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180810
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180811
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180812
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180813
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180814
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180815
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180816
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180817
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180818
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180819
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180820
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180821
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180822
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180823
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180824
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180825
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180826
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180827
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180828
    UNION ALL
    SELECT
      "user_pseudo_id",
      "event_timestamp"
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180829
  ) we
),
week2_activity AS (
  SELECT DISTINCT
    we."user_pseudo_id"
  FROM week2_events we
  JOIN cohort_users cu
    ON we."user_pseudo_id" = cu."user_pseudo_id"
    AND TO_TIMESTAMP_LTZ(we."event_timestamp" / 1e6) BETWEEN cu.week2_start_time AND cu.week2_end_time
)
SELECT
  rr."Event_Type",
  TRUNC(rr."Retention_Rate_Week2", 4) AS "Retention_Rate_Week2"
FROM (
  SELECT
    uet."event_name" AS "Event_Type",
    COUNT(DISTINCT uet."user_pseudo_id") AS total_users,
    COUNT(DISTINCT CASE WHEN wa."user_pseudo_id" IS NOT NULL THEN uet."user_pseudo_id" END) AS retained_users,
    (COUNT(DISTINCT CASE WHEN wa."user_pseudo_id" IS NOT NULL THEN uet."user_pseudo_id" END) * 100.0) / COUNT(DISTINCT uet."user_pseudo_id") AS "Retention_Rate_Week2"
  FROM user_event_types uet
  LEFT JOIN week2_activity wa
    ON uet."user_pseudo_id" = wa."user_pseudo_id"
  GROUP BY uet."event_name"
) rr
ORDER BY rr."Retention_Rate_Week2" ASC NULLS LAST
LIMIT 1;