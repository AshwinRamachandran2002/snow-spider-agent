WITH ranked AS (
  SELECT
    "session",
    "path",
    ROW_NUMBER() OVER (PARTITION BY "session" ORDER BY "stamp")       AS rn_first,
    ROW_NUMBER() OVER (PARTITION BY "session" ORDER BY "stamp" DESC)  AS rn_last
  FROM activity_log
  WHERE "action" = 'view'
    AND "path" IS NOT NULL
),
landing_exit AS (
  SELECT "session", "path" FROM ranked WHERE rn_first = 1
  UNION
  SELECT "session", "path" FROM ranked WHERE rn_last  = 1
)
SELECT
  "path" AS web_page,
  COUNT(DISTINCT "session") AS total_sessions
FROM landing_exit
GROUP BY "path"
ORDER BY total_sessions DESC, web_page;