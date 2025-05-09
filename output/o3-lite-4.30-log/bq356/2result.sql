SELECT
  COUNT(*) AS stations_meeting_criteria
FROM (
  SELECT
    s.usaf,
    s.wban
  FROM `bigquery-public-data.noaa_gsod.stations` AS s
  JOIN (
    SELECT
      stn  AS usaf,
      wban,
      COUNT(*) AS valid_day_count
    FROM `bigquery-public-data.noaa_gsod.gsod2019`
    WHERE temp <> 9999.9
      AND max  <> 9999.9
      AND min  <> 9999.9
    GROUP BY usaf, wban
    HAVING COUNT(*) >= 329          -- ≥ 90 % of 365 days
  ) AS v
  ON s.usaf = v.usaf
 AND s.wban = v.wban
  WHERE s.begin <= '20000101'       -- in service by 1‑Jan‑2000
    AND s.end   >= '20190630'       -- still active on 30‑Jun‑2019
);