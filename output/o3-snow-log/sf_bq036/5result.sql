WITH python_repos AS (
    -- repositories that contain at least some Python code
    SELECT DISTINCT "repo_name"
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."LANGUAGES",
         LATERAL FLATTEN(input => "language") f
    WHERE LOWER(f.value:"name"::STRING) = 'python'
),
monthly_commits AS (
    -- commit counts per month in 2016 for those repositories
    SELECT
        TO_CHAR(
            TO_TIMESTAMP_NTZ(("author"::VARIANT:"date"::NUMBER) / 1000000),
            'YYYY-MM'
        )                           AS "year_month",
        COUNT(*)                    AS "commit_count"
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_COMMITS" c
    JOIN python_repos p
      ON c."repo_name" = p."repo_name"
    WHERE TO_TIMESTAMP_NTZ(("author"::VARIANT:"date"::NUMBER) / 1000000)
          BETWEEN '2016-01-01' AND '2016-12-31 23:59:59'
    GROUP BY "year_month"
)
-- average commits per month across 2016
SELECT AVG("commit_count") AS "avg_commits_per_month_2016"
FROM   monthly_commits;