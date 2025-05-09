WITH first_paths AS (
  SELECT
    "session",
    "path",
    ROW_NUMBER() OVER (PARTITION BY "session" ORDER BY "stamp" ASC, "path" ASC) AS rn
  FROM LOG.LOG.ACTIVITY_LOG
  WHERE "path" IS NOT NULL AND "path" <> ''
),
last_paths AS (
  SELECT
    "session",
    "path",
    ROW_NUMBER() OVER (PARTITION BY "session" ORDER BY "stamp" DESC, "path" ASC) AS rn
  FROM LOG.LOG.ACTIVITY_LOG
  WHERE "path" IS NOT NULL AND "path" <> ''
),
session_paths AS (
  SELECT f."session", f."path" AS "first_path", l."path" AS "last_path"
  FROM first_paths f
  INNER JOIN last_paths l ON f."session" = l."session"
  WHERE f.rn = 1 AND l.rn = 1
),
start_paths AS (
  SELECT "first_path" AS "url_or_path", COUNT(DISTINCT "session") AS "unique_sessions_start"
  FROM session_paths
  GROUP BY "first_path"
),
end_paths AS (
  SELECT "last_path" AS "url_or_path", COUNT(DISTINCT "session") AS "unique_sessions_end"
  FROM session_paths
  GROUP BY "last_path"
),
combined AS (
  SELECT "url_or_path", "unique_sessions_start", 0 AS "unique_sessions_end"
  FROM start_paths
  UNION ALL
  SELECT "url_or_path", 0 AS "unique_sessions_start", "unique_sessions_end"
  FROM end_paths
)
SELECT
  "url_or_path",
  SUM("unique_sessions_start") AS "unique_sessions_start",
  SUM("unique_sessions_end") AS "unique_sessions_end"
FROM combined
GROUP BY "url_or_path"
ORDER BY "url_or_path" ASC NULLS LAST;