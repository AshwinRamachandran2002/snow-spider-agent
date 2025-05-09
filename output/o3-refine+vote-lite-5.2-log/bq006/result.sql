/* Date with the second‑highest daily Z‑score for “PUBLIC INTOXICATION” incidents in 2016 */
WITH daily_counts AS (                 -- number of incidents per day
  SELECT
    `date` AS incident_date,           -- `date` column is already DATE type
    COUNT(*)  AS daily_total
  FROM `bigquery-public-data.austin_incidents.incidents_2016`
  WHERE
    UPPER(TRIM(descript)) = 'PUBLIC INTOXICATION'
  GROUP BY incident_date
),
stats AS (                             -- overall mean & std‑dev
  SELECT
    AVG(daily_total)               AS mean_cnt,
    STDDEV_SAMP(daily_total)       AS sd_cnt
  FROM daily_counts
),
scored AS (                            -- compute Z‑score for each day
  SELECT
    incident_date,
    SAFE_DIVIDE(daily_total - mean_cnt, sd_cnt) AS z_score
  FROM daily_counts, stats
),
ranked AS (                            -- rank days by Z‑score
  SELECT
    incident_date,
    z_score,
    ROW_NUMBER() OVER (ORDER BY z_score DESC, incident_date) AS rn
  FROM scored
)
SELECT
  FORMAT_DATE('%Y-%m-%d', incident_date) AS `2016_date`
FROM ranked
WHERE rn = 2;