WITH python_repos AS (
    /* repositories that list Python among their languages */
    SELECT DISTINCT
           l."repo_name"
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."LANGUAGES" l,
         LATERAL FLATTEN (INPUT => l."language") f
    WHERE LOWER(f.value:"name"::STRING) = 'python'
), monthly_commits AS (
    /* commit counts per month in 2016 for those repositories */
    SELECT
        DATE_TRUNC('month',
                   TO_TIMESTAMP(c."author":"date"::NUMBER / 1000000))  AS month_2016,
        COUNT(*)                                                    AS commit_cnt
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_COMMITS" c
    JOIN python_repos pr
      ON c."repo_name" = pr."repo_name"
    WHERE TO_TIMESTAMP(c."author":"date"::NUMBER / 1000000)
          BETWEEN '2016-01-01' AND '2016-12-31 23:59:59'
    GROUP BY month_2016
)
SELECT
    AVG(commit_cnt) AS avg_commits_per_month_2016
FROM monthly_commits;