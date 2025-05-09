WITH commits_per_month AS (
    SELECT
        TO_CHAR(
            TO_TIMESTAMP_NTZ( ("author":"date"::NUMBER) / 1000000 ),
            'YYYY-MM'
        )                                            AS "yyyy_mm",
        COUNT(*)                                     AS "commit_cnt"
    FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS  AS c
    JOIN   GITHUB_REPOS.GITHUB_REPOS.LANGUAGES       AS l
           ON c."repo_name" = l."repo_name"
    WHERE  l."language" ILIKE '%Python%'                         -- repos containing Python
      AND  TO_CHAR(
               TO_TIMESTAMP_NTZ( ("author":"date"::NUMBER) / 1000000 ),
               'YYYY'
           ) = '2016'                                            -- commits made in 2016
    GROUP  BY 1
)
SELECT AVG("commit_cnt") AS "avg_commits_per_month_2016"
FROM   commits_per_month;