WITH

-- Workforce Hiring Percentages
workforce_hiring AS (
  SELECT
    'Asian' AS Category,
    ROUND("race_asian", 4) AS Workforce_Hiring_Percentage
  FROM "GOOGLE_DEI"."GOOGLE_DEI"."DAR_NON_INTERSECTIONAL_HIRING"
  WHERE "report_year" = 2021 AND "workforce" = 'overall'
  UNION ALL
  SELECT
    'Black' AS Category,
    ROUND("race_black", 4) AS Workforce_Hiring_Percentage
  FROM "GOOGLE_DEI"."GOOGLE_DEI"."DAR_NON_INTERSECTIONAL_HIRING"
  WHERE "report_year" = 2021 AND "workforce" = 'overall'
  UNION ALL
  SELECT
    'Hispanic/Latinx' AS Category,
    ROUND("race_hispanic_latinx", 4) AS Workforce_Hiring_Percentage
  FROM "GOOGLE_DEI"."GOOGLE_DEI"."DAR_NON_INTERSECTIONAL_HIRING"
  WHERE "report_year" = 2021 AND "workforce" = 'overall'
  UNION ALL
  SELECT
    'White' AS Category,
    ROUND("race_white", 4) AS Workforce_Hiring_Percentage
  FROM "GOOGLE_DEI"."GOOGLE_DEI"."DAR_NON_INTERSECTIONAL_HIRING"
  WHERE "report_year" = 2021 AND "workforce" = 'overall'
  UNION ALL
  SELECT
    'U.S. Women' AS Category,
    ROUND("gender_us_women", 4) AS Workforce_Hiring_Percentage
  FROM "GOOGLE_DEI"."GOOGLE_DEI"."DAR_NON_INTERSECTIONAL_HIRING"
  WHERE "report_year" = 2021 AND "workforce" = 'overall'
  UNION ALL
  SELECT
    'U.S. Men' AS Category,
    ROUND("gender_us_men", 4) AS Workforce_Hiring_Percentage
  FROM "GOOGLE_DEI"."GOOGLE_DEI"."DAR_NON_INTERSECTIONAL_HIRING"
  WHERE "report_year" = 2021 AND "workforce" = 'overall'
),

-- Workforce Representation Percentages
workforce_representation AS (
  SELECT
    'Asian' AS Category,
    ROUND("race_asian", 4) AS Workforce_Representation_Percentage
  FROM "GOOGLE_DEI"."GOOGLE_DEI"."DAR_NON_INTERSECTIONAL_REPRESENTATION"
  WHERE "report_year" = 2021 AND "workforce" = 'overall'
  UNION ALL
  SELECT
    'Black' AS Category,
    ROUND("race_black", 4) AS Workforce_Representation_Percentage
  FROM "GOOGLE_DEI"."GOOGLE_DEI"."DAR_NON_INTERSECTIONAL_REPRESENTATION"
  WHERE "report_year" = 2021 AND "workforce" = 'overall'
  UNION ALL
  SELECT
    'Hispanic/Latinx' AS Category,
    ROUND("race_hispanic_latinx", 4) AS Workforce_Representation_Percentage
  FROM "GOOGLE_DEI"."GOOGLE_DEI"."DAR_NON_INTERSECTIONAL_REPRESENTATION"
  WHERE "report_year" = 2021 AND "workforce" = 'overall'
  UNION ALL
  SELECT
    'White' AS Category,
    ROUND("race_white", 4) AS Workforce_Representation_Percentage
  FROM "GOOGLE_DEI"."GOOGLE_DEI"."DAR_NON_INTERSECTIONAL_REPRESENTATION"
  WHERE "report_year" = 2021 AND "workforce" = 'overall'
  UNION ALL
  SELECT
    'U.S. Women' AS Category,
    ROUND("gender_us_women", 4) AS Workforce_Representation_Percentage
  FROM "GOOGLE_DEI"."GOOGLE_DEI"."DAR_NON_INTERSECTIONAL_REPRESENTATION"
  WHERE "report_year" = 2021 AND "workforce" = 'overall'
  UNION ALL
  SELECT
    'U.S. Men' AS Category,
    ROUND("gender_us_men", 4) AS Workforce_Representation_Percentage
  FROM "GOOGLE_DEI"."GOOGLE_DEI"."DAR_NON_INTERSECTIONAL_REPRESENTATION"
  WHERE "report_year" = 2021 AND "workforce" = 'overall'
),

-- BLS Sector Percentages
bls_sector AS (
  SELECT
    'Asian' AS Category,
    ROUND(AVG("percent_asian"), 4) AS BLS_Sector_Percentage
  FROM "GOOGLE_DEI"."BLS"."CPSAAT18"
  WHERE "year" = 2021
    AND "industry" IN ('Computer and peripheral equipment manufacturing', 'Computer systems design and related services')
  UNION ALL
  SELECT
    'Black' AS Category,
    ROUND(AVG("percent_black_or_african_american"), 4) AS BLS_Sector_Percentage
  FROM "GOOGLE_DEI"."BLS"."CPSAAT18"
  WHERE "year" = 2021
    AND "industry" IN ('Computer and peripheral equipment manufacturing', 'Computer systems design and related services')
  UNION ALL
  SELECT
    'Hispanic/Latinx' AS Category,
    ROUND(AVG("percent_hispanic_or_latino"), 4) AS BLS_Sector_Percentage
  FROM "GOOGLE_DEI"."BLS"."CPSAAT18"
  WHERE "year" = 2021
    AND "industry" IN ('Computer and peripheral equipment manufacturing', 'Computer systems design and related services')
  UNION ALL
  SELECT
    'White' AS Category,
    ROUND(AVG("percent_white"), 4) AS BLS_Sector_Percentage
  FROM "GOOGLE_DEI"."BLS"."CPSAAT18"
  WHERE "year" = 2021
    AND "industry" IN ('Computer and peripheral equipment manufacturing', 'Computer systems design and related services')
  UNION ALL
  SELECT
    'U.S. Women' AS Category,
    ROUND(AVG("percent_women"), 4) AS BLS_Sector_Percentage
  FROM "GOOGLE_DEI"."BLS"."CPSAAT18"
  WHERE "year" = 2021
    AND "industry" IN ('Computer and peripheral equipment manufacturing', 'Computer systems design and related services')
  UNION ALL
  SELECT
    'U.S. Men' AS Category,
    ROUND(1 - AVG("percent_women"), 4) AS BLS_Sector_Percentage
  FROM "GOOGLE_DEI"."BLS"."CPSAAT18"
  WHERE "year" = 2021
    AND "industry" IN ('Computer and peripheral equipment manufacturing', 'Computer systems design and related services')
)

SELECT
  wh.Category,
  wh.Workforce_Hiring_Percentage,
  wr.Workforce_Representation_Percentage,
  b.BLS_Sector_Percentage
FROM workforce_hiring wh
JOIN workforce_representation wr ON wh.Category = wr.Category
JOIN bls_sector b ON wh.Category = b.Category
ORDER BY
  CASE
    WHEN wh.Category = 'Asian' THEN 1
    WHEN wh.Category = 'Black' THEN 2
    WHEN wh.Category = 'Hispanic/Latinx' THEN 3
    WHEN wh.Category = 'White' THEN 4
    WHEN wh.Category = 'U.S. Women' THEN 5
    WHEN wh.Category = 'U.S. Men' THEN 6
    ELSE 7
  END;