WITH "PYTHON_REPOS" AS (        -- repos having at least one *.py file on the master branch
    SELECT DISTINCT "repo_name"
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES
    WHERE "ref"  = 'refs/heads/master'
      AND "path" ILIKE '%.py'
),

"LICENSED_REPOS" AS (           -- repos whose licence is one of the required OSS licences
    SELECT "repo_name"
    FROM   GITHUB_REPOS_DATE.GITHUB_REPOS.LICENSES
    WHERE  LOWER("license") IN ('artistic-2.0','isc','mit','apache-2.0')
),

"CANDIDATE_REPOS" AS (          -- repos satisfying both conditions above
    SELECT DISTINCT p."repo_name"
    FROM "PYTHON_REPOS"  p
    JOIN "LICENSED_REPOS" l
      ON p."repo_name" = l."repo_name"
),

"EVENTS_APR_2022" AS (          -- all GitHub events occurring in April‑2022
    SELECT
        "repo":"name" ::string  AS "repo_name",
        "actor":"login"::string AS "actor_login",
        "type"       ::string   AS "event_type"
    FROM  GITHUB_REPOS_DATE.YEAR."_2022"
    WHERE TO_DATE(TO_TIMESTAMP_NTZ("created_at" / 1000000))
          BETWEEN '2022-04-01' AND '2022-04-30'
),

"WATCH_COUNTS" AS (             -- distinct watchers
    SELECT "repo_name", COUNT(DISTINCT "actor_login") AS "watch_cnt"
    FROM   "EVENTS_APR_2022"
    WHERE  "event_type" = 'WatchEvent'
    GROUP  BY "repo_name"
),

"ISSUE_COUNTS" AS (             -- number of issue‑related events
    SELECT "repo_name", COUNT(*) AS "issue_cnt"
    FROM   "EVENTS_APR_2022"
    WHERE  "event_type" = 'IssuesEvent'
    GROUP  BY "repo_name"
),

"FORK_COUNTS" AS (              -- number of forks
    SELECT "repo_name", COUNT(*) AS "fork_cnt"
    FROM   "EVENTS_APR_2022"
    WHERE  "event_type" = 'ForkEvent'
    GROUP  BY "repo_name"
),

"ACTIVITY" AS (                 -- combine the three metrics into a single activity score
    SELECT
        c."repo_name",
        COALESCE(w."watch_cnt", 0) AS "watch_cnt",
        COALESCE(i."issue_cnt", 0) AS "issue_cnt",
        COALESCE(f."fork_cnt",  0) AS "fork_cnt",
        COALESCE(w."watch_cnt", 0)
      + COALESCE(i."issue_cnt", 0)
      + COALESCE(f."fork_cnt",  0) AS "activity_score"
    FROM "CANDIDATE_REPOS" c
    LEFT JOIN "WATCH_COUNTS" w ON c."repo_name" = w."repo_name"
    LEFT JOIN "ISSUE_COUNTS" i ON c."repo_name" = i."repo_name"
    LEFT JOIN "FORK_COUNTS"  f ON c."repo_name" = f."repo_name"
)

SELECT  "repo_name",
        "activity_score"
FROM    "ACTIVITY"
ORDER BY "activity_score" DESC NULLS LAST,
         "repo_name"
LIMIT   1;