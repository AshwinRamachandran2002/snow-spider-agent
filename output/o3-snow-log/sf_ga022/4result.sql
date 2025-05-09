/* Weekly retention (weeks 1-3) for users whose first_open occurred
   between 1–7 Sep 2018 (Asia/Shanghai)                                   */

WITH
raw AS (   /* all September-2018 events, minimal columns                 */
    SELECT "user_pseudo_id","event_name","event_timestamp" AS event_ts_micro
      FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180901" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180902" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180903" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180904" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180905" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180906" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180907" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180908" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180909" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180910" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180911" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180912" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180913" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180914" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180915" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180916" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180917" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180918" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180919" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180920" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180921" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180922" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180923" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180924" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180925" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180926" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180927" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180928" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180929" UNION ALL
    SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180930"
),
events AS (  /* convert epoch-µs (UTC) to Shanghai time                  */
    SELECT
        "user_pseudo_id"                                            AS user_id,
        "event_name"                                                AS event_name,
        CONVERT_TIMEZONE(
            'UTC',
            'Asia/Shanghai',
            TO_TIMESTAMP_NTZ(event_ts_micro / 1000000)
        )                                                           AS event_time_sh
    FROM raw
),
cohort AS (  /* users whose first_open was 1-7 Sep 2018 (week 0)         */
    SELECT DISTINCT user_id
    FROM events
    WHERE event_name = 'first_open'
      AND event_time_sh >= '2018-09-01 00:00:00+08:00'::timestamp_tz
      AND event_time_sh <  '2018-09-08 00:00:00+08:00'::timestamp_tz
),
cohort_size AS ( SELECT COUNT(*) AS total_users FROM cohort ),

activity AS (  /* cohort members’ activity, bucketed into week index     */
    SELECT
        e.user_id,
        FLOOR(
            DATEDIFF('day',
                     '2018-09-01'::date,
                     e.event_time_sh) / 7
        ) AS week_index
    FROM events e
    JOIN cohort c ON e.user_id = c.user_id
    WHERE DATEDIFF('day','2018-09-01'::date, e.event_time_sh) BETWEEN 0 AND 27
),
retention AS (
    SELECT week_index, COUNT(DISTINCT user_id) AS active_users
    FROM activity
    GROUP BY week_index
)

SELECT
    cs.total_users                                                          AS cohort_users,
    ROUND(100.0 * COALESCE(r1.active_users,0) / cs.total_users, 4)          AS week1_retention_rate,
    ROUND(100.0 * COALESCE(r2.active_users,0) / cs.total_users, 4)          AS week2_retention_rate,
    ROUND(100.0 * COALESCE(r3.active_users,0) / cs.total_users, 4)          AS week3_retention_rate
FROM cohort_size cs
LEFT JOIN retention r1 ON r1.week_index = 1
LEFT JOIN retention r2 ON r2.week_index = 2
LEFT JOIN retention r3 ON r3.week_index = 3;