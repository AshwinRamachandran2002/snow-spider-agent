SELECT 
  t.zip_code,
  ROUND((d.employed_pop / d.pop_16_over) * 100, 4) AS employment_rate
FROM (
  SELECT zip_code, COUNT(*) AS num_locations
  FROM `bigquery-public-data.fdic_banks.locations`
  WHERE state = 'UT'
  GROUP BY zip_code
  ORDER BY num_locations ASC, zip_code ASC
  LIMIT 1
) t
JOIN `bigquery-public-data.census_bureau_acs.zip_codes_2017_5yr` d
ON t.zip_code = SUBSTR(d.geo_id, -5)