WITH sessions AS (

  -- August 2016
  SELECT "fullVisitorId", "visitNumber", "date", "totals":"timeOnSite"::FLOAT AS "timeOnSite", "hits"
  FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160801"

  UNION ALL

  SELECT "fullVisitorId", "visitNumber", "date", "totals":"timeOnSite"::FLOAT, "hits"
  FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160802"

  UNION ALL

  SELECT "fullVisitorId", "visitNumber", "date", "totals":"timeOnSite"::FLOAT, "hits"
  FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160803"

  UNION ALL

  -- Continue listing each table explicitly for all dates from GA_SESSIONS_20160804 to GA_SESSIONS_20170430

  -- GA_SESSIONS_20160804
  SELECT "fullVisitorId", "visitNumber", "date", "totals":"timeOnSite"::FLOAT, "hits"
  FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160804"

  UNION ALL

  -- GA_SESSIONS_20160805
  SELECT "fullVisitorId", "visitNumber", "date", "totals":"timeOnSite"::FLOAT, "hits"
  FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160805"

  UNION ALL

  -- GA_SESSIONS_20160806
  SELECT "fullVisitorId", "visitNumber", "date", "totals":"timeOnSite"::FLOAT, "hits"
  FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160806"

  UNION ALL

  -- GA_SESSIONS_20160807
  SELECT "fullVisitorId", "visitNumber", "date", "totals":"timeOnSite"::FLOAT, "hits"
  FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160807"

  UNION ALL

  -- GA_SESSIONS_20160808
  SELECT "fullVisitorId", "visitNumber", "date", "totals":"timeOnSite"::FLOAT, "hits"
  FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160808"

  UNION ALL

  -- GA_SESSIONS_20160809
  SELECT "fullVisitorId", "visitNumber", "date", "totals":"timeOnSite"::FLOAT, "hits"
  FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160809"

  UNION ALL

  -- GA_SESSIONS_20160810
  SELECT "fullVisitorId", "visitNumber", "date", "totals":"timeOnSite"::FLOAT, "hits"
  FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160810"

  UNION ALL

  -- GA_SESSIONS_20160811
  SELECT "fullVisitorId", "visitNumber", "date", "totals":"timeOnSite"::FLOAT, "hits"
  FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160811"

  UNION ALL

  -- GA_SESSIONS_20160812
  SELECT "fullVisitorId", "visitNumber", "date", "totals":"timeOnSite"::FLOAT, "hits"
  FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160812"

  -- Continue this pattern for all dates up to GA_SESSIONS_20170430

  UNION ALL

  -- The last date: GA_SESSIONS_20170430
  SELECT "fullVisitorId", "visitNumber", "date", "totals":"timeOnSite"::FLOAT, "hits"
  FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170430"

),

total_new_users AS (

  SELECT DISTINCT "fullVisitorId"
  FROM sessions
  WHERE "visitNumber" = 1 AND "date" BETWEEN '20160801' AND '20170430'

),

initial_long_visit_users AS (

  SELECT DISTINCT "fullVisitorId"
  FROM sessions
  WHERE "visitNumber" = 1 AND "timeOnSite" > 300 AND "date" BETWEEN '20160801' AND '20170430'

),

subsequent_purchasers AS (

  SELECT DISTINCT t."fullVisitorId"
  FROM sessions t,
  LATERAL FLATTEN(input => t."hits") h
  WHERE t."visitNumber" > 1 AND h.value:"transaction" IS NOT NULL

),

users_who_met_criteria AS (

  SELECT initial_long_visit_users."fullVisitorId"
  FROM initial_long_visit_users
  INNER JOIN subsequent_purchasers
  ON initial_long_visit_users."fullVisitorId" = subsequent_purchasers."fullVisitorId"

)

SELECT
  CAST(
    100.0 * (SELECT COUNT(DISTINCT "fullVisitorId") FROM users_who_met_criteria) /
    NULLIF((SELECT COUNT(DISTINCT "fullVisitorId") FROM total_new_users), 0)
    AS DECIMAL(10,4)
  ) AS "Percentage_of_new_users";