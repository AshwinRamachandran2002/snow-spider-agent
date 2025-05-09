SELECT
  COUNT(*) AS number_of_stations
FROM (
  SELECT
    s.usaf,
    s.wban
  FROM
    `bigquery-public-data.noaa_gsod.stations` AS s
  JOIN (
    SELECT
      stn,
      wban,
      COUNTIF(temp != 9999.9 AND max != 9999.9 AND min != 9999.9) AS valid_temp_days,
      COUNT(*) AS total_days
    FROM
      `bigquery-public-data.noaa_gsod.gsod2019`
    GROUP BY
      stn,
      wban
    HAVING
      valid_temp_days / total_days >= 0.9
  ) AS temp_data
  ON
    s.usaf = temp_data.stn AND s.wban = temp_data.wban
  WHERE
    s.begin <= '20000101' AND (s.end IS NULL OR s.end >= '20190630')
)