WITH watch_events_2017 AS (
    SELECT
        y."repo":name::STRING   AS "repo_name",
        y."actor":id::STRING    AS "actor_id"
    FROM GITHUB_REPOS_DATE.YEAR."_2017" AS y
    WHERE y."type" = 'WatchEvent'
),
watch_counts AS (
    SELECT
        "repo_name",
        COUNT(DISTINCT "actor_id") AS "distinct_watchers"
    FROM watch_events_2017
    GROUP BY "repo_name"
    HAVING COUNT(DISTINCT "actor_id") > 300
),
sample_repos AS (
    SELECT DISTINCT "repo_name"
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES
)
SELECT
    wc."repo_name",
    wc."distinct_watchers"
FROM watch_counts wc
JOIN sample_repos sr
      ON sr."repo_name" = wc."repo_name"
ORDER BY
    wc."distinct_watchers" DESC NULLS LAST,
    wc."repo_name"        ASC
LIMIT 2;