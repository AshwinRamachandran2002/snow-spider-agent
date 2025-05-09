WITH py_repos AS (
    /* Repositories that have at least one small Python file
       (size < 15 000 bytes) whose content includes 'def ' */
    SELECT DISTINCT
           "sample_repo_name"        AS repo_name
    FROM   GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE  LOWER("sample_path") LIKE '%.py'      -- Python files
      AND  "size" < 15000                        -- smaller than 15 000 B
      AND  "content" ILIKE '%def %'              -- contains the substring
),

watch_counts AS (
    /* 2017 WatchEvent counts per repository */
    SELECT
           "repo":name::string        AS repo_name,
           COUNT(*)                   AS watch_event_total
    FROM   GITHUB_REPOS_DATE.YEAR."_2017"
    WHERE  "type" = 'WatchEvent'
      AND  "repo":name IS NOT NULL
    GROUP  BY repo_name
)

/* Top‑3 repositories satisfying both conditions */
SELECT  w.repo_name,
        w.watch_event_total
FROM    watch_counts w
JOIN    py_repos    p
       ON p.repo_name = w.repo_name
ORDER BY w.watch_event_total DESC NULLS LAST,
         w.repo_name
LIMIT 3;