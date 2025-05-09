/*-----------------------------------------------------------------------
  2021 racial & gender mix comparison
    • Google overall U.S. hiring
    • Google overall U.S. representation
    • BLS technology sector workforce
        (Internet publishing & broadcasting & web‑search portals  OR
         Computer systems design & related services) – weighted
------------------------------------------------------------------------*/
WITH
-- -------------------------------------------------
--  Google overall – 2021 U.S. HIRING
-- -------------------------------------------------
google_hiring AS (
  SELECT
    'Google Hiring (2021)'                              AS source,
    race_asian,
    race_black,
    race_hispanic_latinx,
    race_white,
    gender_us_women,
    gender_us_men
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE workforce   = 'overall'
    AND report_year = 2021
),

-- -------------------------------------------------
--  Google overall – 2021 U.S. REPRESENTATION
-- -------------------------------------------------
google_representation AS (
  SELECT
    'Google Representation (2021)'                     AS source,
    race_asian,
    race_black,
    race_hispanic_latinx,
    race_white,
    gender_us_women,
    gender_us_men
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE workforce   = 'overall'
    AND report_year = 2021
),

-- -------------------------------------------------
--  BLS 2021 tech‑sector workforce:
--    • Internet publishing & broadcasting & web‑search portals
--    • Computer systems design & related services
--  Weighted by employment levels
-- -------------------------------------------------
bls_tech AS (
  SELECT
    'BLS Tech Sectors (2021)'                          AS source,

    -- weighted racial shares
    SUM(percent_asian                    * total_employed_in_thousands)
      / SUM(total_employed_in_thousands)              AS race_asian,
    SUM(percent_black_or_african_american* total_employed_in_thousands)
      / SUM(total_employed_in_thousands)              AS race_black,
    SUM(percent_hispanic_or_latino        * total_employed_in_thousands)
      / SUM(total_employed_in_thousands)              AS race_hispanic_latinx,
    SUM(percent_white                     * total_employed_in_thousands)
      / SUM(total_employed_in_thousands)              AS race_white,

    -- weighted gender shares
    SUM(percent_women                     * total_employed_in_thousands)
      / SUM(total_employed_in_thousands)              AS gender_us_women,
    1 - (SUM(percent_women                * total_employed_in_thousands)
      / SUM(total_employed_in_thousands))             AS gender_us_men
  FROM `bigquery-public-data.bls.cpsaat18`
  WHERE year = 2021
    AND (
         -- Internet publishing & broadcasting & web‑search portals
         LOWER(IFNULL(industry,''))       LIKE '%internet publishing%'       OR
         LOWER(IFNULL(industry_group,'')) LIKE '%internet publishing%'       OR
         LOWER(IFNULL(subsector,''))      LIKE '%internet publishing%'       OR
         -- Computer systems design & related services
         LOWER(IFNULL(industry,''))       LIKE '%computer systems design%'   OR
         LOWER(IFNULL(industry_group,'')) LIKE '%computer systems design%'
    )
)

-- -------------------------------------------------
--  Combine all three sources
-- -------------------------------------------------
SELECT *
FROM   google_hiring

UNION ALL
SELECT *
FROM   google_representation

UNION ALL
SELECT *
FROM   bls_tech;