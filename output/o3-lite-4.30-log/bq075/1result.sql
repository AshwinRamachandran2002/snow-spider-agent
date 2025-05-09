WITH google_hiring AS (
  SELECT
    'google_hiring_2021'                                   AS category,
    ROUND(race_asian,           4) AS asian_pct,
    ROUND(race_black,           4) AS black_pct,
    ROUND(race_hispanic_latinx, 4) AS hispanic_latinx_pct,
    ROUND(race_white,           4) AS white_pct,
    ROUND(gender_us_women,      4) AS women_pct,
    ROUND(gender_us_men,        4) AS men_pct
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE workforce   = 'overall'
    AND report_year = 2021
),
google_representation AS (
  SELECT
    'google_representation_2021'                           AS category,
    ROUND(race_asian,           4) AS asian_pct,
    ROUND(race_black,           4) AS black_pct,
    ROUND(race_hispanic_latinx, 4) AS hispanic_latinx_pct,
    ROUND(race_white,           4) AS white_pct,
    ROUND(gender_us_women,      4) AS women_pct,
    ROUND(gender_us_men,        4) AS men_pct
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE workforce   = 'overall'
    AND report_year = 2021
),
bls_tech AS (
  SELECT
    'bls_tech_sectors_2021'                                AS category,
    ROUND(IFNULL(SUM(total_employed_in_thousands * percent_asian) /
                 SUM(total_employed_in_thousands), 0), 4)  AS asian_pct,
    ROUND(IFNULL(SUM(total_employed_in_thousands * percent_black_or_african_american) /
                 SUM(total_employed_in_thousands), 0), 4)  AS black_pct,
    ROUND(IFNULL(SUM(total_employed_in_thousands * percent_hispanic_or_latino) /
                 SUM(total_employed_in_thousands), 0), 4)  AS hispanic_latinx_pct,
    ROUND(IFNULL(SUM(total_employed_in_thousands * percent_white) /
                 SUM(total_employed_in_thousands), 0), 4)  AS white_pct,
    ROUND(IFNULL(SUM(total_employed_in_thousands * percent_women) /
                 SUM(total_employed_in_thousands), 0), 4)  AS women_pct,
    ROUND(IFNULL(SUM(total_employed_in_thousands * (1 - percent_women)) /
                 SUM(total_employed_in_thousands), 0), 4)  AS men_pct
  FROM `bigquery-public-data.bls.cpsaat18`
  WHERE year = 2021
    AND (
           LOWER(industry) LIKE '%internet publishing%'
        OR LOWER(industry) LIKE '%web search portal%'
        OR LOWER(industry) LIKE '%computer systems design%'
    )
)
SELECT *
FROM google_hiring
UNION ALL
SELECT *
FROM google_representation
UNION ALL
SELECT *
FROM bls_tech
ORDER BY category;