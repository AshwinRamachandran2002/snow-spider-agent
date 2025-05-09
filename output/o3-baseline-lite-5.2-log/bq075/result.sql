WITH google_hiring AS (
  SELECT
    'Google – Hiring (Overall Workforce)' AS source,
    race_asian,
    race_black,
    race_hispanic_latinx,
    race_white,
    gender_us_women,
    gender_us_men
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE workforce = 'overall'
    AND report_year = 2021
),

google_representation AS (
  SELECT
    'Google – Representation (Overall Workforce)' AS source,
    race_asian,
    race_black,
    race_hispanic_latinx,
    race_white,
    gender_us_women,
    gender_us_men
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE workforce = 'overall'
    AND report_year = 2021
),

bls_tech AS (
  /* technology = Internet publishing & web search portals + Computer systems design & related services */
  SELECT
    'BLS – Tech Sectors (Internet Publishing/Web Search + Computer Systems Design)' AS source,
    SUM(total_employed_in_thousands * percent_asian             ) / SUM(total_employed_in_thousands) AS race_asian,
    SUM(total_employed_in_thousands * percent_black_or_african_american) / SUM(total_employed_in_thousands) AS race_black,
    SUM(total_employed_in_thousands * percent_hispanic_or_latino ) / SUM(total_employed_in_thousands) AS race_hispanic_latinx,
    SUM(total_employed_in_thousands * percent_white              ) / SUM(total_employed_in_thousands) AS race_white,
    /* women & men percentages (men = 1 ‑ women) */
    SUM(total_employed_in_thousands * percent_women              ) / SUM(total_employed_in_thousands) AS gender_us_women,
    SUM(total_employed_in_thousands * (1 - percent_women)        ) / SUM(total_employed_in_thousands) AS gender_us_men
  FROM `bigquery-public-data.google_dei.full_csv-latest-data-is-2023`
  WHERE year = 2021
    AND industry IN ('Internet publishing and broadcasting and web search portals',
                     'Computer systems design and related services')
)

SELECT *
FROM google_hiring
UNION ALL
SELECT *
FROM google_representation
UNION ALL
SELECT *
FROM bls_tech;