WITH april_2022_events AS (
    SELECT
        COALESCE("repo":"full_name"::STRING, "repo":"name"::STRING) AS "REPO_NAME",
        "type"                                                      AS "EVENT_TYPE"
    FROM GITHUB_REPOS_DATE.YEAR."_2022"
    WHERE "created_at" >= 1648771200000000      -- 1 Apr 2022 00:00 UTC  (µs)
      AND "created_at" <  1651363200000000      -- 1 May 2022 00:00 UTC  (µs, exclusive)
      AND "type" IN ('ForkEvent', 'IssuesEvent', 'WatchEvent')
),
per_repo_counts AS (
    SELECT
        "REPO_NAME",
        SUM(CASE WHEN "EVENT_TYPE" = 'ForkEvent'   THEN 1 ELSE 0 END) AS "FORKS",
        SUM(CASE WHEN "EVENT_TYPE" = 'IssuesEvent' THEN 1 ELSE 0 END) AS "ISSUES",
        SUM(CASE WHEN "EVENT_TYPE" = 'WatchEvent'  THEN 1 ELSE 0 END) AS "WATCHES",
        COUNT(*)                                                     AS "TOTAL_ACTIVITY"
    FROM april_2022_events
    GROUP BY "REPO_NAME"
),
licensed_repos AS (
    SELECT DISTINCT LOWER("repo_name") AS "REPO_NAME_LOWER"
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.LICENSES
    WHERE "license" IS NOT NULL
)
SELECT
    c."REPO_NAME",
    c."TOTAL_ACTIVITY"
FROM per_repo_counts c
JOIN licensed_repos l
  ON LOWER(c."REPO_NAME") = l."REPO_NAME_LOWER"
ORDER BY
    c."TOTAL_ACTIVITY" DESC NULLS LAST,
    c."REPO_NAME"
LIMIT 1;