/* Top three races with the largest 2021 hiring-vs-BLS race-percentage gaps */

WITH google_2021 AS (
  SELECT
    race_white,
    race_black,
    race_asian,
    race_hispanic_latinx
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE workforce   = 'overall'
    AND report_year = 2021
),

bls_tech_2021 AS (
  SELECT
    percent_white                     AS race_white,
    percent_black_or_african_american AS race_black,
    percent_asian                     AS race_asian,
    percent_hispanic_or_latino        AS race_hispanic_latinx
  FROM `bigquery-public-data.bls.cpsaat18`
  WHERE year = 2021
    AND (
      LOWER(CONCAT(IFNULL(sector,''),' ',IFNULL(subsector,''),' ',
                   IFNULL(industry_group,''),' ',IFNULL(industry,''))) LIKE '%internet publishing and broadcasting and web search portals%' OR
      LOWER(CONCAT(IFNULL(sector,''),' ',IFNULL(subsector,''),' ',
                   IFNULL(industry_group,''),' ',IFNULL(industry,''))) LIKE '%software publishers%' OR
      LOWER(CONCAT(IFNULL(sector,''),' ',IFNULL(subsector,''),' ',
                   IFNULL(industry_group,''),' ',IFNULL(industry,''))) LIKE '%data processing, hosting%' OR
      LOWER(CONCAT(IFNULL(sector,''),' ',IFNULL(subsector,''),' ',
                   IFNULL(industry_group,''),' ',IFNULL(industry,''))) LIKE '%computer systems design and related services%'
    )
),

bls_avg AS (
  SELECT
    AVG(race_white)           AS race_white,
    AVG(race_black)           AS race_black,
    AVG(race_asian)           AS race_asian,
    AVG(race_hispanic_latinx) AS race_hispanic_latinx
  FROM bls_tech_2021
),

diffs AS (
  SELECT 'White'            AS race, ABS(g.race_white           - b.race_white)            AS diff FROM google_2021 g CROSS JOIN bls_avg b UNION ALL
  SELECT 'Black'            AS race, ABS(g.race_black           - b.race_black)            AS diff FROM google_2021 g CROSS JOIN bls_avg b UNION ALL
  SELECT 'Asian'            AS race, ABS(g.race_asian           - b.race_asian)            AS diff FROM google_2021 g CROSS JOIN bls_avg b UNION ALL
  SELECT 'Hispanic/Latinx'  AS race, ABS(g.race_hispanic_latinx - b.race_hispanic_latinx)  AS diff
  FROM   google_2021 g CROSS JOIN bls_avg b
)

SELECT
  race,
  ROUND(diff, 6) AS difference
FROM diffs
ORDER BY diff DESC
LIMIT 3;