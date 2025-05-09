WITH python_repos AS (          -- repos that have at least one qualifying Python file
    SELECT DISTINCT LOWER("sample_repo_name") AS "repo_name"
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE LOWER("sample_path") LIKE '%.py'          -- Python file
      AND "size" < 15000                            -- smaller than 15 000 bytes
      AND POSITION('def ' IN "content") > 0         -- contains the substring ‘def ’
),

watch_events_2017 AS (          -- all 2017 WatchEvent rows
    SELECT LOWER("repo":"name"::STRING) AS "repo_name"
    FROM GITHUB_REPOS_DATE.YEAR."_2017"
    WHERE "type" = 'WatchEvent'
),

watch_counts AS (               -- watch‑event totals per repo
    SELECT "repo_name",
           COUNT(*) AS "watch_events"
    FROM watch_events_2017
    GROUP BY "repo_name"
)

SELECT "repo_name",
       "watch_events"
FROM watch_counts
WHERE "repo_name" IN (SELECT "repo_name" FROM python_repos)   -- only repos with qualifying .py file
ORDER BY "watch_events" DESC NULLS LAST, "repo_name"
LIMIT 3;                                                      -- top‑3 repositories