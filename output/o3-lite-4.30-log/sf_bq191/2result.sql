WITH watchers_2017 AS (
    SELECT
        t."repo":"name"::STRING                    AS repo_name,
        COUNT(DISTINCT t."actor":"login"::STRING)  AS distinct_watcher_count
    FROM "GITHUB_REPOS_DATE"."YEAR"."_2017" t
    WHERE t."type" = 'WatchEvent'
    GROUP BY repo_name
    HAVING COUNT(DISTINCT t."actor":"login"::STRING) > 300
),
repos_in_sample AS (
    SELECT DISTINCT "repo_name"
    FROM "GITHUB_REPOS_DATE"."GITHUB_REPOS"."SAMPLE_FILES"
)
SELECT
    w.repo_name,
    w.distinct_watcher_count
FROM watchers_2017 w
JOIN repos_in_sample s
      ON w.repo_name = s."repo_name"
ORDER BY w.distinct_watcher_count DESC NULLS LAST,
         w.repo_name
LIMIT 2;