/*  Lowest 2-week (days 8-14) retention — measured by session_start —
    for users whose very first “quickplay” event occurred 1-15 Aug 2018  */

WITH all_aug_events AS (
    /* pick the SAME four columns from every August-2018 daily table      */
    SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180801"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180802"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180803"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180804"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180805"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180806"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180807"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180808"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180809"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180810"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180811"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180812"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180813"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180814"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180815"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180816"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180817"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180818"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180819"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180820"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180821"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180822"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180823"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180824"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180825"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180826"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180827"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180828"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180829"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180830"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180831"
),

/* cohort: first quickplay 1-15 Aug */
cohort AS (
    SELECT  "user_pseudo_id",
            "event_name"                               AS first_event_type,
            TO_DATE("event_date",'YYYYMMDD')           AS first_event_date,
            ROW_NUMBER() OVER (PARTITION BY "user_pseudo_id"
                               ORDER BY "event_timestamp")  AS rn
    FROM    all_aug_events
    WHERE   "event_name" ILIKE '%quickplay%'
      AND   TO_DATE("event_date",'YYYYMMDD')
            BETWEEN '2018-08-01'::DATE AND '2018-08-15'::DATE
),
first_cohort AS (
    SELECT "user_pseudo_id", first_event_type, first_event_date
    FROM   cohort
    WHERE  rn = 1
),

/* session_start events */
sessions AS (
    SELECT  "user_pseudo_id",
            TO_DATE("event_date",'YYYYMMDD') AS sess_date
    FROM    all_aug_events
    WHERE   "event_name" = 'session_start'
),

/* retention (days 8-14) */
retention_calc AS (
    SELECT
        f.first_event_type,
        COUNT(DISTINCT f."user_pseudo_id")                                                     AS cohort_size,
        COUNT(DISTINCT CASE
                          WHEN s."user_pseudo_id" IS NOT NULL THEN f."user_pseudo_id"
                       END)                                                                    AS retained_users
    FROM        first_cohort f
    LEFT JOIN   sessions s
           ON   s."user_pseudo_id" = f."user_pseudo_id"
          AND   s.sess_date BETWEEN DATEADD(day,7 ,f.first_event_date)
                               AND     DATEADD(day,14,f.first_event_date)
    GROUP BY    f.first_event_type
)

SELECT  first_event_type,
        retained_users,
        cohort_size,
        retained_users::FLOAT / cohort_size AS retention_rate
FROM    retention_calc
ORDER BY retention_rate ASC NULLS LAST
LIMIT 1;