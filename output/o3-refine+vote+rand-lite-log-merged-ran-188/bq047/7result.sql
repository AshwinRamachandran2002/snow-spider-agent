/*  Relationship between daily temperature (LaGuardia & JFK) and 311 complaints
    Window : 2008-01-01 ‑ 2017-12-31 (10 years)
    1.  Build daily average temperature from the two airport stations
       (exclude missing 9999.9 values).
    2.  Build daily complaint counts & daily totals.
    3.  Correlate temperature with:
          a) raw daily count
          b) daily share of total complaints
    4.  Keep complaint types with >5 000 complaints and |corr|>0.5 on *both* metrics.
*/

WITH temps AS (          -- daily mean temperature for LGA (725030) & JFK (744860)
  SELECT
    DATE(CONCAT('20', _TABLE_SUFFIX, '-', LPAD(mo,2,'0'), '-', LPAD(da,2,'0'))) AS day,
    AVG(temp) AS temp                               -- average of the 2 stations (when present)
  FROM `bigquery-public-data.noaa_gsod.gsod20*`
  WHERE _TABLE_SUFFIX BETWEEN '08' AND '17'
    AND stn IN ('725030','744860')
    AND temp < 9000                                 -- filter out 9999.9 (missing)
  GROUP BY day
),

daily_complaints AS (    -- daily count per complaint type
  SELECT
    DATE(created_date)     AS day,
    complaint_type,
    COUNT(*)               AS cnt
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE DATE(created_date) BETWEEN '2008-01-01' AND '2017-12-31'
  GROUP BY day, complaint_type
),

daily_tot AS (           -- total complaints each day
  SELECT
    day,
    SUM(cnt) AS day_tot
  FROM daily_complaints
  GROUP BY day
),

metrics AS (             -- compute correlations
  SELECT
    dc.complaint_type,
    COUNT(*)                          AS valid_days,          -- days used in corr
    SUM(dc.cnt)                       AS total_complaints,
    CORR(dc.cnt,          t.temp)     AS corr_cnt,
    CORR(100.0 * dc.cnt / dt.day_tot,
                        t.temp)       AS corr_pct
  FROM daily_complaints dc
  JOIN temps t USING(day)             -- keep only days with a valid temperature
  JOIN daily_tot dt USING(day)
  GROUP BY dc.complaint_type
)

SELECT
  complaint_type,
  total_complaints,
  valid_days,
  ROUND(corr_cnt , 4) AS corr_count_temp,
  ROUND(corr_pct , 4) AS corr_share_temp
FROM metrics
WHERE total_complaints > 5000
  AND ABS(corr_cnt)  > 0.5
  AND ABS(corr_pct)  > 0.5
ORDER BY total_complaints DESC;