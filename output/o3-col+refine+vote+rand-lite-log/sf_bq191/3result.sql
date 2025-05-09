WITH watch_counts AS (
    SELECT
        t."repo":"name"::STRING                                   AS "repo_name",
        COUNT(DISTINCT t."actor":"id"::STRING)                    AS "distinct_watchers"
    FROM GITHUB_REPOS_DATE.YEAR."_2017" t
    WHERE t."type" = 'WatchEvent'
    GROUP BY 1
    HAVING COUNT(DISTINCT t."actor":"id"::STRING) > 300
)

SELECT
    w."repo_name",
    w."distinct_watchers"
FROM watch_counts w
JOIN GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES sf
      ON sf."repo_name" = w."repo_name"
GROUP BY
    w."repo_name",
    w."distinct_watchers"
ORDER BY
    w."distinct_watchers" DESC NULLS LAST
LIMIT 2;