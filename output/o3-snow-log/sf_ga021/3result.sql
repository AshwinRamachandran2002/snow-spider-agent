/*  Two–week retention for every quick-play event type.
    – Cohort users: all users that fired a “session_start” between 2-Jul-2018 and 16-Jul-2018 (inclusive).
    – Initial event: first time each of those users fired the given quick-play event in the same period.
    – Retained-14d: user fired the SAME quick-play event again exactly 14 days after that initial date.
*/

WITH union_events AS (          --------------------------------------------------
    SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180702"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180703"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180704"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180705"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180706"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180707"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180708"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180709"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180710"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180711"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180712"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180713"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180714"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180715"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180716"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180717"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180718"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180719"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180720"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180721"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180722"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180723"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180724"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180725"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180726"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180727"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180728"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180729"
    UNION ALL SELECT "user_pseudo_id","event_name","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180730"
), --------------------------------------------------

cohort_users AS (             -- users that opened a session in the target window
    SELECT DISTINCT "user_pseudo_id"
    FROM union_events
    WHERE "event_name" = 'session_start'
      AND "event_date" BETWEEN '20180702' AND '20180716'
),

initial_quickplay AS (        -- first quick-play event (per type) during the window
    SELECT
        ue."user_pseudo_id",
        ue."event_name",
        MIN(TO_DATE(ue."event_date",'YYYYMMDD')) AS initial_date
    FROM union_events  ue
    JOIN cohort_users  cu
      ON ue."user_pseudo_id" = cu."user_pseudo_id"
    WHERE ue."event_name" IN ('level_fail_quickplay',
                              'level_end_quickplay',
                              'level_start_quickplay')
      AND ue."event_date" BETWEEN '20180702' AND '20180716'
    GROUP BY ue."user_pseudo_id", ue."event_name"
),

retention AS (                -- check if user repeats same event exactly 14 days later
    SELECT
        iq."user_pseudo_id",
        iq."event_name",
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM union_events ue2
                WHERE ue2."user_pseudo_id" = iq."user_pseudo_id"
                  AND ue2."event_name"     = iq."event_name"
                  AND TO_DATE(ue2."event_date",'YYYYMMDD') = iq.initial_date + 14
            ) THEN 1 ELSE 0
        END AS retained_flag
    FROM initial_quickplay iq
)

SELECT  "event_name"                                  AS "quickplay_event_type",
        COUNT(*)                                      AS "users_with_initial_event",
        SUM(retained_flag)                            AS "users_retained_day_14",
        ROUND(SUM(retained_flag) * 100.0 / COUNT(*), 2) AS "retention_rate_percent"
FROM    retention
GROUP BY "event_name"
ORDER BY "quickplay_event_type";