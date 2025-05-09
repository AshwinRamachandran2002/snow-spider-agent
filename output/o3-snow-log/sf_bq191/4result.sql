SELECT
    e.repo_name,
    e.watchers_count
FROM (
        SELECT
            "repo":"name"::string              AS repo_name,
            COUNT(DISTINCT "actor":"id"::string) AS watchers_count
        FROM GITHUB_REPOS_DATE.YEAR."_2017"
        WHERE "type" = 'WatchEvent'
        GROUP BY repo_name
        HAVING COUNT(DISTINCT "actor":"id"::string) > 300
     ) e
JOIN GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES sf
     ON sf."repo_name" = e.repo_name
ORDER BY e.watchers_count DESC NULLS LAST
LIMIT 2;