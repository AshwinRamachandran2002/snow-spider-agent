WITH april_events AS (
    SELECT
        "repo":"name"::string AS "REPO_NAME",
        CASE WHEN "type" = 'ForkEvent' THEN 1 ELSE 0 END                                              AS "FORK_CNT",
        CASE WHEN "type" = 'IssuesEvent' AND "payload" ILIKE '%"action":"opened"%'  THEN 1 ELSE 0 END AS "ISSUE_CNT",
        CASE WHEN "type" = 'WatchEvent'  AND "payload" ILIKE '%"action":"started"%' THEN 1 ELSE 0 END AS "WATCH_CNT"
    FROM GITHUB_REPOS_DATE.YEAR."_2022"
    WHERE "created_at" >= 1648771200000000   -- 2022-04-01 00:00:00 UTC
      AND "created_at" <  1651363200000000   -- 2022-05-01 00:00:00 UTC
), agg AS (
    SELECT
        "REPO_NAME",
        SUM("FORK_CNT")  AS "FORKS",
        SUM("ISSUE_CNT") AS "ISSUES",
        SUM("WATCH_CNT") AS "WATCHES",
        SUM("FORK_CNT" + "ISSUE_CNT" + "WATCH_CNT") AS "TOTAL_ACTIVITY"
    FROM april_events
    GROUP BY "REPO_NAME"
)
SELECT
    a."REPO_NAME",
    a."TOTAL_ACTIVITY"
FROM agg a
JOIN GITHUB_REPOS_DATE.GITHUB_REPOS.LICENSES l
  ON a."REPO_NAME" = l."repo_name"
WHERE l."license" IS NOT NULL
ORDER BY a."TOTAL_ACTIVITY" DESC NULLS LAST
LIMIT 1;