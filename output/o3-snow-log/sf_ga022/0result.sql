/*  Weekly retention for users whose very first “first_open” happened
    between 1 Sep 2018 00:00 and 7 Sep 2018 23:59:59 (Asia/Shanghai).
    Retention windows are
      Week-1 : 08–14 Sep
      Week-2 : 15–21 Sep
      Week-3 : 22–28 Sep
*/

WITH all_events AS (
    SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180901" UNION ALL
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
    SELECT "user_pseudo_id","event_name","event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180928"
),

events_shanghai AS (
    SELECT
        "user_pseudo_id",
        "event_name",
        CONVERT_TIMEZONE('UTC','Asia/Shanghai',TO_TIMESTAMP_NTZ("event_timestamp"/1000000))                 AS event_time_sh
    FROM all_events
),

/* Cohort = first-time users in 1-7 Sep (Shanghai time) */
cohort_users AS (
    SELECT DISTINCT "user_pseudo_id"
    FROM   events_shanghai
    WHERE  "event_name" = 'first_open'
      AND  event_time_sh >= '2018-09-01'::timestamp
      AND  event_time_sh <  '2018-09-08'::timestamp
),

/* Mark whether each cohort user returned in Weeks 1-3 */
user_activity AS (
    SELECT
        cu."user_pseudo_id",
        MAX( CASE WHEN event_time_sh >= '2018-09-08'::timestamp
                       AND event_time_sh <  '2018-09-15'::timestamp THEN 1 ELSE 0 END ) AS wk1,
        MAX( CASE WHEN event_time_sh >= '2018-09-15'::timestamp
                       AND event_time_sh <  '2018-09-22'::timestamp THEN 1 ELSE 0 END ) AS wk2,
        MAX( CASE WHEN event_time_sh >= '2018-09-22'::timestamp
                       AND event_time_sh <  '2018-09-29'::timestamp THEN 1 ELSE 0 END ) AS wk3
    FROM cohort_users           cu
    LEFT JOIN events_shanghai   es
           ON cu."user_pseudo_id" = es."user_pseudo_id"
    GROUP BY cu."user_pseudo_id"
),

/* Aggregate & calculate retention percentages */
summary AS (
    SELECT
        COUNT(*)                 AS cohort_size,
        SUM(wk1)                 AS wk1_users,
        SUM(wk2)                 AS wk2_users,
        SUM(wk3)                 AS wk3_users
    FROM user_activity
)

SELECT
    cohort_size,
    ROUND( wk1_users / cohort_size :: FLOAT , 4 ) AS week1_retention_rate,
    ROUND( wk2_users / cohort_size :: FLOAT , 4 ) AS week2_retention_rate,
    ROUND( wk3_users / cohort_size :: FLOAT , 4 ) AS week3_retention_rate
FROM summary;