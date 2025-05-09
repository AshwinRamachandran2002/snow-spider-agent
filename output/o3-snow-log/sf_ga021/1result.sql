WITH union_events AS (  
    SELECT "event_date",
           TO_DATE("event_date",'YYYYMMDD')      AS event_date_d,
           "event_name",
           "user_pseudo_id"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180702"  
    UNION ALL SELECT "event_date", TO_DATE("event_date",'YYYYMMDD'), "event_name", "user_pseudo_id"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180703"
    UNION ALL SELECT "event_date", TO_DATE("event_date",'YYYYMMDD'), "event_name", "user_pseudo_id"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180704"
    UNION ALL SELECT "event_date", TO_DATE("event_date",'YYYYMMDD'), "event_name", "user_pseudo_id"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180705"
    UNION ALL SELECT "event_date", TO_DATE("event_date",'YYYYMMDD'), "event_name", "user_pseudo_id"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180706"
    UNION ALL SELECT "event_date", TO_DATE("event_date",'YYYYMMDD'), "event_name", "user_pseudo_id"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180707"
    UNION ALL SELECT "event_date", TO_DATE("event_date",'YYYYMMDD'), "event_name", "user_pseudo_id"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180708"
    UNION ALL SELECT "event_date", TO_DATE("event_date",'YYYYMMDD'), "event_name", "user_pseudo_id"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180709"
    UNION ALL SELECT "event_date", TO_DATE("event_date",'YYYYMMDD'), "event_name", "user_pseudo_id"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180710"
    UNION ALL SELECT "event_date", TO_DATE("event_date",'YYYYMMDD'), "event_name", "user_pseudo_id"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180711"
    UNION ALL SELECT "event_date", TO_DATE("event_date",'YYYYMMDD'), "event_name", "user_pseudo_id"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180712"
    UNION ALL SELECT "event_date", TO_DATE("event_date",'YYYYMMDD'), "event_name", "user_pseudo_id"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180713"
    UNION ALL SELECT "event_date", TO_DATE("event_date",'YYYYMMDD'), "event_name", "user_pseudo_id"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180714"
    UNION ALL SELECT "event_date", TO_DATE("event_date",'YYYYMMDD'), "event_name", "user_pseudo_id"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180715"
    UNION ALL SELECT "event_date", TO_DATE("event_date",'YYYYMMDD'), "event_name", "user_pseudo_id"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180716"
    UNION ALL SELECT "event_date", TO_DATE("event_date",'YYYYMMDD'), "event_name", "user_pseudo_id"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180717"
    UNION ALL SELECT "event_date", TO_DATE("event_date",'YYYYMMDD'), "event_name", "user_pseudo_id"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180718"
    UNION ALL SELECT "event_date", TO_DATE("event_date",'YYYYMMDD'), "event_name", "user_pseudo_id"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180719"
    UNION ALL SELECT "event_date", TO_DATE("event_date",'YYYYMMDD'), "event_name", "user_pseudo_id"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180720"
    UNION ALL SELECT "event_date", TO_DATE("event_date",'YYYYMMDD'), "event_name", "user_pseudo_id"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180721"
    UNION ALL SELECT "event_date", TO_DATE("event_date",'YYYYMMDD'), "event_name", "user_pseudo_id"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180722"
    UNION ALL SELECT "event_date", TO_DATE("event_date",'YYYYMMDD'), "event_name", "user_pseudo_id"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180723"
    UNION ALL SELECT "event_date", TO_DATE("event_date",'YYYYMMDD'), "event_name", "user_pseudo_id"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180724"
    UNION ALL SELECT "event_date", TO_DATE("event_date",'YYYYMMDD'), "event_name", "user_pseudo_id"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180725"
    UNION ALL SELECT "event_date", TO_DATE("event_date",'YYYYMMDD'), "event_name", "user_pseudo_id"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180726"
    UNION ALL SELECT "event_date", TO_DATE("event_date",'YYYYMMDD'), "event_name", "user_pseudo_id"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180727"
    UNION ALL SELECT "event_date", TO_DATE("event_date",'YYYYMMDD'), "event_name", "user_pseudo_id"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180728"
    UNION ALL SELECT "event_date", TO_DATE("event_date",'YYYYMMDD'), "event_name", "user_pseudo_id"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180729"
    UNION ALL SELECT "event_date", TO_DATE("event_date",'YYYYMMDD'), "event_name", "user_pseudo_id"
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180730"
),

session_users AS (           -- users with a session_start in the cohort window
    SELECT DISTINCT "user_pseudo_id"
    FROM union_events
    WHERE "event_name" = 'session_start'
      AND "event_date" BETWEEN '20180702' AND '20180716'
),

initial_quickplay AS (        -- first quick-play event during the window for each user & type
    SELECT 
        ue."user_pseudo_id",
        ue."event_name"                       AS qp_event,
        MIN(ue.event_date_d)                  AS init_date
    FROM union_events ue
    WHERE ue."event_name" LIKE '%_quickplay'
      AND ue."event_date" BETWEEN '20180702' AND '20180716'
      AND ue."user_pseudo_id" IN (SELECT "user_pseudo_id" FROM session_users)
    GROUP BY ue."user_pseudo_id", ue."event_name"
),

retention AS (                 -- did the user perform the same quick-play exactly 14 days later?
    SELECT 
        iq."user_pseudo_id",
        iq.qp_event,
        CASE 
            WHEN EXISTS (
                SELECT 1
                FROM union_events ue2
                WHERE ue2."user_pseudo_id" = iq."user_pseudo_id"
                  AND ue2."event_name"     = iq.qp_event
                  AND ue2.event_date_d     = DATEADD(day,14,iq.init_date)
            ) THEN 1 ELSE 0 
        END AS retained
    FROM initial_quickplay iq
)

SELECT 
    qp_event                       AS quickplay_event,
    COUNT(*)                       AS cohort_size,
    SUM(retained)                  AS retained_users,
    ROUND(SUM(retained)::FLOAT / COUNT(*), 4) AS retention_rate
FROM retention
GROUP BY qp_event
ORDER BY retention_rate DESC NULLS LAST;