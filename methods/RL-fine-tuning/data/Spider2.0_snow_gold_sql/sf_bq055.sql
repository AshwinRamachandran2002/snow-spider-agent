WITH google_data AS (
  SELECT
    'Asian' AS "Race",
    "race_asian" AS "google_percentage"
  FROM GOOGLE_DEI.GOOGLE_DEI.DAR_NON_INTERSECTIONAL_HIRING
  WHERE "workforce" = 'overall' AND "report_year" = 2021
  UNION ALL
  SELECT
    'Black' AS "Race",
    "race_black" AS "google_percentage"
  FROM GOOGLE_DEI.GOOGLE_DEI.DAR_NON_INTERSECTIONAL_HIRING
  WHERE "workforce" = 'overall' AND "report_year" = 2021
  UNION ALL
  SELECT
    'Hispanic_Latinx' AS "Race",
    "race_hispanic_latinx" AS "google_percentage"
  FROM GOOGLE_DEI.GOOGLE_DEI.DAR_NON_INTERSECTIONAL_HIRING
  WHERE "workforce" = 'overall' AND "report_year" = 2021
  UNION ALL
  SELECT
    'White' AS "Race",
    "race_white" AS "google_percentage"
  FROM GOOGLE_DEI.GOOGLE_DEI.DAR_NON_INTERSECTIONAL_HIRING
  WHERE "workforce" = 'overall' AND "report_year" = 2021
),
bls_data AS (
  SELECT
    'Asian' AS "Race",
    AVG("percent_asian") AS "bls_percentage"
  FROM GOOGLE_DEI.BLS.CPSAAT18
  WHERE "year" = 2021 AND (
    "industry" IN (
      'Internet publishing and broadcasting and web search portals',
      'Software publishers',
      'Data processing, hosting, and related services'
    ) OR "industry_group" = 'Computer systems design and related services'
  )
  UNION ALL
  SELECT
    'Black' AS "Race",
    AVG("percent_black_or_african_american") AS "bls_percentage"
  FROM GOOGLE_DEI.BLS.CPSAAT18
  WHERE "year" = 2021 AND (
    "industry" IN (
      'Internet publishing and broadcasting and web search portals',
      'Software publishers',
      'Data processing, hosting, and related services'
    ) OR "industry_group" = 'Computer systems design and related services'
  )
  UNION ALL
  SELECT
    'Hispanic_Latinx' AS "Race",
    AVG("percent_hispanic_or_latino") AS "bls_percentage"
  FROM GOOGLE_DEI.BLS.CPSAAT18
  WHERE "year" = 2021 AND (
    "industry" IN (
      'Internet publishing and broadcasting and web search portals',
      'Software publishers',
      'Data processing, hosting, and related services'
    ) OR "industry_group" = 'Computer systems design and related services'
  )
  UNION ALL
  SELECT
    'White' AS "Race",
    AVG("percent_white") AS "bls_percentage"
  FROM GOOGLE_DEI.BLS.CPSAAT18
  WHERE "year" = 2021 AND (
    "industry" IN (
      'Internet publishing and broadcasting and web search portals',
      'Software publishers',
      'Data processing, hosting, and related services'
    ) OR "industry_group" = 'Computer systems design and related services'
  )
),
differences AS (
  SELECT
    g."Race",
    g."google_percentage",
    b."bls_percentage",
    ROUND(g."google_percentage" - b."bls_percentage", 4) AS "Percentage_Difference",
    ABS(g."google_percentage" - b."bls_percentage") AS "abs_difference"
  FROM google_data g
  JOIN bls_data b ON g."Race" = b."Race"
)
SELECT "Race", "Percentage_Difference"
FROM differences
ORDER BY "abs_difference" DESC NULLS LAST
LIMIT 3;