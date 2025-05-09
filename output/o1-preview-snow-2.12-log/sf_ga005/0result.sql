WITH
all_events AS (
  SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180709"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180710"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180711"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180712"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180713"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180714"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180715"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180716"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180717"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180718"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180719"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180720"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180721"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180722"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180723"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180724"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180725"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180726"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180727"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180728"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180729"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180730"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180731"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180801"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180802"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180803"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180804"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180805"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180806"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180807"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180808"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180809"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180810"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180811"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180812"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180813"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180814"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180815"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180816"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180817"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180818"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180819"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180820"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180821"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180822"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180823"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180824"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180825"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180826"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180827"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180828"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180829"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180830"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180831"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180901"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180902"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180903"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180904"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180905"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180906"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180907"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180908"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180909"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180910"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180911"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180912"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180913"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180914"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180915"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180916"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180917"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180918"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180919"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180920"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180921"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180922"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180923"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180924"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180925"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180926"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180927"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180928"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180929"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180930"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20181001"
  UNION ALL SELECT "user_pseudo_id", "event_date" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20181002"
),
all_events_with_weeks AS (
  SELECT "user_pseudo_id",
         TO_DATE("event_date", 'YYYYMMDD') AS "event_date",
         DATE_TRUNC('WEEK', TO_DATE("event_date", 'YYYYMMDD')) AS "event_week"
  FROM all_events
),
first_event_per_user AS (
  SELECT "user_pseudo_id", MIN("event_date") AS "first_event_date"
  FROM all_events_with_weeks
  GROUP BY "user_pseudo_id"
),
user_cohorts AS (
  SELECT "user_pseudo_id",
         "first_event_date",
         DATE_TRUNC('WEEK', "first_event_date") AS "cohort_week"
  FROM first_event_per_user
),
activity_weeks AS (
  SELECT uc."user_pseudo_id",
         uc."cohort_week",
         aw."event_week",
         DATEDIFF('WEEK', uc."cohort_week", aw."event_week") AS "week_number"
  FROM user_cohorts uc
  JOIN all_events_with_weeks aw
    ON uc."user_pseudo_id" = aw."user_pseudo_id"
),
cohorts_data AS (
  SELECT "cohort_week", COUNT(DISTINCT "user_pseudo_id") AS "cohort_size"
  FROM user_cohorts
  GROUP BY "cohort_week"
),
retention_data AS (
  SELECT "cohort_week", "week_number", COUNT(DISTINCT "user_pseudo_id") AS "users_retained"
  FROM activity_weeks
  WHERE "week_number" IN (0,1,2)
  GROUP BY "cohort_week", "week_number"
),
final_table AS (
  SELECT
    cd."cohort_week",
    cd."cohort_size",
    COALESCE(MAX(CASE WHEN rd."week_number" = 0 THEN rd."users_retained" END), 0) AS "Week0_users",
    COALESCE(MAX(CASE WHEN rd."week_number" = 1 THEN rd."users_retained" END), 0) AS "Week1_users",
    COALESCE(MAX(CASE WHEN rd."week_number" = 2 THEN rd."users_retained" END), 0) AS "Week2_users"
  FROM
    cohorts_data cd
  LEFT JOIN
    retention_data rd
  ON
    cd."cohort_week" = rd."cohort_week"
  GROUP BY
    cd."cohort_week", cd."cohort_size"
)
SELECT
  TO_CHAR("cohort_week", 'YYYY-MM-DD') || ' to ' || TO_CHAR(DATEADD('day',6,"cohort_week"),'YYYY-MM-DD') AS "Cohort_Week",
  100 AS "Week0_Retention_Rate",
  ROUND(("Week1_users" / "cohort_size") * 100.0, 4) AS "Week1_Retention_Rate",
  ROUND(("Week2_users" / "cohort_size") * 100.0, 4) AS "Week2_Retention_Rate"
FROM final_table
ORDER BY "cohort_week";