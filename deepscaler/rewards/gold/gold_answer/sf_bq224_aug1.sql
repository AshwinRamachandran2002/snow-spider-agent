-- Task: List the repositories and their number of unique watchers in April 2022.
SELECT 
    TRY_PARSE_JSON("repo"):"name"::STRING AS "repo",
    COUNT(DISTINCT TRY_PARSE_JSON("actor"):"login"::STRING) AS "watches"
FROM 
    GITHUB_REPOS_DATE.MONTH._202204
WHERE 
    "type" = 'WatchEvent'
GROUP BY 
    TRY_PARSE_JSON("repo"):"name"
LIMIT 100;