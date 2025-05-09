SELECT a."session", a."path", a."search_type"
FROM LOG.LOG.ACTIVITY_LOG AS a
WHERE a."search_type" IS NOT NULL AND a."search_type" <> ''
  AND a."session" IN (
    SELECT "session"
    FROM (
      SELECT "session", COUNT(*) AS "event_count"
      FROM LOG.LOG.ACTIVITY_LOG
      WHERE "search_type" IS NOT NULL AND "search_type" <> ''
        AND "session" NOT IN (
          SELECT "session"
          FROM LOG.LOG.ACTIVITY_LOG
          WHERE "path" LIKE '%/detail%' OR "path" LIKE '%/complete%'
        )
      GROUP BY "session"
      HAVING COUNT(*) = (
        SELECT MIN("event_count")
        FROM (
          SELECT "session", COUNT(*) AS "event_count"
          FROM LOG.LOG.ACTIVITY_LOG
          WHERE "search_type" IS NOT NULL AND "search_type" <> ''
            AND "session" NOT IN (
              SELECT "session"
              FROM LOG.LOG.ACTIVITY_LOG
              WHERE "path" LIKE '%/detail%' OR "path" LIKE '%/complete%'
            )
          GROUP BY "session"
        ) AS min_counts
      )
    ) AS sessions_with_min_events
  );