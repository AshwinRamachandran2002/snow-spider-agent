WITH combined_events AS
(
    SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp"
    FROM
    (
        SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180702"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180703"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180704"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180705"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180706"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180707"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180708"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180709"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180710"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180711"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180712"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180713"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180714"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180715"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180716"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180717"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180718"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180719"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180720"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180721"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180722"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180723"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180724"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180725"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180726"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180727"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180728"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180729"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180730"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180731"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180801"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180802"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180803"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180804"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180805"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180806"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180807"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180808"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180809"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180810"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180811"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180812"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180813"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180814"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180815"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180816"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180817"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180818"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180819"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180820"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180821"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180822"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180823"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180824"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180825"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180826"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180827"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180828"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180829"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180830"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180831"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180901"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180902"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180903"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180904"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180905"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180906"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180907"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180908"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180909"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180910"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180911"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180912"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180913"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180914"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180915"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180916"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180917"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180918"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180919"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180920"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180921"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180922"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180923"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180924"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180925"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180926"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180927"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180928"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180929"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180930"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181001"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181002"
        UNION ALL SELECT "user_pseudo_id", "user_first_touch_timestamp", "event_timestamp" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181003"
    ) AS all_events
    WHERE "user_first_touch_timestamp" >= 1530489600000000  -- July 2, 2018 in microseconds
),
user_cohorts AS
(
    SELECT "user_pseudo_id",
           DATE_TRUNC('week', TO_TIMESTAMP_NTZ("user_first_touch_timestamp" / 1000000)) AS "cohort_week_start"
    FROM combined_events
    GROUP BY "user_pseudo_id", "user_first_touch_timestamp"
),
user_retention AS
(
    SELECT DISTINCT uc."user_pseudo_id", uc."cohort_week_start"
    FROM user_cohorts uc
    JOIN combined_events ce ON uc."user_pseudo_id" = ce."user_pseudo_id"
    WHERE TO_TIMESTAMP_NTZ(ce."event_timestamp" / 1000000) >= (uc."cohort_week_start" + INTERVAL '7 DAY')
      AND TO_TIMESTAMP_NTZ(ce."event_timestamp" / 1000000) < (uc."cohort_week_start" + INTERVAL '35 DAY')
      AND DATE_TRUNC('week', TO_TIMESTAMP_NTZ(ce."event_timestamp" / 1000000)) >= uc."cohort_week_start" + INTERVAL '7 DAY'
      AND DATE_TRUNC('week', TO_TIMESTAMP_NTZ(ce."event_timestamp" / 1000000)) <= uc."cohort_week_start" + INTERVAL '28 DAY'
),
cohort_activity AS
(
    SELECT "cohort_week_start", COUNT(DISTINCT "user_pseudo_id") AS "active_users_remaining"
    FROM user_retention
    GROUP BY "cohort_week_start"
)
SELECT TO_CHAR("cohort_week_start", 'YYYY-MM-DD') AS "Week_Start_Date"
FROM cohort_activity
ORDER BY "active_users_remaining" DESC NULLS LAST
LIMIT 1;