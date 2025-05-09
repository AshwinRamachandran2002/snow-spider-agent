WITH daily_counts AS (
  SELECT "date", COUNT(*) AS "incident_count"
  FROM AUSTIN.AUSTIN_INCIDENTS.INCIDENTS_2016
  WHERE "descript" = 'PUBLIC INTOXICATION'
  GROUP BY "date"
), stats AS (
  SELECT
    AVG("incident_count") AS "mean_count",
    STDDEV("incident_count") AS "stddev_count"
  FROM daily_counts
)
SELECT "date"
FROM (
  SELECT
    "date",
    ROUND(( "incident_count" - stats."mean_count" ) / NULLIF(stats."stddev_count", 0), 4) AS "z_score",
    ROW_NUMBER() OVER (
      ORDER BY 
        ROUND(( "incident_count" - stats."mean_count" ) / NULLIF(stats."stddev_count", 0), 4) DESC NULLS LAST,
        "date"
    ) AS "rank"
  FROM daily_counts, stats
)
WHERE "rank" = 2
LIMIT 1;