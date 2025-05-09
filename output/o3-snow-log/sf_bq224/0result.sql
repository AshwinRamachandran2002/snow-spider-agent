WITH april_events AS (
    SELECT
        ("repo":"name")::string AS REPO_NAME
    FROM GITHUB_REPOS_DATE.YEAR."_2022"
    WHERE "type" IN ('ForkEvent', 'IssuesEvent', 'WatchEvent')
      AND TO_TIMESTAMP_NTZ("created_at" / 1000000) >= '2022-04-01'
      AND TO_TIMESTAMP_NTZ("created_at" / 1000000) <  '2022-05-01'
), approved_repos AS (
    SELECT
        "repo_name" AS REPO_NAME
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.LICENSES
    WHERE "license" IS NOT NULL
)
SELECT
    ae.REPO_NAME,
    COUNT(*) AS COMBINED_TOTAL
FROM april_events  ae
JOIN approved_repos ar
  ON ae.REPO_NAME = ar.REPO_NAME
GROUP BY ae.REPO_NAME
ORDER BY COMBINED_TOTAL DESC NULLS LAST
LIMIT 1;