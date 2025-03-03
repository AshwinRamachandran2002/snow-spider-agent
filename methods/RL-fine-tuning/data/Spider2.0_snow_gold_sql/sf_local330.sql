SELECT "page",
       SUM("unique_sessions_start") AS "unique_sessions_start",
       SUM("unique_sessions_end") AS "unique_sessions_end"
FROM (
    -- Start pages from ACTIVITY_LOG
    SELECT "path" AS "page", COUNT(DISTINCT "session") AS "unique_sessions_start", 0 AS "unique_sessions_end"
    FROM (
        SELECT al."session", al."path",
               ROW_NUMBER() OVER (PARTITION BY al."session" ORDER BY al."stamp" ASC) AS rn
        FROM LOG.LOG.ACTIVITY_LOG al
    ) sub
    WHERE rn = 1
    GROUP BY "path"
    
    UNION ALL
    
    -- End pages from ACTIVITY_LOG
    SELECT "path" AS "page", 0 AS "unique_sessions_start", COUNT(DISTINCT "session") AS "unique_sessions_end"
    FROM (
        SELECT al."session", al."path",
               ROW_NUMBER() OVER (PARTITION BY al."session" ORDER BY al."stamp" DESC) AS rn
        FROM LOG.LOG.ACTIVITY_LOG al
    ) sub
    WHERE rn = 1
    GROUP BY "path"
    
    UNION ALL
    
    -- Start pages from READ_LOG
    SELECT "url" AS "page", COUNT(DISTINCT "session") AS "unique_sessions_start", 0 AS "unique_sessions_end"
    FROM (
        SELECT rl."session", rl."url",
               ROW_NUMBER() OVER (PARTITION BY rl."session" ORDER BY rl."stamp" ASC) AS rn
        FROM LOG.LOG.READ_LOG rl
    ) sub
    WHERE rn = 1
    GROUP BY "url"
    
    UNION ALL
    
    -- End pages from READ_LOG
    SELECT "url" AS "page", 0 AS "unique_sessions_start", COUNT(DISTINCT "session") AS "unique_sessions_end"
    FROM (
        SELECT rl."session", rl."url",
               ROW_NUMBER() OVER (PARTITION BY rl."session" ORDER BY rl."stamp" DESC) AS rn
        FROM LOG.LOG.READ_LOG rl
    ) sub
    WHERE rn = 1
    GROUP BY "url"
)
GROUP BY "page"
ORDER BY "page" NULLS LAST;