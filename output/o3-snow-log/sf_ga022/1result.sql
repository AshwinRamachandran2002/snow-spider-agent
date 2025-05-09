WITH ALL_EVENTS AS (

    /* -----------------------------------------------------------------
       Explicitly UNION ALL every daily table that can contain activity
       from the cohort (01-Sep-2018 through 30-Sep-2018, inclusive)
    ----------------------------------------------------------------- */
    SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180901"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180902"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180903"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180904"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180905"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180906"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180907"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180908"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180909"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180910"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180911"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180912"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180913"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180914"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180915"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180916"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180917"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180918"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180919"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180920"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180921"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180922"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180923"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180924"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180925"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180926"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180927"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180928"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180929"
    UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180930"

), EVENTS AS (

    /* ---------------------------------------------------------------
       Convert micro-seconds to TIMESTAMP and shift to Asia/Shanghai
    --------------------------------------------------------------- */
    SELECT
        "user_pseudo_id"                                              AS user_id,
        "event_name",
        CONVERT_TIMEZONE('UTC','Asia/Shanghai',
                         TO_TIMESTAMP_NTZ("event_timestamp" / 1000000)
                        )                                              AS ts_sh
    FROM ALL_EVENTS
), FIRST_OPEN AS (

    /* -----------------------------------
       Earliest first_open per each user
    ----------------------------------- */
    SELECT
        user_id,
        MIN(ts_sh) AS first_open_ts
    FROM EVENTS
    WHERE "event_name" = 'first_open'
    GROUP BY user_id
), COHORT AS (

    /* -----------------------------------------------------------
       Users whose FIRST open is 01-Sep-2018 – 07-Sep-2018 (Shanghai)
    ----------------------------------------------------------- */
    SELECT
        user_id,
        first_open_ts
    FROM FIRST_OPEN
    WHERE first_open_ts >= '2018-09-01 00:00:00'::TIMESTAMP
      AND first_open_ts <  '2018-09-08 00:00:00'::TIMESTAMP
), USER_ACTIVITY AS (

    /* ----------------------------------------------------------
       Every post-first_open event of cohort users
    ---------------------------------------------------------- */
    SELECT
        c.user_id,
        DATEDIFF('day', c.first_open_ts, e.ts_sh) AS days_since_open
    FROM COHORT          AS c
    JOIN EVENTS          AS e
      ON e.user_id = c.user_id
     AND e.ts_sh  > c.first_open_ts          -- only after first_open
), RETENTION_FLAGS AS (

    /* ---------------------------------------------------------
       One row per user with week-level retention flags
    --------------------------------------------------------- */
    SELECT
        user_id,
        MAX(CASE WHEN days_since_open BETWEEN  1 AND  7 THEN 1 ELSE 0 END) AS wk1,
        MAX(CASE WHEN days_since_open BETWEEN  8 AND 14 THEN 1 ELSE 0 END) AS wk2,
        MAX(CASE WHEN days_since_open BETWEEN 15 AND 21 THEN 1 ELSE 0 END) AS wk3
    FROM USER_ACTIVITY
    GROUP BY user_id
), SUMMARY AS (

    SELECT
        (SELECT COUNT(*) FROM COHORT)                       AS cohort_size,
        SUM(wk1)                                            AS users_wk1,
        SUM(wk2)                                            AS users_wk2,
        SUM(wk3)                                            AS users_wk3
    FROM RETENTION_FLAGS
)

SELECT
    cohort_size,
    ROUND(users_wk1 / cohort_size::FLOAT, 4) AS week_1_retention_rate,
    ROUND(users_wk2 / cohort_size::FLOAT, 4) AS week_2_retention_rate,
    ROUND(users_wk3 / cohort_size::FLOAT, 4) AS week_3_retention_rate
FROM SUMMARY;