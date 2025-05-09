/*-----------------------------------------------------------
Retention = users whose very first “quick-play” event happens
between 2-Jul-2018 and 16-Jul-2018 (inclusive) **and** who fire
a “session_start” event exactly 14 days after that first
quick-play.  Results are broken out by quick-play event type.
-----------------------------------------------------------*/
WITH events AS (                       /* 1. bring in all July events we need */
    SELECT
        t."user_pseudo_id",
        t."event_name",
        t."event_date",
        TO_DATE(t."event_date",'YYYYMMDD')      AS evt_dt,
        t."event_timestamp"
    FROM (
        SELECT "user_pseudo_id","event_name","event_date","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180702"
        UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180703"
        UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180704"
        UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180705"
        UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180706"
        UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180707"
        UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180708"
        UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180709"
        UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180710"
        UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180711"
        UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180712"
        UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180713"
        UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180714"
        UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180715"
        UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180716"
        UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180717"
        UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180718"
        UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180719"
        UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180720"
        UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180721"
        UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180722"
        UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180723"
        UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180724"
        UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180725"
        UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180726"
        UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180727"
        UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180728"
        UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180729"
        UNION ALL SELECT "user_pseudo_id","event_name","event_date","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180730"
    ) t
),

/* 2. users who had a session_start between 2-Jul and 16-Jul */
cohort_users AS (
    SELECT DISTINCT "user_pseudo_id"
    FROM   events
    WHERE  "event_name" = 'session_start'
      AND  evt_dt BETWEEN '2018-07-02'::DATE AND '2018-07-16'::DATE
),

/* 3. every user’s FIRST quick-play event (per type) inside the window */
initial_quickplay AS (
    SELECT
        e."user_pseudo_id",
        e."event_name"                            AS quickplay_type,
        e.evt_dt                                  AS cohort_dt,
        ROW_NUMBER() OVER (
            PARTITION BY e."user_pseudo_id", e."event_name"
            ORDER BY    e."event_timestamp"
        )                                         AS rn
    FROM   events      e
    JOIN   cohort_users c  ON c."user_pseudo_id" = e."user_pseudo_id"
    WHERE  e."event_name" ILIKE '%quickplay'      -- match any event containing 'quickplay'
      AND  e.evt_dt BETWEEN '2018-07-02'::DATE AND '2018-07-16'::DATE
),

/* 4. retain only that first quick-play row */
cohort AS (
    SELECT "user_pseudo_id",
           quickplay_type,
           cohort_dt
    FROM   initial_quickplay
    WHERE  rn = 1
),

/* 5. did the same user fire session_start exactly 14 days later? */
retained AS (
    SELECT DISTINCT
           c."user_pseudo_id",
           c.quickplay_type
    FROM   cohort c
    JOIN   events e
           ON  e."user_pseudo_id" = c."user_pseudo_id"
           AND e."event_name"     = 'session_start'
           AND e.evt_dt           = c.cohort_dt + 14
)

/* 6. calculate retention rate */
SELECT
    c.quickplay_type,
    COUNT(DISTINCT r."user_pseudo_id")                            AS retained_users,
    COUNT(DISTINCT c."user_pseudo_id")                            AS cohort_users,
    ROUND(
        COUNT(DISTINCT r."user_pseudo_id")::FLOAT
        / NULLIF(COUNT(DISTINCT c."user_pseudo_id"),0),
        4
    )                                                             AS retention_rate
FROM   cohort   c
LEFT   JOIN retained r
       ON r."user_pseudo_id" = c."user_pseudo_id"
      AND r.quickplay_type   = c.quickplay_type
GROUP  BY c.quickplay_type
ORDER  BY retention_rate DESC NULLS LAST;