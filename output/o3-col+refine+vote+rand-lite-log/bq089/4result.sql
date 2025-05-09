-- Number of COVID-19 vaccination sites per 1,000 residents
-- for every California county, using 2018 ACS 5-year population.

WITH county_xwalk AS (
  -- Manual county-name ↔ county-FIPS cross-walk
  SELECT *
  FROM UNNEST([
    STRUCT('Alameda County'        AS county_name, '06001' AS county_fips),
    STRUCT('Alpine County'         AS county_name, '06003' AS county_fips),
    STRUCT('Amador County'         AS county_name, '06005' AS county_fips),
    STRUCT('Butte County'          AS county_name, '06007' AS county_fips),
    STRUCT('Calaveras County'      AS county_name, '06009' AS county_fips),
    STRUCT('Colusa County'         AS county_name, '06011' AS county_fips),
    STRUCT('Contra Costa County'   AS county_name, '06013' AS county_fips),
    STRUCT('Del Norte County'      AS county_name, '06015' AS county_fips),
    STRUCT('El Dorado County'      AS county_name, '06017' AS county_fips),
    STRUCT('Fresno County'         AS county_name, '06019' AS county_fips),
    STRUCT('Glenn County'          AS county_name, '06021' AS county_fips),
    STRUCT('Humboldt County'       AS county_name, '06023' AS county_fips),
    STRUCT('Imperial County'       AS county_name, '06025' AS county_fips),
    STRUCT('Inyo County'           AS county_name, '06027' AS county_fips),
    STRUCT('Kern County'           AS county_name, '06029' AS county_fips),
    STRUCT('Kings County'          AS county_name, '06031' AS county_fips),
    STRUCT('Lake County'           AS county_name, '06033' AS county_fips),
    STRUCT('Lassen County'         AS county_name, '06035' AS county_fips),
    STRUCT('Los Angeles County'    AS county_name, '06037' AS county_fips),
    STRUCT('Madera County'         AS county_name, '06039' AS county_fips),
    STRUCT('Marin County'          AS county_name, '06041' AS county_fips),
    STRUCT('Mariposa County'       AS county_name, '06043' AS county_fips),
    STRUCT('Mendocino County'      AS county_name, '06045' AS county_fips),
    STRUCT('Merced County'         AS county_name, '06047' AS county_fips),
    STRUCT('Modoc County'          AS county_name, '06049' AS county_fips),
    STRUCT('Mono County'           AS county_name, '06051' AS county_fips),
    STRUCT('Monterey County'       AS county_name, '06053' AS county_fips),
    STRUCT('Napa County'           AS county_name, '06055' AS county_fips),
    STRUCT('Nevada County'         AS county_name, '06057' AS county_fips),
    STRUCT('Orange County'         AS county_name, '06059' AS county_fips),
    STRUCT('Placer County'         AS county_name, '06061' AS county_fips),
    STRUCT('Plumas County'         AS county_name, '06063' AS county_fips),
    STRUCT('Riverside County'      AS county_name, '06065' AS county_fips),
    STRUCT('Sacramento County'     AS county_name, '06067' AS county_fips),
    STRUCT('San Benito County'     AS county_name, '06069' AS county_fips),
    STRUCT('San Bernardino County' AS county_name, '06071' AS county_fips),
    STRUCT('San Diego County'      AS county_name, '06073' AS county_fips),
    STRUCT('San Francisco County'  AS county_name, '06075' AS county_fips),
    STRUCT('San Joaquin County'    AS county_name, '06077' AS county_fips),
    STRUCT('San Luis Obispo County'AS county_name, '06079' AS county_fips),
    STRUCT('San Mateo County'      AS county_name, '06081' AS county_fips),
    STRUCT('Santa Barbara County'  AS county_name, '06083' AS county_fips),
    STRUCT('Santa Clara County'    AS county_name, '06085' AS county_fips),
    STRUCT('Santa Cruz County'     AS county_name, '06087' AS county_fips),
    STRUCT('Shasta County'         AS county_name, '06089' AS county_fips),
    STRUCT('Sierra County'         AS county_name, '06091' AS county_fips),
    STRUCT('Siskiyou County'       AS county_name, '06093' AS county_fips),
    STRUCT('Solano County'         AS county_name, '06095' AS county_fips),
    STRUCT('Sonoma County'         AS county_name, '06097' AS county_fips),
    STRUCT('Stanislaus County'     AS county_name, '06099' AS county_fips),
    STRUCT('Sutter County'         AS county_name, '06101' AS county_fips),
    STRUCT('Tehama County'         AS county_name, '06103' AS county_fips),
    STRUCT('Trinity County'        AS county_name, '06105' AS county_fips),
    STRUCT('Tulare County'         AS county_name, '06107' AS county_fips),
    STRUCT('Tuolumne County'       AS county_name, '06109' AS county_fips),
    STRUCT('Ventura County'        AS county_name, '06111' AS county_fips),
    STRUCT('Yolo County'           AS county_name, '06113' AS county_fips),
    STRUCT('Yuba County'           AS county_name, '06115' AS county_fips)
  ])
),
acs_pop AS (
  -- 2018 five-year ACS population for California counties (FIPS prefix 06)
  SELECT
    geo_id       AS county_fips,
    total_pop
  FROM `bigquery-public-data.census_bureau_acs.county_2018_5yr`
  WHERE SUBSTR(geo_id, 1, 2) = '06'
),
site_counts AS (
  -- Count of vaccination facilities in each California county
  SELECT
    facility_sub_region_2 AS county_name,
    COUNT(*)              AS num_sites
  FROM `bigquery-public-data.covid19_vaccination_access.facility_boundary_us_all`
  WHERE facility_sub_region_1 = 'California'
  GROUP BY county_name
)

SELECT
  x.county_name,
  p.total_pop,
  COALESCE(s.num_sites, 0)                                   AS num_sites,
  ROUND(1000 * COALESCE(s.num_sites, 0) / p.total_pop, 4)    AS sites_per_1000
FROM county_xwalk AS x
JOIN acs_pop      AS p ON p.county_fips = x.county_fips
LEFT JOIN site_counts AS s USING (county_name)
ORDER BY sites_per_1000 DESC;