WITH monthly_commits AS (
    SELECT
        TO_CHAR(
            TO_TIMESTAMP( (sc."committer":"date")::NUMBER / 1000000 ),
            'YYYY-MM'
        )                          AS "year_month",
        COUNT(*)                   AS "commits_in_month"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS  AS sc
    JOIN GITHUB_REPOS.GITHUB_REPOS.LANGUAGES       AS lg
          ON sc."repo_name" = lg."repo_name"
    WHERE lg."language" ILIKE '%python%'                         -- repos containing Python
      AND TO_CHAR(
            TO_TIMESTAMP( (sc."committer":"date")::NUMBER / 1000000 ),
            'YYYY'
          ) = '2016'                                             -- commits in 2016 only
    GROUP BY "year_month"
)
SELECT AVG("commits_in_month") AS "avg_commits_per_month_2016"
FROM   monthly_commits;