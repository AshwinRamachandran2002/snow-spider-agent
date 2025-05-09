WITH
data_2014 AS (
  SELECT
    "race_asian" AS "race_asian_2014",
    "race_black" AS "race_black_2014",
    "race_hispanic_latinx" AS "race_hispanic_latinx_2014",
    "race_native_american" AS "race_native_american_2014",
    "race_white" AS "race_white_2014",
    "gender_us_women" AS "gender_us_women_2014",
    "gender_us_men" AS "gender_us_men_2014",
    "gender_global_women" AS "gender_global_women_2014",
    "gender_global_men" AS "gender_global_men_2014"
  FROM "GOOGLE_DEI"."GOOGLE_DEI"."DAR_NON_INTERSECTIONAL_REPRESENTATION"
  WHERE "workforce" = 'overall' AND "report_year" = 2014
),
data_2024 AS (
  SELECT
    "race_asian" AS "race_asian_2024",
    "race_black" AS "race_black_2024",
    "race_hispanic_latinx" AS "race_hispanic_latinx_2024",
    "race_native_american" AS "race_native_american_2024",
    "race_white" AS "race_white_2024",
    "gender_us_women" AS "gender_us_women_2024",
    "gender_us_men" AS "gender_us_men_2024",
    "gender_global_women" AS "gender_global_women_2024",
    "gender_global_men" AS "gender_global_men_2024"
  FROM "GOOGLE_DEI"."GOOGLE_DEI"."DAR_NON_INTERSECTIONAL_REPRESENTATION"
  WHERE "workforce" = 'overall' AND "report_year" = 2024
)
SELECT
  ROUND((("race_asian_2024" - "race_asian_2014") / NULLIF("race_asian_2014", 0)) * 100, 4) AS "Asian_Growth_Rate",
  ROUND((("race_black_2024" - "race_black_2014") / NULLIF("race_black_2014", 0)) * 100, 4) AS "Black_Growth_Rate",
  ROUND((("race_hispanic_latinx_2024" - "race_hispanic_latinx_2014") / NULLIF("race_hispanic_latinx_2014", 0)) * 100, 4) AS "Latinx_Growth_Rate",
  ROUND((("race_native_american_2024" - "race_native_american_2014") / NULLIF("race_native_american_2014", 0)) * 100, 4) AS "Native_American_Growth_Rate",
  ROUND((("race_white_2024" - "race_white_2014") / NULLIF("race_white_2014", 0)) * 100, 4) AS "White_Growth_Rate",
  ROUND((("gender_us_women_2024" - "gender_us_women_2014") / NULLIF("gender_us_women_2014", 0)) * 100, 4) AS "US_Women_Growth_Rate",
  ROUND((("gender_us_men_2024" - "gender_us_men_2014") / NULLIF("gender_us_men_2014", 0)) * 100, 4) AS "US_Men_Growth_Rate",
  ROUND((("gender_global_women_2024" - "gender_global_women_2014") / NULLIF("gender_global_women_2014", 0)) * 100, 4) AS "Global_Women_Growth_Rate",
  ROUND((("gender_global_men_2024" - "gender_global_men_2014") / NULLIF("gender_global_men_2014", 0)) * 100, 4) AS "Global_Men_Growth_Rate"
FROM data_2014, data_2024;