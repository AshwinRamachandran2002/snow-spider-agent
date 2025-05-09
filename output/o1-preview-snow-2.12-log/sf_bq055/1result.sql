WITH google_hiring AS (
  SELECT
    "race_asian" AS google_asian,
    "race_black" AS google_black,
    "race_hispanic_latinx" AS google_hispanic_latinx,
    "race_white" AS google_white
  FROM "GOOGLE_DEI"."GOOGLE_DEI"."DAR_NON_INTERSECTIONAL_HIRING"
  WHERE "report_year" = 2021 AND "workforce" = 'overall'
),
bls_averages AS (
  SELECT
    AVG("percent_white") AS bls_white,
    AVG("percent_black_or_african_american") AS bls_black,
    AVG("percent_asian") AS bls_asian,
    AVG("percent_hispanic_or_latino") AS bls_hispanic_latinx
  FROM "GOOGLE_DEI"."BLS"."CPSAAT18"
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
    'race_white' AS "Race",
    ABS(g.google_white - b.bls_white) AS "Percentage_Difference"
  FROM google_hiring g CROSS JOIN bls_averages b
  UNION ALL
  SELECT
    'race_black' AS "Race",
    ABS(g.google_black - b.bls_black) AS "Percentage_Difference"
  FROM google_hiring g CROSS JOIN bls_averages b
  UNION ALL
  SELECT
    'race_asian' AS "Race",
    ABS(g.google_asian - b.bls_asian) AS "Percentage_Difference"
  FROM google_hiring g CROSS JOIN bls_averages b
  UNION ALL
  SELECT
    'race_hispanic_latinx' AS "Race",
    ABS(g.google_hispanic_latinx - b.bls_hispanic_latinx) AS "Percentage_Difference"
  FROM google_hiring g CROSS JOIN bls_averages b
)
SELECT "Race", ROUND("Percentage_Difference", 4) AS "Percentage_Difference"
FROM differences
ORDER BY "Percentage_Difference" DESC NULLS LAST
LIMIT 3;