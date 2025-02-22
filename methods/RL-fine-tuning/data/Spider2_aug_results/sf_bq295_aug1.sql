-- Task: Using the 2017 GitHub Archive data for watch events, find the top 10 repositories with the highest total number of watch events for that year.

WITH watched_repos AS (
    SELECT
        PARSE_JSON("repo"):"name"::STRING AS "repo"
    FROM 
        GITHUB_REPOS_DATE.MONTH._201701
    WHERE
        "type" = 'WatchEvent'

    UNION ALL

    SELECT
        PARSE_JSON("repo"):"name"::STRING AS "repo"
    FROM 
        GITHUB_REPOS_DATE.MONTH._201702
    WHERE
        "type" = 'WatchEvent'
        
    UNION ALL

    SELECT
        PARSE_JSON("repo"):"name"::STRING AS "repo"
    FROM 
        GITHUB_REPOS_DATE.MONTH._201703
    WHERE
        "type" = 'WatchEvent'
        
    UNION ALL

    SELECT 
        PARSE_JSON("repo"):"name"::STRING AS "repo"
    FROM 
        GITHUB_REPOS_DATE.MONTH._201704
    WHERE
        "type" = 'WatchEvent'
        
    UNION ALL

    SELECT 
        PARSE_JSON("repo"):"name"::STRING AS "repo"
    FROM 
        GITHUB_REPOS_DATE.MONTH._201705
    WHERE
        "type" = 'WatchEvent'
        
    UNION ALL

    SELECT 
        PARSE_JSON("repo"):"name"::STRING AS "repo"
    FROM 
        GITHUB_REPOS_DATE.MONTH._201706
    WHERE
        "type" = 'WatchEvent'
        
    UNION ALL

    SELECT 
        PARSE_JSON("repo"):"name"::STRING AS "repo"
    FROM 
        GITHUB_REPOS_DATE.MONTH._201707
    WHERE
        "type" = 'WatchEvent'
        
    UNION ALL

    SELECT 
        PARSE_JSON("repo"):"name"::STRING AS "repo"
    FROM 
        GITHUB_REPOS_DATE.MONTH._201708
    WHERE
        "type" = 'WatchEvent'
        
    UNION ALL

    SELECT 
        PARSE_JSON("repo"):"name"::STRING AS "repo"
    FROM 
        GITHUB_REPOS_DATE.MONTH._201709
    WHERE
        "type" = 'WatchEvent'
        
    UNION ALL

    SELECT 
        PARSE_JSON("repo"):"name"::STRING AS "repo"
    FROM 
        GITHUB_REPOS_DATE.MONTH._201710
    WHERE
        "type" = 'WatchEvent'
        
    UNION ALL

    SELECT 
        PARSE_JSON("repo"):"name"::STRING AS "repo"
    FROM 
        GITHUB_REPOS_DATE.MONTH._201711
    WHERE
        "type" = 'WatchEvent'
        
    UNION ALL

    SELECT 
        PARSE_JSON("repo"):"name"::STRING AS "repo"
    FROM 
        GITHUB_REPOS_DATE.MONTH._201712
    WHERE
        "type" = 'WatchEvent'
),

repo_watch_counts AS (
    SELECT
        "repo",
        COUNT(*) AS "watch_count"
    FROM
        watched_repos
    GROUP BY
        "repo"
)

SELECT
    REPLACE("repo", '"', '') AS "repo",
    "watch_count"
FROM
    repo_watch_counts
ORDER BY
    "watch_count" DESC
LIMIT
    10;