SELECT
  ROUND((("curr"."race_asian" - "base"."race_asian") / "base"."race_asian") * 100, 4) AS "Asian_Growth_Rate",
  ROUND((("curr"."race_black" - "base"."race_black") / "base"."race_black") * 100, 4) AS "Black_Growth_Rate",
  ROUND((("curr"."race_hispanic_latinx" - "base"."race_hispanic_latinx") / "base"."race_hispanic_latinx") * 100, 4) AS "Latinx_Growth_Rate",
  ROUND((("curr"."race_native_american" - "base"."race_native_american") / "base"."race_native_american") * 100, 4) AS "Native_American_Growth_Rate",
  ROUND((("curr"."race_white" - "base"."race_white") / "base"."race_white") * 100, 4) AS "White_Growth_Rate",
  ROUND((("curr"."gender_us_women" - "base"."gender_us_women") / "base"."gender_us_women") * 100, 4) AS "US_Women_Growth_Rate",
  ROUND((("curr"."gender_us_men" - "base"."gender_us_men") / "base"."gender_us_men") * 100, 4) AS "US_Men_Growth_Rate",
  ROUND((("curr"."gender_global_women" - "base"."gender_global_women") / "base"."gender_global_women") * 100, 4) AS "Global_Women_Growth_Rate",
  ROUND((("curr"."gender_global_men" - "base"."gender_global_men") / "base"."gender_global_men") * 100, 4) AS "Global_Men_Growth_Rate"
FROM
  (
    SELECT *
    FROM "GOOGLE_DEI"."GOOGLE_DEI"."DAR_NON_INTERSECTIONAL_REPRESENTATION"
    WHERE "workforce" = 'overall' AND "report_year" = 2014
  ) AS "base"
CROSS JOIN
  (
    SELECT *
    FROM "GOOGLE_DEI"."GOOGLE_DEI"."DAR_NON_INTERSECTIONAL_REPRESENTATION"
    WHERE "workforce" = 'overall' AND "report_year" = 2024
  ) AS "curr";