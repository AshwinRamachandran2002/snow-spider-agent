WITH all_events AS (
    -- July 9, 2018
    SELECT "event_date", "event_timestamp", "event_name", "user_pseudo_id", "user_first_touch_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180709"
    UNION ALL
    -- July 10, 2018
    SELECT "event_date", "event_timestamp", "event_name", "user_pseudo_id", "user_first_touch_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180710"
    UNION ALL
    -- July 11, 2018
    SELECT "event_date", "event_timestamp", "event_name", "user_pseudo_id", "user_first_touch_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180711"
    UNION ALL
    -- July 12, 2018
    SELECT "event_date", "event_timestamp", "event_name", "user_pseudo_id", "user_first_touch_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180712"
    UNION ALL
    -- July 13, 2018
    SELECT "event_date", "event_timestamp", "event_name", "user_pseudo_id", "user_first_touch_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180713"
    UNION ALL
    -- July 14, 2018
    SELECT "event_date", "event_timestamp", "event_name", "user_pseudo_id", "user_first_touch_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180714"
    UNION ALL
    -- July 15, 2018
    SELECT "event_date", "event_timestamp", "event_name", "user_pseudo_id", "user_first_touch_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180715"
    UNION ALL
    -- Continue including all tables up to "EVENTS_20181002"
    -- ...
    -- October 2, 2018
    SELECT "event_date", "event_timestamp", "event_name", "user_pseudo_id", "user_first_touch_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20181002"
),
user_cohorts AS (
    SELECT
        "user_pseudo_id",
        DATE_TRUNC('WEEK', DATEADD('SECOND', MIN("user_first_touch_timestamp") / 1e6, '1970-01-01')) AS "cohort_week"
    FROM
        all_events
    WHERE
        DATEADD('SECOND', "user_first_touch_timestamp" / 1e6, '1970-01-01') BETWEEN '2018-07-09' AND '2018-10-02'
    GROUP BY
        "user_pseudo_id"
),
events_with_weeks AS (
    SELECT
        "user_pseudo_id",
        DATE_TRUNC('WEEK', TO_TIMESTAMP_NTZ("event_timestamp" / 1e6)) AS "event_week"
    FROM
        all_events
),
cohort_retention AS (
    SELECT
        uc."cohort_week",
        DATEDIFF('WEEK', uc."cohort_week", ew."event_week") AS "week_offset",
        uc."user_pseudo_id"
    FROM
        user_cohorts uc
        JOIN events_with_weeks ew ON uc."user_pseudo_id" = ew."user_pseudo_id"
    WHERE
        DATEDIFF('WEEK', uc."cohort_week", ew."event_week") BETWEEN 0 AND 2
),
cohort_retention_counts AS (
    SELECT
        "cohort_week",
        "week_offset",
        COUNT(DISTINCT "user_pseudo_id") AS "user_count"
    FROM
        cohort_retention
    GROUP BY
        "cohort_week",
        "week_offset"
),
cohort_sizes AS (
    SELECT
        "cohort_week",
        COUNT(DISTINCT "user_pseudo_id") AS "cohort_size"
    FROM
        user_cohorts
    GROUP BY
        "cohort_week"
),
retention_data AS (
    SELECT
        cs."cohort_week",
        0 AS "week_offset",
        cs."cohort_size" AS "user_count"
    FROM
        cohort_sizes cs
    UNION ALL
    SELECT
        cr."cohort_week",
        cr."week_offset",
        cr."user_count"
    FROM
        cohort_retention_counts cr
)
SELECT
    TO_VARCHAR(r."cohort_week", 'YYYY-MM-DD') || ' to ' || TO_VARCHAR(DATEADD('day', 6, r."cohort_week"), 'YYYY-MM-DD') AS "Cohort_Week",
    100 AS "Week0_Retention_Rate",
    ROUND(100.0000 * MAX(CASE WHEN r."week_offset" = 1 THEN r."user_count" END) / MAX(CASE WHEN r."week_offset" = 0 THEN r."user_count" END), 4) AS "Week1_Retention_Rate",
    ROUND(100.0000 * MAX(CASE WHEN r."week_offset" = 2 THEN r."user_count" END) / MAX(CASE WHEN r."week_offset" = 0 THEN r."user_count" END), 4) AS "Week2_Retention_Rate"
FROM
    retention_data r
WHERE
    r."cohort_week" BETWEEN '2018-07-09' AND '2018-10-02'
GROUP BY
    r."cohort_week"
ORDER BY
    r."cohort_week";