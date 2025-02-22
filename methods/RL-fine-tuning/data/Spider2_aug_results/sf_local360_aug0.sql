-- Task: For each session, identify the events that occur before the first '/detail' click or '/complete' conversion within that session, considering only events where "search_type" is non-empty (not null or empty string). Determine the sessions that have the minimal number of such events. For these sessions, display the "session", "path", and "search_type" of the events occurring before the first '/detail' or '/complete' event.
WITH activity_log_with_session_click_conversion_flag AS (
  SELECT
    "session",
    "stamp",
    "path",
    "search_type",
    CASE
      WHEN LAG("path") OVER (PARTITION BY "session" ORDER BY "stamp" DESC) = '/detail'
        THEN 1
      ELSE 0
    END AS "has_session_click",
    SIGN(
      SUM(CASE WHEN "path" = '/complete' THEN 1 ELSE 0 END)
      OVER (PARTITION BY "session" ORDER BY "stamp" DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
    ) AS "has_session_conversion"
  FROM
    LOG.LOG.ACTIVITY_LOG
),

counts AS (
  SELECT
    "session",
    "path",
    "search_type",
    COUNT(*) AS "count_zeros"
  FROM
    activity_log_with_session_click_conversion_flag
  WHERE
    "has_session_click" = 0
    AND "has_session_conversion" = 0
    AND "search_type" IS NOT NULL
    AND TRIM("search_type") <> ''
  GROUP BY
    "session",
    "path",
    "search_type"
),

min_count AS (
  SELECT
    MIN("count_zeros") AS "min_zeros"
  FROM
    counts
)

SELECT
  c."session",
  c."path",
  c."search_type"
FROM
  counts c
JOIN
  min_count mc ON c."count_zeros" = mc."min_zeros"
ORDER BY
  c."count_zeros";