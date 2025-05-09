-- Daily weather for Rochester (New York) with 8‑day moving averages and their lag‑1…lag‑8 differences
WITH stations_rochester AS (
  SELECT
    usaf,
    wban
  FROM
    `bigquery-public-data.noaa_gsod.stations`
  WHERE
    state = 'NY'
    AND REGEXP_CONTAINS(TRIM(name), r'(?i)^ROCHESTER')      -- pick Rochester, NY stations
),
daily AS (                                                -- raw daily values, unit‑converted
  SELECT
    DATE(CONCAT(year, '-', mo, '-', da))                AS dt,
    AVG(CASE WHEN temp  < 9999.9 THEN (temp - 32) * 5/9            END) AS temp_c,        -- °C
    AVG(CASE WHEN prcp  <  99.99 THEN prcp * 2.54                   END) AS prcp_cm,      -- cm
    AVG(CASE WHEN SAFE_CAST(wdsp AS FLOAT64) < 999.9
             THEN SAFE_CAST(wdsp AS FLOAT64) * 0.514444            END) AS wind_ms        -- m s‑1
  FROM
    `bigquery-public-data.noaa_gsod.gsod2019`  g
    JOIN stations_rochester s
      ON g.stn  = s.usaf
     AND g.wban = s.wban
  WHERE
    DATE(CONCAT(year, '-', mo, '-', da)) BETWEEN '2019-01-01' AND '2019-03-31'
  GROUP BY dt
),
ma AS (                                                   -- 8‑day moving averages
  SELECT
    dt,
    ROUND(temp_c ,1)                               AS temp_c,
    ROUND(prcp_cm,1)                               AS prcp_cm,
    ROUND(wind_ms,1)                               AS wind_ms,
    ROUND(AVG(temp_c ) OVER (ORDER BY dt ROWS BETWEEN 7 PRECEDING AND CURRENT ROW),1) AS temp_ma8,
    ROUND(AVG(prcp_cm) OVER (ORDER BY dt ROWS BETWEEN 7 PRECEDING AND CURRENT ROW),1) AS prcp_ma8,
    ROUND(AVG(wind_ms) OVER (ORDER BY dt ROWS BETWEEN 7 PRECEDING AND CURRENT ROW),1) AS wind_ma8
  FROM daily
),
final AS (                                               -- add lag‑difference columns
  SELECT
    dt,
    temp_c, prcp_cm, wind_ms,
    temp_ma8, prcp_ma8, wind_ma8,
    -- temperature MA differences
    ROUND(temp_ma8 - LAG(temp_ma8, 1) OVER (ORDER BY dt),1) AS temp_ma8_diff1,
    ROUND(temp_ma8 - LAG(temp_ma8, 2) OVER (ORDER BY dt),1) AS temp_ma8_diff2,
    ROUND(temp_ma8 - LAG(temp_ma8, 3) OVER (ORDER BY dt),1) AS temp_ma8_diff3,
    ROUND(temp_ma8 - LAG(temp_ma8, 4) OVER (ORDER BY dt),1) AS temp_ma8_diff4,
    ROUND(temp_ma8 - LAG(temp_ma8, 5) OVER (ORDER BY dt),1) AS temp_ma8_diff5,
    ROUND(temp_ma8 - LAG(temp_ma8, 6) OVER (ORDER BY dt),1) AS temp_ma8_diff6,
    ROUND(temp_ma8 - LAG(temp_ma8, 7) OVER (ORDER BY dt),1) AS temp_ma8_diff7,
    ROUND(temp_ma8 - LAG(temp_ma8, 8) OVER (ORDER BY dt),1) AS temp_ma8_diff8,
    -- precipitation MA differences
    ROUND(prcp_ma8 - LAG(prcp_ma8, 1) OVER (ORDER BY dt),1) AS prcp_ma8_diff1,
    ROUND(prcp_ma8 - LAG(prcp_ma8, 2) OVER (ORDER BY dt),1) AS prcp_ma8_diff2,
    ROUND(prcp_ma8 - LAG(prcp_ma8, 3) OVER (ORDER BY dt),1) AS prcp_ma8_diff3,
    ROUND(prcp_ma8 - LAG(prcp_ma8, 4) OVER (ORDER BY dt),1) AS prcp_ma8_diff4,
    ROUND(prcp_ma8 - LAG(prcp_ma8, 5) OVER (ORDER BY dt),1) AS prcp_ma8_diff5,
    ROUND(prcp_ma8 - LAG(prcp_ma8, 6) OVER (ORDER BY dt),1) AS prcp_ma8_diff6,
    ROUND(prcp_ma8 - LAG(prcp_ma8, 7) OVER (ORDER BY dt),1) AS prcp_ma8_diff7,
    ROUND(prcp_ma8 - LAG(prcp_ma8, 8) OVER (ORDER BY dt),1) AS prcp_ma8_diff8,
    -- wind‑speed MA differences
    ROUND(wind_ma8 - LAG(wind_ma8, 1) OVER (ORDER BY dt),1) AS wind_ma8_diff1,
    ROUND(wind_ma8 - LAG(wind_ma8, 2) OVER (ORDER BY dt),1) AS wind_ma8_diff2,
    ROUND(wind_ma8 - LAG(wind_ma8, 3) OVER (ORDER BY dt),1) AS wind_ma8_diff3,
    ROUND(wind_ma8 - LAG(wind_ma8, 4) OVER (ORDER BY dt),1) AS wind_ma8_diff4,
    ROUND(wind_ma8 - LAG(wind_ma8, 5) OVER (ORDER BY dt),1) AS wind_ma8_diff5,
    ROUND(wind_ma8 - LAG(wind_ma8, 6) OVER (ORDER BY dt),1) AS wind_ma8_diff6,
    ROUND(wind_ma8 - LAG(wind_ma8, 7) OVER (ORDER BY dt),1) AS wind_ma8_diff7,
    ROUND(wind_ma8 - LAG(wind_ma8, 8) OVER (ORDER BY dt),1) AS wind_ma8_diff8
  FROM ma
)
SELECT *
FROM final
WHERE dt >= '2019-01-09'           -- first day with a complete 8‑day window
ORDER BY dt;