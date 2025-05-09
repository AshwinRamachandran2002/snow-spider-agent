WITH watch_counts AS (
    SELECT
        "repo":"name"::string                         AS repo_name,
        COUNT(DISTINCT "actor":"login"::string)       AS distinct_watchers
    FROM GITHUB_REPOS_DATE.YEAR._2017
    WHERE "type" = 'WatchEvent'
    GROUP BY "repo":"name"
    HAVING COUNT(DISTINCT "actor":"login"::string) > 300
),
repos_in_files AS (
    SELECT DISTINCT "repo_name" AS repo_name
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES
)
SELECT
    w.repo_name,
    w.distinct_watchers
FROM watch_counts w
JOIN repos_in_files f
  ON f.repo_name = w.repo_name
ORDER BY w.distinct_watchers DESC NULLS LAST,
         w.repo_name
LIMIT 2;