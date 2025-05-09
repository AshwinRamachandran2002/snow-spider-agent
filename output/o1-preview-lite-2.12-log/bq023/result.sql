SELECT
    crosswalk.census_tract_geoid AS census_tract_geoid,
    acs.median_income AS median_income,
    ROUND(
        SAFE_DIVIDE(
            SUM(donors.transaction_amt * SAFE_CAST(crosswalk.total_ratio AS FLOAT64)),
            SUM(SAFE_CAST(crosswalk.total_ratio AS FLOAT64))
        ), 4
    ) AS average_donation_amount
FROM
    `bigquery-public-data.fec.individuals_ingest_2020` AS donors
JOIN
    `bigquery-public-data.hud_zipcode_crosswalk.zipcode_to_census_tracts` AS crosswalk
    ON donors.zip_code = crosswalk.zip_code
JOIN
    `bigquery-public-data.geo_census_tracts.census_tracts_new_york` AS tracts
    ON crosswalk.census_tract_geoid = tracts.geo_id
JOIN
    `bigquery-public-data.census_bureau_acs.censustract_2018_5yr` AS acs
    ON crosswalk.census_tract_geoid = acs.geo_id
WHERE
    donors.state = 'NY'
    AND tracts.county_fips_code = '047'
GROUP BY
    crosswalk.census_tract_geoid,
    acs.median_income