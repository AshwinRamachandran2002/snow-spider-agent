SELECT 
  'Google' AS Data_Source,
  ROUND(race_asian * 100, 4) AS Race_Asian_percent,
  ROUND(race_black * 100, 4) AS Race_Black_percent,
  ROUND(race_hispanic_latinx * 100, 4) AS Race_Hispanic_Latinx_percent,
  ROUND(race_native_american * 100, 4) AS Race_Native_American_percent,
  ROUND(race_white * 100, 4) AS Race_White_percent,
  ROUND(gender_us_women * 100, 4) AS Gender_Women_percent,
  ROUND(gender_us_men * 100, 4) AS Gender_Men_percent
FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
WHERE report_year = 2021 AND LOWER(workforce) = 'overall'

UNION ALL

SELECT 
  'BLS_Tech_Sector' AS Data_Source,
  ROUND(percent_asian * 100, 4) AS Race_Asian_percent,
  ROUND(percent_black_or_african_american * 100, 4) AS Race_Black_percent,
  ROUND(percent_hispanic_or_latino * 100, 4) AS Race_Hispanic_Latinx_percent,
  NULL AS Race_Native_American_percent,
  ROUND(percent_white * 100, 4) AS Race_White_percent,
  ROUND(percent_women * 100, 4) AS Gender_Women_percent,
  ROUND((1 - percent_women) * 100, 4) AS Gender_Men_percent
FROM `bigquery-public-data.bls.cpsaat18`
WHERE year = 2021 AND industry = 'Computer Systems Design and Related Services'