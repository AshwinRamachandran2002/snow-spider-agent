SELECT
    w."repo_name",
    w."watcher_count"
FROM (
        /* Aggregate 2017 WatchEvents to get distinct‑watcher counts          */
        SELECT
            "repo":"name"::string                 AS "repo_name",
            COUNT(DISTINCT "actor":"login"::string) AS "watcher_count"
        FROM GITHUB_REPOS_DATE.YEAR."_2017"
        WHERE "type" = 'WatchEvent'
        GROUP BY "repo":"name"::string
        HAVING COUNT(DISTINCT "actor":"login"::string) > 300
     ) AS w
     /* Keep only repositories that also appear in SAMPLE_FILES              */
JOIN (
        SELECT DISTINCT "repo_name"
        FROM GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES
     ) AS sf
  ON sf."repo_name" = w."repo_name"
ORDER BY
    w."watcher_count" DESC NULLS LAST,
    w."repo_name"
LIMIT 2;