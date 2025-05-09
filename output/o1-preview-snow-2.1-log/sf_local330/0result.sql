WITH first_last_pages AS (
  SELECT
    s."session",
    s."path",
    ROW_NUMBER() OVER (
      PARTITION BY s."session"
      ORDER BY TO_TIMESTAMP(s."stamp") ASC NULLS LAST
    ) AS rn_start,
    ROW_NUMBER() OVER (
      PARTITION BY s."session"
      ORDER BY TO_TIMESTAMP(s."stamp") DESC NULLS LAST
    ) AS rn_end
  FROM LOG.LOG.ACTIVITY_LOG s
)
SELECT
  p."path" AS "url_or_path",
  COUNT(DISTINCT CASE WHEN p.rn_start = 1 THEN p."session" END) AS "unique_sessions_start",
  COUNT(DISTINCT CASE WHEN p.rn_end = 1 THEN p."session" END) AS "unique_sessions_end"
FROM first_last_pages p
GROUP BY p."path"
ORDER BY p."path" NULLS LAST;