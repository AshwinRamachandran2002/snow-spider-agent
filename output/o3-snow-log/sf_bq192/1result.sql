WITH apr2022_events AS (
    SELECT
        "type"                                                   AS event_type,
        TO_TIMESTAMP_NTZ("created_at" / 1000000)                 AS event_time,
        "repo":"name"::STRING                                    AS repo_name,
        "actor":"id"::STRING                                     AS actor_id
    FROM   "GITHUB_REPOS_DATE"."YEAR"."_2022"
    WHERE  DATE(TO_TIMESTAMP_NTZ("created_at" / 1000000))
           BETWEEN '2022-04-01' AND '2022-04-30'
),

watch_counts AS (
    SELECT repo_name,
           COUNT(DISTINCT actor_id)                              AS watches
    FROM   apr2022_events
    WHERE  event_type = 'WatchEvent'
    GROUP BY repo_name
),

issue_counts AS (
    SELECT repo_name,
           COUNT(*)                                             AS issues
    FROM   apr2022_events
    WHERE  event_type = 'IssuesEvent'
    GROUP BY repo_name
),

fork_counts AS (
    SELECT repo_name,
           COUNT(*)                                             AS forks
    FROM   apr2022_events
    WHERE  event_type = 'ForkEvent'
    GROUP BY repo_name
),

eligible_repos AS (
    SELECT DISTINCT "repo_name" AS repo_name
    FROM   "GITHUB_REPOS_DATE"."GITHUB_REPOS"."SAMPLE_FILES"
    WHERE  "ref" = 'refs/heads/master'
      AND  LOWER("path") LIKE '%.py'
),

licensed_repos AS (
    SELECT "repo_name" AS repo_name
    FROM   "GITHUB_REPOS_DATE"."GITHUB_REPOS"."LICENSES"
    WHERE  LOWER("license") IN ('artistic-2.0', 'isc', 'mit', 'apache-2.0')
)

SELECT
       lr.repo_name,
       COALESCE(fc.forks, 0)
     + COALESCE(ic.issues, 0)
     + COALESCE(wc.watches, 0) AS activity_score
FROM   licensed_repos  lr
JOIN   eligible_repos  er ON er.repo_name = lr.repo_name
LEFT   JOIN fork_counts  fc ON fc.repo_name = lr.repo_name
LEFT   JOIN issue_counts ic ON ic.repo_name = lr.repo_name
LEFT   JOIN watch_counts wc ON wc.repo_name = lr.repo_name
ORDER  BY activity_score DESC NULLS LAST
LIMIT  1;