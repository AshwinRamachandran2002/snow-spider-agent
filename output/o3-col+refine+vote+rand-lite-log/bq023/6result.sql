-- Kings County (Brooklyn) census-tracts :
--   • 2018 ACS 5-yr median household income
--   • 2020 FEC individual-donor average contribution
WITH ny_donations AS (      -- 1. 2020 NY donors with clean 5-digit ZIPs
  SELECT
    SUBSTR(zip_code,1,5)           AS zip5,
    transaction_amt
  FROM `bigquery-public-data.fec.indiv20`
  WHERE state = 'NY'
    AND transaction_amt IS NOT NULL
    AND REGEXP_CONTAINS(SUBSTR(zip_code,1,5), r'^[0-9]{5}$')
),
donations_by_tract AS (     -- 2. map ZIP → census-tract & average per tract
  SELECT
    ct.census_tract_geoid          AS geo_id,
    AVG(d.transaction_amt)         AS avg_donation_amt
  FROM  ny_donations                                AS d
  JOIN  `bigquery-public-data.hud_zipcode_crosswalk.zipcode_to_census_tracts` AS ct
        ON  d.zip5 = ct.zip_code
  WHERE SUBSTR(ct.census_tract_geoid,1,5) = '36047'   -- Kings County
  GROUP BY geo_id
)
-- 3. attach 2018 ACS median income & list all Kings-County tracts
SELECT
  d.geo_id,
  ROUND(d.avg_donation_amt,2)      AS avg_donation_amt,
  a.median_income
FROM   donations_by_tract                          AS d
JOIN   `bigquery-public-data.census_bureau_acs.censustract_2018_5yr` AS a
       ON  d.geo_id = a.geo_id
ORDER  BY d.geo_id;