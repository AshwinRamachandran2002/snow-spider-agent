-- 2021 Race & U.S.-gender profile comparison
--   • Google overall workforce – HIRING
--   • Google overall workforce – REPRESENTATION
--   • BLS CPS (2021) for tech industries:
--       “Internet publishing and broadcasting and web search portals”
--       OR “Computer systems design and related services”
WITH
/* ---------- 1.  Google – 2021 hiring & representation ---------- */
google AS (
  SELECT
    'Google Hiring (Overall)'           AS source,
    race_asian,
    race_black,
    race_hispanic_latinx,
    race_white,
    gender_us_women,
    gender_us_men
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE workforce = 'overall' AND report_year = 2021
  
  UNION ALL
  
  SELECT
    'Google Representation (Overall)'   AS source,
    race_asian,
    race_black,
    race_hispanic_latinx,
    race_white,
    gender_us_women,
    gender_us_men
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE workforce = 'overall' AND report_year = 2021
),

/* ---------- 2.  BLS CPS 2021 – tech-sector rows ---------- */
bls_tech_rows AS (   -- pick rows whose *any* hierarchy column contains either phrase
  SELECT
    total_employed_in_thousands                                AS emp,
    percent_women,
    percent_white,
    percent_black_or_african_american   AS percent_black,
    percent_asian,
    percent_hispanic_or_latino          AS percent_hispanic
  FROM `bigquery-public-data.bls.cpsaat18`
  WHERE year = 2021
    AND (
          LOWER(COALESCE(sector,''))        LIKE '%internet publishing%'  OR
          LOWER(COALESCE(subsector,''))     LIKE '%internet publishing%'  OR
          LOWER(COALESCE(industry_group,''))LIKE '%internet publishing%'  OR
          LOWER(COALESCE(industry,''))      LIKE '%internet publishing%'  OR
          LOWER(COALESCE(sector,''))        LIKE '%computer systems design%'  OR
          LOWER(COALESCE(subsector,''))     LIKE '%computer systems design%'  OR
          LOWER(COALESCE(industry_group,''))LIKE '%computer systems design%'  OR
          LOWER(COALESCE(industry,''))      LIKE '%computer systems design%'
        )
),

/* ---------- 2b.  Weighted aggregation ---------- */
bls AS (
  SELECT
    'BLS CPS Tech sectors'              AS source,
    SAFE_DIVIDE(SUM(emp * percent_asian   ), SUM(emp)) AS race_asian,
    SAFE_DIVIDE(SUM(emp * percent_black   ), SUM(emp)) AS race_black,
    SAFE_DIVIDE(SUM(emp * percent_hispanic), SUM(emp)) AS race_hispanic_latinx,
    SAFE_DIVIDE(SUM(emp * percent_white   ), SUM(emp)) AS race_white,
    SAFE_DIVIDE(SUM(emp * percent_women   ), SUM(emp)) AS gender_us_women,
    1 - SAFE_DIVIDE(SUM(emp * percent_women), SUM(emp)) AS gender_us_men
  FROM bls_tech_rows
)

/* ---------- 3.  Combine & present ---------- */
SELECT
  source,
  ROUND(race_asian           ,4) AS race_asian,
  ROUND(race_black           ,4) AS race_black,
  ROUND(race_hispanic_latinx ,4) AS race_hispanic_latinx,
  ROUND(race_white           ,4) AS race_white,
  ROUND(gender_us_women      ,4) AS gender_us_women,
  ROUND(gender_us_men        ,4) AS gender_us_men
FROM (
  SELECT * FROM google
  UNION ALL
  SELECT * FROM bls
)
ORDER BY source;