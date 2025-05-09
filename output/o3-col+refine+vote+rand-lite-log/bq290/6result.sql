/* Daily US-minus-UK temperature differences – October 2023 */
WITH us_daily AS (
  SELECT
    DATE(CONCAT(gs.year,'-',gs.mo,'-',gs.da))            AS obs_date,
    MAX(gs.max)                                         AS max_temp,
    MIN(gs.min)                                         AS min_temp,
    AVG(gs.temp)                                        AS avg_temp
  FROM `bigquery-public-data.noaa_gsod.gsod2023` AS gs
  JOIN `bigquery-public-data.noaa_gsod.stations`  AS st
    ON gs.stn  = st.usaf
   AND gs.wban = st.wban
  WHERE st.country = 'US'
    AND gs.mo = '10'                          -- October
    AND gs.max  < 9999                        -- discard missing/invalid values
    AND gs.min  < 9999
    AND gs.temp < 9999
  GROUP BY obs_date
),
uk_daily AS (
  SELECT
    DATE(CONCAT(gs.year,'-',gs.mo,'-',gs.da))            AS obs_date,
    MAX(gs.max)                                         AS max_temp,
    MIN(gs.min)                                         AS min_temp,
    AVG(gs.temp)                                        AS avg_temp
  FROM `bigquery-public-data.noaa_gsod.gsod2023` AS gs
  JOIN `bigquery-public-data.noaa_gsod.stations`  AS st
    ON gs.stn  = st.usaf
   AND gs.wban = st.wban
  WHERE st.country = 'UK'
    AND gs.mo = '10'
    AND gs.max  < 9999
    AND gs.min  < 9999
    AND gs.temp < 9999
  GROUP BY obs_date
)
SELECT
  us.obs_date,
  ROUND(us.max_temp - uk.max_temp, 2) AS diff_max_temp,
  ROUND(us.min_temp - uk.min_temp, 2) AS diff_min_temp,
  ROUND(us.avg_temp - uk.avg_temp, 2) AS diff_avg_temp
FROM us_daily AS us
JOIN uk_daily AS uk USING (obs_date)
ORDER BY obs_date;