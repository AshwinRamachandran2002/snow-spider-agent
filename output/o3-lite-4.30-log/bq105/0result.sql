WITH population AS (
  /* 2010 Census population summed to each U.S. state                     */
  SELECT
    REGEXP_REPLACE(
      TRIM(SPLIT(z.state_name,',')[OFFSET(0)]),    /* if ZIP spans states, keep first */
      r' \([^)]+\)$',                              /* strip trailing parenthetical note */
      ''
    )                                   AS state,
    SUM(p.population)                   AS population_2010
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010` p
  JOIN `bigquery-public-data.utility_us.zipcode_area` z
    ON LPAD(p.zipcode,5,'0') = z.zipcode
  GROUP BY state
  HAVING state <> ''                                    /* drop blank names */
),
accidents_2015 AS (
  /* 2015 crashes that involved ≥ 1 distracted driver                      */
  SELECT
    REGEXP_REPLACE(a.state_name, r' \([^)]+\)$', '') AS state,
    COUNT(DISTINCT CONCAT(a.state_number,'-',a.consecutive_number)) 
      AS accidents_2015
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2015`  a
  JOIN `bigquery-public-data.nhtsa_traffic_fatalities.distract_2015`  d
    ON  a.state_number       = d.state_number
   AND a.consecutive_number  = d.consecutive_number
  WHERE d.driver_distracted_by_name NOT IN ('Not Distracted',
                                            'Unknown if Distracted',
                                            'Not Reported')
  GROUP BY state
  HAVING state <> ''
),
accidents_2016 AS (
  /* 2016 crashes that involved ≥ 1 distracted driver                      */
  SELECT
    REGEXP_REPLACE(a.state_name, r' \([^)]+\)$', '') AS state,
    COUNT(DISTINCT CONCAT(a.state_number,'-',a.consecutive_number)) 
      AS accidents_2016
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`  a
  JOIN `bigquery-public-data.nhtsa_traffic_fatalities.distract_2016`  d
    ON  a.state_number       = d.state_number
   AND a.consecutive_number  = d.consecutive_number
  WHERE d.driver_distracted_by_name NOT IN ('Not Distracted',
                                            'Unknown if Distracted',
                                            'Not Reported')
  GROUP BY state
  HAVING state <> ''
),
rates AS (
  /* merge population with crash counts and compute rates per 100 000      */
  SELECT
    pop.state,
    ROUND(100000 * IFNULL(acc15.accidents_2015,0) / pop.population_2010,4)
      AS accidents_per_100k_2015,
    ROUND(100000 * IFNULL(acc16.accidents_2016,0) / pop.population_2010,4)
      AS accidents_per_100k_2016
  FROM population pop
  LEFT JOIN accidents_2015 acc15 USING (state)
  LEFT JOIN accidents_2016 acc16 USING (state)
),
top5_2015 AS (
  SELECT state
  FROM   rates
  ORDER  BY accidents_per_100k_2015 DESC
  LIMIT  5
),
top5_2016 AS (
  SELECT state
  FROM   rates
  ORDER  BY accidents_per_100k_2016 DESC
  LIMIT  5
)
SELECT
  state,
  accidents_per_100k_2015,
  accidents_per_100k_2016,
  IF(state IN (SELECT state FROM top5_2015),'Y','') AS in_top5_2015,
  IF(state IN (SELECT state FROM top5_2016),'Y','') AS in_top5_2016
FROM rates
ORDER BY state;