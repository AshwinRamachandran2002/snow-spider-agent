WITH python_repos AS (
    SELECT DISTINCT l."repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES AS l,
         LATERAL FLATTEN(input => l."language") AS f
    WHERE LOWER(f.value:"name"::STRING) = 'python'
), monthly_commits AS (
    SELECT
        TO_CHAR(
            TO_TIMESTAMP_NTZ((c."author":"date")::NUMBER / 1000000),
            'YYYY-MM'
        ) AS "year_month",
        COUNT(*) AS "commit_cnt"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS AS c
    JOIN python_repos AS pr
      ON c."repo_name" = pr."repo_name"
    WHERE TO_CHAR(
              TO_TIMESTAMP_NTZ((c."author":"date")::NUMBER / 1000000),
              'YYYY'
          ) = '2016'
    GROUP BY "year_month"
)
SELECT
    AVG("commit_cnt") AS "avg_commits_per_month_2016"
FROM monthly_commits;