-- Top three races with the largest absolute percentage‑point gaps
-- between Google’s 2021 overall U.S. hiring and the 2021 BLS tech‑sector average
WITH google_2021 AS (
  SELECT
    race_asian                     AS asian_pct,
    race_black                     AS black_pct,
    race_hispanic_latinx           AS hispanic_pct,
    race_white                     AS white_pct
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE workforce   = 'overall'
    AND report_year = 2021
),
bls_tech_2021 AS (
  /* 2021 tech‑sector rows in CPSAAT18 that match the four NAICS tech categories */
  SELECT
    SAFE_DIVIDE(SUM(total_employed_in_thousands * percent_asian)                    ,
                SUM(total_employed_in_thousands)) AS asian_pct,
    SAFE_DIVIDE(SUM(total_employed_in_thousands * percent_black_or_african_american),
                SUM(total_employed_in_thousands)) AS black_pct,
    SAFE_DIVIDE(SUM(total_employed_in_thousands * percent_hispanic_or_latino)       ,
                SUM(total_employed_in_thousands)) AS hispanic_pct,
    SAFE_DIVIDE(SUM(total_employed_in_thousands * percent_white)                    ,
                SUM(total_employed_in_thousands)) AS white_pct
  FROM `bigquery-public-data.bls.cpsaat18`
  WHERE year = 2021
    AND (
          LOWER(IFNULL(industry       ,'')) LIKE '%internet publishing%'                         OR
          LOWER(IFNULL(industry       ,'')) LIKE '%software publishers%'                         OR
          LOWER(IFNULL(industry       ,'')) LIKE '%data processing, hosting%'                    OR
          LOWER(IFNULL(industry_group ,'')) LIKE '%computer systems design and related services%'
        )
),
race_diff AS (
  /* pivot the two single‑row tables and calculate differences */
  SELECT 'Asian'            AS race, g.asian_pct    AS google_pct, b.asian_pct    AS bls_pct, g.asian_pct    - b.asian_pct    AS diff FROM google_2021 g CROSS JOIN bls_tech_2021 b UNION ALL
  SELECT 'Black'            AS race, g.black_pct    AS google_pct, b.black_pct    AS bls_pct, g.black_pct    - b.black_pct    AS diff FROM google_2021 g CROSS JOIN bls_tech_2021 b UNION ALL
  SELECT 'Hispanic/Latinx'  AS race, g.hispanic_pct AS google_pct, b.hispanic_pct AS bls_pct, g.hispanic_pct - b.hispanic_pct AS diff FROM google_2021 g CROSS JOIN bls_tech_2021 b UNION ALL
  SELECT 'White'            AS race, g.white_pct    AS google_pct, b.white_pct    AS bls_pct, g.white_pct    - b.white_pct    AS diff FROM google_2021 g CROSS JOIN bls_tech_2021 b
)
SELECT
  race,
  diff        AS difference_in_percentage_points
FROM race_diff
ORDER BY ABS(diff) DESC
LIMIT 3;