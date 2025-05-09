WITH issues_apr_2022 AS (
    SELECT
        t."repo":name::STRING AS "repo_name",
        COUNT(*)              AS "issue_cnt"
    FROM GITHUB_REPOS_DATE.YEAR."_2022" t
    WHERE t."type" = 'IssuesEvent'
      AND t."created_at" BETWEEN 1648771200000000 AND 1651363199000000   -- 2022-04-01 .. 2022-04-30 (µs)
    GROUP BY "repo_name"
),
forks_apr_2022 AS (
    SELECT
        t."repo":name::STRING AS "repo_name",
        COUNT(*)              AS "fork_cnt"
    FROM GITHUB_REPOS_DATE.YEAR."_2022" t
    WHERE t."type" = 'ForkEvent'
      AND t."created_at" BETWEEN 1648771200000000 AND 1651363199000000
    GROUP BY "repo_name"
),
py_repos AS (
    SELECT DISTINCT "repo_name"
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES
    WHERE "path" ILIKE '%.py'
      AND "ref"  = 'refs/heads/master'
),
licensed_repos AS (
    SELECT DISTINCT "repo_name"
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.LICENSES
    WHERE "license" ILIKE ANY ('%artistic-2.0%','%isc%','%mit%','%apache-2.0%')
),
watchers AS (
    SELECT "repo_name",
           "watch_count"
    FROM   GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_REPOS
)

SELECT
    core."repo_name",
    COALESCE(w."watch_count",0) +
    COALESCE(i."issue_cnt",0)   +
    COALESCE(f."fork_cnt",0)    AS "activity_score"
FROM (
    SELECT p."repo_name"
    FROM   py_repos       p
    JOIN   licensed_repos l ON p."repo_name" = l."repo_name"
) core
LEFT JOIN watchers       w ON core."repo_name" = w."repo_name"
LEFT JOIN issues_apr_2022 i ON core."repo_name" = i."repo_name"
LEFT JOIN forks_apr_2022  f ON core."repo_name" = f."repo_name"
ORDER BY "activity_score" DESC NULLS LAST
LIMIT 1;