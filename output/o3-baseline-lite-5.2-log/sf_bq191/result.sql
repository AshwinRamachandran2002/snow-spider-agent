WITH watchers AS (          -- all 2017 WatchEvents (user‑repo pairs)
    SELECT
        "repo":"name"::string   AS REPO_NAME,
        "actor":"login"::string AS WATCHER
    FROM GITHUB_REPOS_DATE.YEAR._2017
    WHERE "type" = 'WatchEvent'
),
watcher_counts AS (         -- repos with > 300 distinct watchers
    SELECT
        REPO_NAME,
        COUNT(DISTINCT WATCHER) AS DISTINCT_WATCHERS
    FROM watchers
    GROUP BY REPO_NAME
    HAVING COUNT(DISTINCT WATCHER) > 300
),
sample_repos AS (           -- repos present in SAMPLE_FILES
    SELECT DISTINCT
        "repo_name" AS REPO_NAME
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES
)
SELECT
    wc.REPO_NAME         AS repo_name,
    wc.DISTINCT_WATCHERS AS distinct_watchers
FROM watcher_counts wc
JOIN sample_repos sr
      ON wc.REPO_NAME = sr.REPO_NAME
ORDER BY wc.DISTINCT_WATCHERS DESC NULLS LAST,
         wc.REPO_NAME
LIMIT 2;