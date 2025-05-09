WITH hiring AS (
  SELECT
    "race_asian",
    "race_black",
    "race_hispanic_latinx",
    "race_white",
    "gender_us_women",
    "gender_us_men"
  FROM
    "GOOGLE_DEI"."GOOGLE_DEI"."DAR_NON_INTERSECTIONAL_HIRING"
  WHERE
    "report_year" = 2021 AND "workforce" = 'overall'
),
representation AS (
  SELECT
    "race_asian",
    "race_black",
    "race_hispanic_latinx",
    "race_white",
    "gender_us_women",
    "gender_us_men"
  FROM
    "GOOGLE_DEI"."GOOGLE_DEI"."DAR_NON_INTERSECTIONAL_REPRESENTATION"
  WHERE
    "report_year" = 2021 AND "workforce" = 'overall'
),
bls AS (
  SELECT
    AVG("percent_asian") AS "percent_asian",
    AVG("percent_black_or_african_american") AS "percent_black_or_african_american",
    AVG("percent_hispanic_or_latino") AS "percent_hispanic_or_latino",
    AVG("percent_white") AS "percent_white",
    AVG("percent_women") AS "percent_women"
  FROM
    "GOOGLE_DEI"."BLS"."CPSAAT18"
  WHERE
    "year" = 2021 AND
    "industry_group" = 'Computer systems design and related services'
)
SELECT
  'Asian' AS "Category",
  ROUND(h."race_asian", 4) AS "Workforce_Hiring_Percentage",
  ROUND(r."race_asian", 4) AS "Workforce_Representation_Percentage",
  ROUND(b."percent_asian", 4) AS "BLS_Sector_Percentage"
FROM hiring h, representation r, bls b

UNION ALL

SELECT
  'Black' AS "Category",
  ROUND(h."race_black", 4),
  ROUND(r."race_black", 4),
  ROUND(b."percent_black_or_african_american", 4)
FROM hiring h, representation r, bls b

UNION ALL

SELECT
  'Hispanic/Latinx' AS "Category",
  ROUND(h."race_hispanic_latinx", 4),
  ROUND(r."race_hispanic_latinx", 4),
  ROUND(b."percent_hispanic_or_latino", 4)
FROM hiring h, representation r, bls b

UNION ALL

SELECT
  'White' AS "Category",
  ROUND(h."race_white", 4),
  ROUND(r."race_white", 4),
  ROUND(b."percent_white", 4)
FROM hiring h, representation r, bls b

UNION ALL

SELECT
  'U.S. Women' AS "Category",
  ROUND(h."gender_us_women", 4),
  ROUND(r."gender_us_women", 4),
  ROUND(b."percent_women", 4)
FROM hiring h, representation r, bls b

UNION ALL

SELECT
  'U.S. Men' AS "Category",
  ROUND(h."gender_us_men", 4),
  ROUND(r."gender_us_men", 4),
  ROUND(1 - b."percent_women", 4) AS "BLS_Sector_Percentage"
FROM hiring h, representation r, bls b;