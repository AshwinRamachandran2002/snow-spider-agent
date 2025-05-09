WITH lic_repos AS (          -- repos that use one of the required licenses
    SELECT "repo_name"
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.LICENSES
    WHERE LOWER("license") IN ('artistic-2.0','isc','mit','apache-2.0')
),

py_repos AS (                -- repos that contain at least one *.py file on master
    SELECT DISTINCT "repo_name"
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES
    WHERE "ref"  = 'refs/heads/master'
      AND LOWER("path") LIKE '%.py'
),

watchers AS (                -- latest watcher count we have for each repo
    SELECT "repo_name",
           MAX("watch_count") AS "watchers"
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_REPOS
    GROUP BY "repo_name"
),

issue_counts AS (            -- number of issue‑related events in April‑2022
    SELECT ("repo":"name")::STRING AS "repo_name",
           COUNT(*)                AS "issues"
    FROM   GITHUB_REPOS_DATE.YEAR._2022
    WHERE  TO_TIMESTAMP("created_at") >= '2022-04-01'::TIMESTAMP
       AND TO_TIMESTAMP("created_at") <  '2022-05-01'::TIMESTAMP
       AND "type" = 'IssuesEvent'
    GROUP BY ("repo":"name")::STRING
),

fork_counts AS (             -- number of fork events in April‑2022
    SELECT ("repo":"name")::STRING AS "repo_name",
           COUNT(*)                AS "forks"
    FROM   GITHUB_REPOS_DATE.YEAR._2022
    WHERE  TO_TIMESTAMP("created_at") >= '2022-04-01'::TIMESTAMP
       AND TO_TIMESTAMP("created_at") <  '2022-05-01'::TIMESTAMP
       AND "type" = 'ForkEvent'
    GROUP BY ("repo":"name")::STRING
),

candidate_repos AS (         -- repos that satisfy license + python‑file conditions
    SELECT DISTINCT lr."repo_name"
    FROM   lic_repos lr
    JOIN   py_repos  pr
      ON   lr."repo_name" = pr."repo_name"
)

SELECT  c."repo_name",
        COALESCE(w."watchers",0)                        AS "watchers",
        COALESCE(i."issues",  0)                        AS "issues",
        COALESCE(f."forks",   0)                        AS "forks",
        COALESCE(w."watchers",0)
      + COALESCE(i."issues",  0)
      + COALESCE(f."forks",   0)                        AS "activity_score"
FROM    candidate_repos           c
LEFT JOIN watchers     w USING ("repo_name")
LEFT JOIN issue_counts i USING ("repo_name")
LEFT JOIN fork_counts  f USING ("repo_name")
ORDER BY "activity_score" DESC NULLS LAST,
         c."repo_name"
LIMIT 1;