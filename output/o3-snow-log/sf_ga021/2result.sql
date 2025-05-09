/*------------------------------------------------------------
 Two-week (14-20 days) retention for every “*_quickplay” event
 Cohort window : 02-Jul-2018 – 16-Jul-2018
 Data window   : 02-Jul-2018 – 06-Aug-2018  (cohort + 20 days)
------------------------------------------------------------*/
WITH union_events AS (           -- all days needed
    SELECT TO_DATE("event_date",'YYYYMMDD')          AS event_date ,
           "event_name"                              AS event_name ,
           "user_pseudo_id"                          AS user_pseudo_id
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180702"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"event_name","user_pseudo_id"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180703"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"event_name","user_pseudo_id"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180704"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"event_name","user_pseudo_id"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180705"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"event_name","user_pseudo_id"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180706"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"event_name","user_pseudo_id"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180707"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"event_name","user_pseudo_id"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180708"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"event_name","user_pseudo_id"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180709"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"event_name","user_pseudo_id"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180710"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"event_name","user_pseudo_id"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180711"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"event_name","user_pseudo_id"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180712"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"event_name","user_pseudo_id"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180713"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"event_name","user_pseudo_id"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180714"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"event_name","user_pseudo_id"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180715"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"event_name","user_pseudo_id"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180716"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"event_name","user_pseudo_id"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180717"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"event_name","user_pseudo_id"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180718"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"event_name","user_pseudo_id"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180719"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"event_name","user_pseudo_id"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180720"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"event_name","user_pseudo_id"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180721"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"event_name","user_pseudo_id"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180722"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"event_name","user_pseudo_id"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180723"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"event_name","user_pseudo_id"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180724"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"event_name","user_pseudo_id"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180725"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"event_name","user_pseudo_id"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180726"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"event_name","user_pseudo_id"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180727"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"event_name","user_pseudo_id"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180728"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"event_name","user_pseudo_id"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180729"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"event_name","user_pseudo_id"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180730"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"event_name","user_pseudo_id"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180731"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"event_name","user_pseudo_id"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180801"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"event_name","user_pseudo_id"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180802"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"event_name","user_pseudo_id"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180803"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"event_name","user_pseudo_id"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180804"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"event_name","user_pseudo_id"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180805"
    UNION ALL SELECT TO_DATE("event_date",'YYYYMMDD'),"event_name","user_pseudo_id"
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180806"
),

-- users with a session in the cohort window
session_users AS (
    SELECT DISTINCT user_pseudo_id
    FROM union_events
    WHERE event_name = 'session_start'
      AND event_date BETWEEN DATE '2018-07-02' AND DATE '2018-07-16'
),

-- first “*_quickplay” per user & type within cohort window
cohort AS (
    SELECT
        user_pseudo_id,
        event_name                  AS quickplay_event,
        MIN(event_date)             AS initial_date
    FROM union_events
    WHERE event_name LIKE '%\\_quickplay' ESCAPE '\\'
      AND event_date BETWEEN DATE '2018-07-02' AND DATE '2018-07-16'
      AND user_pseudo_id IN (SELECT user_pseudo_id FROM session_users)
    GROUP BY user_pseudo_id, event_name
),

-- users who returned 14-20 days later (any event)
retained AS (
    SELECT DISTINCT
           c.user_pseudo_id
    FROM cohort c
    JOIN union_events u
      ON u.user_pseudo_id = c.user_pseudo_id
     AND u.event_date BETWEEN DATEADD(DAY,14,c.initial_date)
                         AND DATEADD(DAY,20,c.initial_date)
)

-- final retention calculation
SELECT
       c.quickplay_event                          AS quickplay_event_type,
       COUNT(DISTINCT c.user_pseudo_id)           AS cohort_size,
       COUNT(DISTINCT r.user_pseudo_id)           AS retained_users,
       ROUND(
             CAST(COUNT(DISTINCT r.user_pseudo_id) AS FLOAT)
           / NULLIF(COUNT(DISTINCT c.user_pseudo_id), 0)
       ,4)                                        AS retention_rate
FROM cohort c
LEFT JOIN retained r
       ON c.user_pseudo_id = r.user_pseudo_id
GROUP BY c.quickplay_event
ORDER BY retention_rate DESC NULLS LAST;