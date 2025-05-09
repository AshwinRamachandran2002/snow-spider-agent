WITH pull_requests AS (
    SELECT t."repo":name::STRING AS "repo_name"
    FROM GITHUB_REPOS_DATE.YEAR."_2023" t
    WHERE t."type" = 'PullRequestEvent'
        AND DATE(TO_TIMESTAMP(t."created_at" / 1e6)) = '2023-01-18'
),
pull_requests_per_repo AS (
    SELECT "repo_name", COUNT(*) AS "num_pull_requests"
    FROM pull_requests
    GROUP BY "repo_name"
),
primary_language_per_repo AS (
    SELECT 
        t."repo_name",
        l.VALUE:"name"::STRING AS "language_name",
        l.VALUE:"bytes"::NUMBER AS "bytes",
        ROW_NUMBER() OVER (PARTITION BY t."repo_name" ORDER BY l.VALUE:"bytes"::NUMBER DESC) AS "rn"
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.LANGUAGES t,
         LATERAL FLATTEN(INPUT => t."language") l
),
repos_with_primary_language AS (
    SELECT "repo_name", "language_name" AS "primary_language"
    FROM primary_language_per_repo
    WHERE "rn" = 1
)
SELECT
    r."primary_language",
    SUM(p."num_pull_requests") AS "total_pull_requests"
FROM repos_with_primary_language r
JOIN pull_requests_per_repo p ON r."repo_name" = p."repo_name"
GROUP BY r."primary_language"
HAVING SUM(p."num_pull_requests") > 5
ORDER BY "total_pull_requests" DESC NULLS LAST;