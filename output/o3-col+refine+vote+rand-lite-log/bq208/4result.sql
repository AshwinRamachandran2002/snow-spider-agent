WITH near_stations AS (           -- stations within 20 miles of Chappaqua, NY
  SELECT
    usaf,
    wban,
    name,
    lat,
    lon
  FROM `bigquery-public-data.noaa_gsod.stations`
  WHERE ST_DWITHIN(
          ST_GEOGPOINT(lon, lat),
          ST_GEOGPOINT(-73.764, 41.197),
          32187                      -- 20 miles ≈ 32 187 m
        )
),
valid_obs AS (                    -- count valid-temperature rows, 2011-2020
  SELECT
    stn  AS usaf,
    wban,
    COUNTIF(temp <> 9999.9) AS valid_temp_days
  FROM `bigquery-public-data.noaa_gsod.gsod20*`     -- gsod2011 … gsod2020
  WHERE _TABLE_SUFFIX IN ('11','12','13','14','15',
                          '16','17','18','19','20')
  GROUP BY usaf, wban
)
SELECT
  s.usaf,
  s.wban,
  s.name,
  s.lat,
  s.lon,
  v.valid_temp_days
FROM   near_stations AS s
JOIN   valid_obs     AS v
  ON   s.usaf = v.usaf AND s.wban = v.wban
ORDER  BY v.valid_temp_days DESC;