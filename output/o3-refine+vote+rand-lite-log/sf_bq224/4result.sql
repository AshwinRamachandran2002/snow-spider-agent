WITH april_2022_events AS (
    /* forks, issues and watches that happened in April‑2022 */
    SELECT
        "repo":"name"::STRING  AS repo_name
    FROM GITHUB_REPOS_DATE.YEAR."_2022"
    WHERE "type" IN ('ForkEvent','IssuesEvent','WatchEvent')
      AND TO_TIMESTAMP_LTZ("created_at" / 1000000) >= '2022-04-01'
      AND TO_TIMESTAMP_LTZ("created_at" / 1000000) <  '2022-05-01'
), activity_per_repo AS (
    /* combined total of the three kinds of events per repo */
    SELECT
        repo_name,
        COUNT(*) AS total_activity
    FROM april_2022_events
    GROUP BY repo_name
), licensed_repos AS (
    /* keep only repositories that have a (non‑empty) license recorded */
    SELECT
        a.repo_name,
        a.total_activity
    FROM activity_per_repo                       a
    JOIN GITHUB_REPOS_DATE.GITHUB_REPOS.LICENSES l
      ON l."repo_name" = a.repo_name
    WHERE l."license" IS NOT NULL
      AND TRIM(l."license") <> ''
)
SELECT
    repo_name
FROM licensed_repos
ORDER BY total_activity DESC NULLS LAST, repo_name
LIMIT 1;