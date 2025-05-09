/*  Lowest-retention quick-play event for users who first engaged
    between 1-Aug-2018 and 15-Aug-2018 (week-2 retention measured
    by presence of session_start events)                                    */

WITH quickplay_aug AS (               -- every QUICKPLAY row 1-15 Aug
    SELECT "user_pseudo_id" AS user_id,
           "event_timestamp" AS ts,
           "event_name"      AS ev
    FROM (
        SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180801
        UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180802
        UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180803
        UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180804
        UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180805
        UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180806
        UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180807
        UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180808
        UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180809
        UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180810
        UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180811
        UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180812
        UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180813
        UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180814
        UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180815
    )
    WHERE "event_name" ILIKE '%quickplay%'
),

first_touch AS (                      -- first QUICKPLAY per user
    SELECT user_id,
           MIN(ts) AS first_ts
    FROM   quickplay_aug
    GROUP BY user_id
),

cohort AS (                           -- add the event type at first touch
    SELECT f.user_id,
           f.first_ts,
           q.ev AS quickplay_event
    FROM   first_touch f
    JOIN   quickplay_aug q
      ON   q.user_id = f.user_id
     AND   q.ts      = f.first_ts
),

later_ss AS (                         -- every session_start 8-29 Aug
    SELECT "user_pseudo_id" AS user_id,
           "event_timestamp" AS ts
    FROM (
        SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180808
        UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180809
        UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180810
        UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180811
        UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180812
        UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180813
        UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180814
        UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180815
        UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180816
        UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180817
        UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180818
        UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180819
        UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180820
        UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180821
        UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180822
        UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180823
        UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180824
        UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180825
        UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180826
        UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180827
        UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180828
        UNION ALL SELECT "user_pseudo_id","event_timestamp","event_name" FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180829
    )
    WHERE "event_name" = 'session_start'
),

retained AS (                         -- users with session_start in day 7-14 window
    SELECT DISTINCT l.user_id
    FROM   later_ss l
    JOIN   cohort   c
      ON   l.user_id = c.user_id
     AND   l.ts BETWEEN c.first_ts + 7*24*3600*1000000
                    AND c.first_ts +14*24*3600*1000000
),

metrics AS (                          -- cohort size & retained count
    SELECT  c.quickplay_event,
            COUNT(DISTINCT c.user_id) AS cohort_users,
            COUNT(DISTINCT r.user_id) AS retained_users
    FROM    cohort c
    LEFT JOIN retained r USING (user_id)
    GROUP BY c.quickplay_event
)

SELECT  quickplay_event         AS lowest_retention_event,
        retained_users::FLOAT / NULLIF(cohort_users,0) AS week2_retention_rate
FROM    metrics
ORDER BY week2_retention_rate
LIMIT 1;