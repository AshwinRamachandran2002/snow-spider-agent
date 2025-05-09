WITH google_data AS (
  SELECT
    'Google' AS Data_Source,
    'Overall Workforce' AS Industry,
    INITCAP("gender_us") AS Gender,
    'Asian' AS Race,
    ROUND("race_asian", 4) AS Percentage
  FROM
    "GOOGLE_DEI"."GOOGLE_DEI"."DAR_INTERSECTIONAL_REPRESENTATION"
  WHERE
    "report_year" = 2021
    AND LOWER("workforce") = 'overall'
    AND LOWER("gender_us") IN ('women', 'men')

  UNION ALL

  SELECT
    'Google' AS Data_Source,
    'Overall Workforce' AS Industry,
    INITCAP("gender_us") AS Gender,
    'Black' AS Race,
    ROUND("race_black", 4) AS Percentage
  FROM
    "GOOGLE_DEI"."GOOGLE_DEI"."DAR_INTERSECTIONAL_REPRESENTATION"
  WHERE
    "report_year" = 2021
    AND LOWER("workforce") = 'overall'
    AND LOWER("gender_us") IN ('women', 'men')

  UNION ALL

  SELECT
    'Google' AS Data_Source,
    'Overall Workforce' AS Industry,
    INITCAP("gender_us") AS Gender,
    'Hispanic/Latinx' AS Race,
    ROUND("race_hispanic_latinx", 4) AS Percentage
  FROM
    "GOOGLE_DEI"."GOOGLE_DEI"."DAR_INTERSECTIONAL_REPRESENTATION"
  WHERE
    "report_year" = 2021
    AND LOWER("workforce") = 'overall'
    AND LOWER("gender_us") IN ('women', 'men')

  UNION ALL

  SELECT
    'Google' AS Data_Source,
    'Overall Workforce' AS Industry,
    INITCAP("gender_us") AS Gender,
    'Native American' AS Race,
    ROUND("race_native_american", 4) AS Percentage
  FROM
    "GOOGLE_DEI"."GOOGLE_DEI"."DAR_INTERSECTIONAL_REPRESENTATION"
  WHERE
    "report_year" = 2021
    AND LOWER("workforce") = 'overall'
    AND LOWER("gender_us") IN ('women', 'men')

  UNION ALL

  SELECT
    'Google' AS Data_Source,
    'Overall Workforce' AS Industry,
    INITCAP("gender_us") AS Gender,
    'White' AS Race,
    ROUND("race_white", 4) AS Percentage
  FROM
    "GOOGLE_DEI"."GOOGLE_DEI"."DAR_INTERSECTIONAL_REPRESENTATION"
  WHERE
    "report_year" = 2021
    AND LOWER("workforce") = 'overall'
    AND LOWER("gender_us") IN ('women', 'men')
),

bls_data AS (
  SELECT
    'BLS' AS Data_Source,
    CASE
      WHEN "industry" = 'Internet publishing and broadcasting and web search portals' THEN 'Internet Content Broadcasting'
      WHEN "industry" = 'Computer systems design and related services' THEN 'Computer Systems Design and Related Services'
      ELSE NULL
    END AS Industry,
    "percent_women",
    "percent_white",
    "percent_black_or_african_american",
    "percent_asian",
    "percent_hispanic_or_latino"
  FROM "GOOGLE_DEI"."BLS"."CPSAAT18"
  WHERE
    "year" = 2021
    AND "industry" IN (
      'Computer systems design and related services',
      'Internet publishing and broadcasting and web search portals'
    )
    AND "percent_women" IS NOT NULL
    AND "percent_white" IS NOT NULL
    AND "percent_black_or_african_american" IS NOT NULL
    AND "percent_asian" IS NOT NULL
    AND "percent_hispanic_or_latino" IS NOT NULL
)

SELECT
  Data_Source,
  Industry,
  'Women' AS Gender,
  'Asian' AS Race,
  ROUND("percent_women" * "percent_asian", 4) AS Percentage
FROM bls_data
WHERE Industry IS NOT NULL

UNION ALL

SELECT
  Data_Source,
  Industry,
  'Women' AS Gender,
  'Black or African American' AS Race,
  ROUND("percent_women" * "percent_black_or_african_american", 4) AS Percentage
FROM bls_data
WHERE Industry IS NOT NULL

UNION ALL

SELECT
  Data_Source,
  Industry,
  'Women' AS Gender,
  'Hispanic or Latino' AS Race,
  ROUND("percent_women" * "percent_hispanic_or_latino", 4) AS Percentage
FROM bls_data
WHERE Industry IS NOT NULL

UNION ALL

SELECT
  Data_Source,
  Industry,
  'Women' AS Gender,
  'White' AS Race,
  ROUND("percent_women" * "percent_white", 4) AS Percentage
FROM bls_data
WHERE Industry IS NOT NULL

UNION ALL

SELECT
  Data_Source,
  Industry,
  'Men' AS Gender,
  'Asian' AS Race,
  ROUND((1 - "percent_women") * "percent_asian", 4) AS Percentage
FROM bls_data
WHERE Industry IS NOT NULL

UNION ALL

SELECT
  Data_Source,
  Industry,
  'Men' AS Gender,
  'Black or African American' AS Race,
  ROUND((1 - "percent_women") * "percent_black_or_african_american", 4) AS Percentage
FROM bls_data
WHERE Industry IS NOT NULL

UNION ALL

SELECT
  Data_Source,
  Industry,
  'Men' AS Gender,
  'Hispanic or Latino' AS Race,
  ROUND((1 - "percent_women") * "percent_hispanic_or_latino", 4) AS Percentage
FROM bls_data
WHERE Industry IS NOT NULL

UNION ALL

SELECT
  Data_Source,
  Industry,
  'Men' AS Gender,
  'White' AS Race,
  ROUND((1 - "percent_women") * "percent_white", 4) AS Percentage
FROM bls_data
WHERE Industry IS NOT NULL

UNION ALL

SELECT
  Data_Source,
  Industry,
  Gender,
  Race,
  Percentage
FROM google_data

ORDER BY
  Data_Source,
  Industry,
  Gender,
  Race;