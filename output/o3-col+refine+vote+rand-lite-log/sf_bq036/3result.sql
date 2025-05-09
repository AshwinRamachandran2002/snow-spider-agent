WITH python_repos AS (                               -- repositories that list Python
    SELECT DISTINCT l."repo_name"
    FROM   GITHUB_REPOS.GITHUB_REPOS."LANGUAGES" AS l,
           LATERAL FLATTEN(input => l."language") AS f
    WHERE  LOWER(f.value:"name"::STRING) = 'python'
),
monthly_commit_counts AS (                           -- 2016 commit totals per month
    SELECT  DATE_TRUNC('month',
                       TO_TIMESTAMP_LTZ(c."author":"date"::NUMBER / 1000000)) AS commit_month,
            COUNT(*) AS commit_cnt
    FROM    GITHUB_REPOS.GITHUB_REPOS."SAMPLE_COMMITS" AS c
    JOIN    python_repos  p
           ON c."repo_name" = p."repo_name"
    WHERE   YEAR(TO_TIMESTAMP_LTZ(c."author":"date"::NUMBER / 1000000)) = 2016
    GROUP BY commit_month
)
SELECT  AVG(commit_cnt) AS "avg_commits_per_month_2016"
FROM    monthly_commit_counts;