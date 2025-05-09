WITH april_events AS (
    SELECT
        "repo":"name"::STRING                                         AS "repo_name",
        CASE WHEN "type" = 'ForkEvent'   THEN 1 ELSE 0 END            AS "fork_cnt",
        CASE WHEN "type" = 'IssuesEvent' THEN 1 ELSE 0 END            AS "issue_cnt",
        CASE WHEN "type" = 'WatchEvent'  THEN 1 ELSE 0 END            AS "watch_cnt"
    FROM GITHUB_REPOS_DATE.YEAR."_2022"
    WHERE "created_at" BETWEEN 1648771200000000 AND 1651363199000000          -- 2022-04-01 .. 2022-04-30 (µs since epoch)
      AND "type" IN ('ForkEvent', 'IssuesEvent', 'WatchEvent')
),
agg AS (
    SELECT
        "repo_name",
        SUM("fork_cnt" + "issue_cnt" + "watch_cnt") AS "total_activity"
    FROM april_events
    GROUP BY "repo_name"
)
SELECT
    a."repo_name",
    l."license",
    a."total_activity"
FROM agg a
JOIN GITHUB_REPOS_DATE.GITHUB_REPOS."LICENSES" l
      ON a."repo_name" = l."repo_name"
WHERE l."license" IS NOT NULL                                   -- “approved” license present
ORDER BY a."total_activity" DESC NULLS LAST
LIMIT 1;