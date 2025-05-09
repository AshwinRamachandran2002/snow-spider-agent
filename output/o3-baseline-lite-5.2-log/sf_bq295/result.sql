WITH eligible_repos AS (
    /* repositories having at least one sampled .py file < 15 000 bytes that contains "def " */
    SELECT DISTINCT
           "sample_repo_name" AS repo_name
    FROM   GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE  LOWER("sample_path") LIKE '%.py'          -- Python file
      AND  "size" < 15000                           -- < 15 000 bytes
      AND  "content" ILIKE '%def %'                 -- contains the substring "def "
),
watch_counts AS (
    /* 2017 WatchEvent counts per repository */
    SELECT
           ("repo":"name")::string AS repo_name,
           COUNT(*)               AS watch_events
    FROM   GITHUB_REPOS_DATE.YEAR."_2017"
    WHERE  "type" = 'WatchEvent'
    GROUP BY ("repo":"name")::string
)
SELECT
       wc.repo_name,
       wc.watch_events
FROM   watch_counts wc
JOIN   eligible_repos er
       ON wc.repo_name = er.repo_name
ORDER BY
       wc.watch_events DESC NULLS LAST,
       wc.repo_name
LIMIT 3;