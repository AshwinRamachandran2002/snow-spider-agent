/*  Percentage of stations that reported      */
/*  non‑missing temperature, max and min for  */
/*  at least 90 % of calendar days in 2022    */
SELECT
  ROUND(
        100 * COUNTIF(valid_days >= 0.9 * 365)
        / COUNT(*)
       ,2) AS percentage_of_stations
FROM (
  SELECT
    stn,
    /* count days whose temperature values are all present
       and not equal to the missing‑data flag 9999.9        */
    COUNTIF(
        temp IS NOT NULL AND temp <> 9999.9
    AND `max` IS NOT NULL AND `max` <> 9999.9
    AND `min` IS NOT NULL AND `min` <> 9999.9
    ) AS valid_days
  FROM `bigquery-public-data.noaa_gsod.gsod2022`
  /* exclude stations with invalid USAF identifier          */
  WHERE stn <> '999999'
  GROUP BY stn
);