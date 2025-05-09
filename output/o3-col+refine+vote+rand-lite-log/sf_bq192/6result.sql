/* Most-active Python repository in April-2022
   – has ≥1 “.py” file on master
   – licensed under Artistic-2.0, ISC, MIT or Apache-2.0
   – activity = watchers + April-2022 forks + April-2022 issue-related events */

WITH
-- repos that hold at least one Python file on the master branch
py_repos AS (
    SELECT DISTINCT "repo_name"
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES
    WHERE "ref" = 'refs/heads/master'
      AND "path" ILIKE '%.py'
),

-- repos whose license is one of the four permissive licenses
licensed_repos AS (
    SELECT "repo_name"
    FROM   GITHUB_REPOS_DATE.GITHUB_REPOS.LICENSES
    WHERE  "license" IN ('artistic-2.0','isc','mit','apache-2.0')
),

-- candidate repos that satisfy both conditions above
candidates AS (
    SELECT DISTINCT p."repo_name"
    FROM py_repos        p
    JOIN licensed_repos  l  ON p."repo_name" = l."repo_name"
),

-- watcher counts (snapshot) for the repositories we track
watchers AS (
    SELECT "repo_name",
           COALESCE(MAX("watch_count"),0) AS "watch_cnt"
    FROM   GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_REPOS
    GROUP  BY "repo_name"
),

-- April-2022 Issue- and Fork-related GitHub events per repository
apr22_events AS (
    SELECT
        e."repo":"name"::STRING                         AS "repo_name",
        SUM(CASE WHEN e."type" ILIKE '%Issue%' THEN 1 ELSE 0 END) AS "issue_cnt",
        SUM(CASE WHEN e."type" = 'ForkEvent' THEN 1 ELSE 0 END)   AS "fork_cnt"
    FROM   GITHUB_REPOS_DATE.YEAR._2022  e
    WHERE  e."created_at" BETWEEN 1648771200000000   -- 2022-04-01 00:00:00 UTC
                             AND     1651363199000000   -- 2022-04-30 23:59:59 UTC
      AND (e."type" ILIKE '%Issue%' OR e."type" = 'ForkEvent')
    GROUP  BY e."repo":"name"::STRING
)

SELECT
    c."repo_name",
    COALESCE(w."watch_cnt",0) +
    COALESCE(a."issue_cnt",0) +
    COALESCE(a."fork_cnt",0)  AS "activity_score"
FROM   candidates  c
LEFT   JOIN watchers      w ON c."repo_name" = w."repo_name"
LEFT   JOIN apr22_events  a ON c."repo_name" = a."repo_name"
ORDER  BY "activity_score" DESC NULLS LAST
LIMIT 1;