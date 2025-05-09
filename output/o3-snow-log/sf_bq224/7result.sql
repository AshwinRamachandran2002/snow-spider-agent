WITH april_events AS (
    SELECT
        "repo":"name"::STRING AS "REPO_NAME",
        COUNT(*)              AS "EVENTS_TOTAL"
    FROM GITHUB_REPOS_DATE.YEAR."_2022"
    WHERE TO_TIMESTAMP("created_at" / 1000000) >= '2022-04-01'
      AND TO_TIMESTAMP("created_at" / 1000000) <  '2022-05-01'
      AND "type" IN ('ForkEvent', 'IssuesEvent', 'WatchEvent')
    GROUP BY "repo":"name"::STRING
)
SELECT
    ae."REPO_NAME",
    ae."EVENTS_TOTAL" AS "FORK_ISSUE_WATCH_TOTAL"
FROM april_events ae
JOIN GITHUB_REPOS_DATE.GITHUB_REPOS.LICENSES lic
  ON ae."REPO_NAME" = lic."repo_name"
WHERE lic."license" IS NOT NULL
ORDER BY ae."EVENTS_TOTAL" DESC NULLS LAST
LIMIT 1;