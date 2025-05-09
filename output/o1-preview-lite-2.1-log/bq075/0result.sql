SELECT
  Data_Source,
  ROUND(Race_Asian_Pct, 4) AS Race_Asian_Percent,
  ROUND(Race_Black_Pct, 4) AS Race_Black_Percent,
  ROUND(Race_Hispanic_Latinx_Pct, 4) AS Race_Hispanic_Latinx_Percent,
  ROUND(Race_Native_American_Pct, 4) AS Race_Native_American_Percent,
  ROUND(Race_White_Pct, 4) AS Race_White_Percent,
  ROUND(Gender_Women_Pct, 4) AS Gender_Women_Percent,
  ROUND(Gender_Men_Pct, 4) AS Gender_Men_Percent
FROM (
  SELECT
    'Google' AS Data_Source,
    race_asian * 100 AS Race_Asian_Pct,
    race_black * 100 AS Race_Black_Pct,
    race_hispanic_latinx * 100 AS Race_Hispanic_Latinx_Pct,
    race_native_american * 100 AS Race_Native_American_Pct,
    race_white * 100 AS Race_White_Pct,
    gender_us_women * 100 AS Gender_Women_Pct,
    gender_us_men * 100 AS Gender_Men_Pct
  FROM
    `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE
    report_year = 2021
    AND workforce = 'overall'

  UNION ALL

  SELECT
    'BLS_Tech_Sector' AS Data_Source,
    SUM(percent_asian * total_employed_in_thousands) / SUM(total_employed_in_thousands) * 100 AS Race_Asian_Pct,
    SUM(percent_black_or_african_american * total_employed_in_thousands) / SUM(total_employed_in_thousands) * 100 AS Race_Black_Pct,
    SUM(percent_hispanic_or_latino * total_employed_in_thousands) / SUM(total_employed_in_thousands) * 100 AS Race_Hispanic_Latinx_Pct,
    NULL AS Race_Native_American_Pct,
    SUM(percent_white * total_employed_in_thousands) / SUM(total_employed_in_thousands) * 100 AS Race_White_Pct,
    SUM(percent_women * total_employed_in_thousands) / SUM(total_employed_in_thousands) * 100 AS Gender_Women_Pct,
    (100 - SUM(percent_women * total_employed_in_thousands) / SUM(total_employed_in_thousands) * 100) AS Gender_Men_Pct
  FROM
    `bigquery-public-data.bls.cpsaat18`
  WHERE
    year = 2021
    AND industry IN (
      'Internet publishing and broadcasting and web search portals',
      'Computer systems design and related services'
    )
    AND percent_white IS NOT NULL
)