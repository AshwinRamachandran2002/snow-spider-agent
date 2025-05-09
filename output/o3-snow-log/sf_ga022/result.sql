WITH events_union AS (        -- ❶  bring all September 2018 data together
    SELECT "user_pseudo_id",
           "event_name",
           TO_TIMESTAMP("event_timestamp"/1000000) AS ts_utc
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180901"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_TIMESTAMP("event_timestamp"/1000000) FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180902"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_TIMESTAMP("event_timestamp"/1000000) FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180903"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_TIMESTAMP("event_timestamp"/1000000) FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180904"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_TIMESTAMP("event_timestamp"/1000000) FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180905"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_TIMESTAMP("event_timestamp"/1000000) FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180906"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_TIMESTAMP("event_timestamp"/1000000) FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180907"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_TIMESTAMP("event_timestamp"/1000000) FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180908"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_TIMESTAMP("event_timestamp"/1000000) FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180909"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_TIMESTAMP("event_timestamp"/1000000) FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180910"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_TIMESTAMP("event_timestamp"/1000000) FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180911"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_TIMESTAMP("event_timestamp"/1000000) FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180912"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_TIMESTAMP("event_timestamp"/1000000) FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180913"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_TIMESTAMP("event_timestamp"/1000000) FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180914"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_TIMESTAMP("event_timestamp"/1000000) FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180915"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_TIMESTAMP("event_timestamp"/1000000) FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180916"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_TIMESTAMP("event_timestamp"/1000000) FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180917"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_TIMESTAMP("event_timestamp"/1000000) FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180918"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_TIMESTAMP("event_timestamp"/1000000) FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180919"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_TIMESTAMP("event_timestamp"/1000000) FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180920"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_TIMESTAMP("event_timestamp"/1000000) FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180921"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_TIMESTAMP("event_timestamp"/1000000) FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180922"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_TIMESTAMP("event_timestamp"/1000000) FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180923"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_TIMESTAMP("event_timestamp"/1000000) FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180924"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_TIMESTAMP("event_timestamp"/1000000) FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180925"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_TIMESTAMP("event_timestamp"/1000000) FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180926"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_TIMESTAMP("event_timestamp"/1000000) FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180927"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_TIMESTAMP("event_timestamp"/1000000) FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180928"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_TIMESTAMP("event_timestamp"/1000000) FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180929"
    UNION ALL SELECT "user_pseudo_id","event_name",TO_TIMESTAMP("event_timestamp"/1000000) FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180930"
),
events_sh AS (               -- ❷  convert to Asia/Shanghai date
    SELECT
        "user_pseudo_id",
        "event_name",
        CONVERT_TIMEZONE('UTC','Asia/Shanghai',ts_utc)                  AS ts_sh,
        TO_DATE(CONVERT_TIMEZONE('UTC','Asia/Shanghai',ts_utc))         AS event_date_sh
    FROM events_union
),
cohort AS (                   -- ❸  users whose FIRST_OPEN was 1-7 Sept (Shanghai)
    SELECT DISTINCT "user_pseudo_id"
    FROM events_sh
    WHERE "event_name" = 'first_open'
      AND event_date_sh BETWEEN '2018-09-01' AND '2018-09-07'
),
user_activity AS (            -- ❹  flag activity in weeks 1,2,3
    SELECT
        c."user_pseudo_id",
        MAX(CASE WHEN e.event_date_sh BETWEEN '2018-09-08' AND '2018-09-14' THEN 1 ELSE 0 END) AS wk1,
        MAX(CASE WHEN e.event_date_sh BETWEEN '2018-09-15' AND '2018-09-21' THEN 1 ELSE 0 END) AS wk2,
        MAX(CASE WHEN e.event_date_sh BETWEEN '2018-09-22' AND '2018-09-28' THEN 1 ELSE 0 END) AS wk3
    FROM cohort c
    LEFT JOIN events_sh e
          ON c."user_pseudo_id" = e."user_pseudo_id"
    GROUP BY c."user_pseudo_id"
)
SELECT                          -- ❺  compute retention rates
    COUNT(*)                                                     AS cohort_size,
    ROUND(SUM(wk1) / COUNT(*), 4)                               AS "week1_retention_rate",
    ROUND(SUM(wk2) / COUNT(*), 4)                               AS "week2_retention_rate",
    ROUND(SUM(wk3) / COUNT(*), 4)                               AS "week3_retention_rate"
FROM user_activity;