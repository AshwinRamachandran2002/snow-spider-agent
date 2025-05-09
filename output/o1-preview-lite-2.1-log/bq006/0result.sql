SELECT
  `date`
FROM (
  SELECT
    `date`,
    ROW_NUMBER() OVER (ORDER BY z_score DESC) AS rn
  FROM (
    SELECT
      `date`,
      ROUND((incident_count - AVG(incident_count) OVER ()) / STDDEV_SAMP(incident_count) OVER (), 4) AS z_score
    FROM (
      SELECT
        `date`,
        COUNT(*) AS incident_count
      FROM
        `bigquery-public-data.austin_incidents.incidents_2016`
      WHERE
        LOWER(`descript`) LIKE '%public intoxication%'
      GROUP BY
        `date`
    )
  )
)
WHERE rn = 2;