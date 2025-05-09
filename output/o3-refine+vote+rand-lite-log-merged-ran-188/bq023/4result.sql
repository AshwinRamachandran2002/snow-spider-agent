-- Kings County (Brooklyn, NY): 2020 individual-donation averages + 2018-ACS median incomes
WITH ny_donors AS (   -- 2020 FEC individual contributors in New York
  SELECT
    SUBSTR(zip_code,1,5)       AS zip5,
    transaction_amt
  FROM `bigquery-public-data.fec.indiv20`
  WHERE state = 'NY'
    AND zip_code IS NOT NULL
    AND transaction_amt IS NOT NULL
),

tract_avg_donations AS (   -- map 5-digit ZIPs to census tracts and average the gifts
  SELECT
    ztc.census_tract_geoid     AS geo_id,
    AVG(d.transaction_amt)     AS avg_donation
  FROM ny_donors AS d
  JOIN `bigquery-public-data.hud_zipcode_crosswalk.zipcode_to_census_tracts` AS ztc
    ON d.zip5 = ztc.zip_code
  WHERE SUBSTR(ztc.census_tract_geoid,1,5) = '36047'   -- Kings County FIPS
  GROUP BY geo_id
),

acs_income AS (          -- 2018 ACS 5-year median income, Kings County tracts
  SELECT
    geo_id,
    median_income
  FROM `bigquery-public-data.census_bureau_acs.censustract_2018_5yr`
  WHERE geo_id LIKE '36047%'
)

-- Final result: every Kings County census tract with its income and average donation
SELECT
  acs.geo_id,
  donations.avg_donation,
  acs.median_income
FROM acs_income AS acs
LEFT JOIN tract_avg_donations AS donations
  ON acs.geo_id = donations.geo_id
ORDER BY acs.geo_id;