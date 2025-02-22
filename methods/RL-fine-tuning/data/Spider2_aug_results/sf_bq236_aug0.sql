-- Task: List the top 5 zip codes in the United States with the highest number of hail storm events recorded from 2014 to 2024 (inclusive), excluding data from the HAIL_REPORTS table. Use the STORMS_<year> tables to count hail events, associating events with zip codes based on spatial location, and provide for each zip code the concatenated city and state name, and the total number of hail storm events, ordering the results by the hail event count in descending order.
SELECT
  CONCAT("city", ', ', "state_name") AS "city",
  "zip_code",
  COUNT("event_id") AS "count_storms"
FROM (
    SELECT *
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2014
    UNION ALL
    SELECT *
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2015
    UNION ALL
    SELECT *
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2016
    UNION ALL
    SELECT *
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2017
    UNION ALL
    SELECT *
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2018
    UNION ALL
    SELECT *
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2019
    UNION ALL
    SELECT *
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2020
    UNION ALL
    SELECT *
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2021
    UNION ALL
    SELECT *
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2022
    UNION ALL
    SELECT *
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2023
    UNION ALL
    SELECT *
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2024
) AS storms
JOIN NOAA_DATA_PLUS.GEO_US_BOUNDARIES.ZIP_CODES
  ON ST_WITHIN(ST_GEOGFROMWKB(storms."event_point"), ST_GEOGFROMWKB("zip_code_geom"))
WHERE
   LOWER(storms."event_type") = 'hail'
GROUP BY
  "zip_code", 
  "city", 
  "state_name"
ORDER BY
  "count_storms" DESC
LIMIT 5;