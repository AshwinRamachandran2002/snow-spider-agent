WITH temperature AS (
  /* 1.  Daily mean temperature (°F) for LaGuardia (725030) & JFK (744860),
         averaged between the two sites, 2008‑2017                                    */
  SELECT
    DATE(CONCAT(year,'-',LPAD(mo,2,'0'),'-',LPAD(da,2,'0'))) AS dt,
    AVG(temp)                                                AS temp_f
  FROM `bigquery-public-data.noaa_gsod.gsod20*`
  WHERE CAST(year AS INT64) BETWEEN 2008 AND 2017
    AND stn IN ('725030','744860')          -- LaGuardia & JFK
    AND temp != 9999.9                      -- drop missing values
  GROUP BY dt
),
daily_complaints AS (
  /* 2.  Count 311 complaints per type per day (NYC)                                 */
  SELECT
    DATE(created_date)   AS dt,
    complaint_type,
    COUNT(*)             AS daily_cnt
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE created_date BETWEEN '2008-01-01' AND '2017-12-31'
  GROUP BY dt, complaint_type
),
daily_with_pct AS (
  /* 3.  Compute each type’s share of total complaints for that day                  */
  SELECT
    dc.dt,
    dc.complaint_type,
    dc.daily_cnt,
    SUM(dc.daily_cnt) OVER (PARTITION BY dc.dt)                                 AS daily_total,
    SAFE_DIVIDE(dc.daily_cnt,
                SUM(dc.daily_cnt) OVER (PARTITION BY dc.dt))                    AS daily_pct
  FROM daily_complaints dc
),
joined AS (
  /* 4.  Merge with temperature – keep only dates that have valid temp readings      */
  SELECT
    t.dt,
    d.complaint_type,
    d.daily_cnt,
    d.daily_pct,
    t.temp_f
  FROM temperature t
  JOIN daily_with_pct d
    ON t.dt = d.dt
),
summary AS (
  /* 5.  Aggregate & compute Pearson correlations                                    */
  SELECT
    complaint_type,
    SUM(daily_cnt)                              AS total_complaints,
    COUNT(DISTINCT dt)                          AS days_with_valid_temp,
    ROUND(CORR(temp_f, daily_cnt), 4)           AS corr_cnt_temp,
    ROUND(CORR(temp_f, daily_pct), 4)           AS corr_pct_temp
  FROM joined
  GROUP BY complaint_type
)
SELECT
  complaint_type,
  total_complaints,
  days_with_valid_temp,
  corr_cnt_temp,
  corr_pct_temp
FROM summary
WHERE total_complaints > 5000
  AND (ABS(corr_cnt_temp) > 0.5 OR ABS(corr_pct_temp) > 0.5)
ORDER BY complaint_type;