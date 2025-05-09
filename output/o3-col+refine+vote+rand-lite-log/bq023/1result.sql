-- Kings County (Brooklyn, NY) – 2020 average individual donation + 2018 ACS median income
WITH tract_donations AS (
  SELECT
    c.census_tract_geoid                       AS tract_geoid,
    AVG(f.transaction_amt)                     AS avg_political_donation_2020
  FROM `bigquery-public-data.fec.indiv20`                                 AS f
  JOIN `bigquery-public-data.hud_zipcode_crosswalk.zipcode_to_census_tracts` AS c
        ON SUBSTR(f.zip_code, 1, 5) = c.zip_code            -- match on 5-digit ZIP
  WHERE f.state = 'NY'                                      -- New York donors only
    AND c.census_tract_geoid LIKE '36047%'                  -- 36 = NY, 047 = Kings Co.
    AND f.transaction_amt IS NOT NULL                      -- keep records with amounts
  GROUP BY tract_geoid
)

SELECT
  d.tract_geoid                               AS census_tract_geo_id,
  ROUND(d.avg_political_donation_2020, 2)     AS avg_political_donation_2020,
  a.median_income                             AS median_household_income_2018
FROM tract_donations AS d
LEFT JOIN `bigquery-public-data.census_bureau_acs.censustract_2018_5yr` AS a
       ON d.tract_geoid = a.geo_id
ORDER BY census_tract_geo_id;