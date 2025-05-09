/*------------------------------------------------------------
  Most active Python repository in April 2022 (watchers + forks + issues)
  – only repos
      • having at least one “.py” file on the master branch
      • licensed under Artistic‑2.0, ISC, MIT or Apache‑2.0
-------------------------------------------------------------*/
WITH licensed_repos AS (                           -- wanted licences
    SELECT DISTINCT "repo_name"
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.LICENSES
    WHERE LOWER("license") IN ('artistic-2.0','isc','mit','apache-2.0')
),

python_master_repos AS (                           -- at least one .py on master
    SELECT DISTINCT "repo_name"
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES
    WHERE "ref" = 'refs/heads/master'
      AND LOWER("path") LIKE '%.py'
),

watchers AS (                                      -- total watchers per repo
    SELECT "repo_name",
           COALESCE(SUM("watch_count"),0)  AS watch_cnt
    FROM   GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_REPOS
    GROUP  BY "repo_name"
),

events_2022 AS (                                   -- explode 2022 events
    SELECT  "repo":"name"::string        AS repo_name,
            "type"                       AS evt_type,
            TO_TIMESTAMP_NTZ("created_at"/1000) AS evt_time
    FROM    GITHUB_REPOS_DATE.YEAR._2022
),

apr22_issues AS (                                  -- issues opened in April‑2022
    SELECT  repo_name,
            COUNT(*) AS issue_cnt
    FROM    events_2022
    WHERE   evt_type = 'IssuesEvent'
      AND   evt_time >= '2022-04-01'::date
      AND   evt_time <  '2022-05-01'::date
    GROUP BY repo_name
),

apr22_forks AS (                                   -- forks in April‑2022
    SELECT  repo_name,
            COUNT(*) AS fork_cnt
    FROM    events_2022
    WHERE   evt_type = 'ForkEvent'
      AND   evt_time >= '2022-04-01'::date
      AND   evt_time <  '2022-05-01'::date
    GROUP BY repo_name
),

combined AS (                                      -- assemble everything
    SELECT  lr."repo_name",
            COALESCE(w.watch_cnt,0)           AS watch_cnt,
            COALESCE(i.issue_cnt,0)           AS issue_cnt,
            COALESCE(f.fork_cnt,0)            AS fork_cnt,
            COALESCE(w.watch_cnt,0)
          + COALESCE(i.issue_cnt,0)
          + COALESCE(f.fork_cnt,0)            AS activity_score
    FROM    licensed_repos        lr
    JOIN    python_master_repos   pm ON lr."repo_name" = pm."repo_name"
    LEFT JOIN watchers           w  ON lr."repo_name" = w."repo_name"
    LEFT JOIN apr22_issues       i  ON lr."repo_name" = i.repo_name
    LEFT JOIN apr22_forks        f  ON lr."repo_name" = f.repo_name
)

SELECT  "repo_name",
        activity_score
FROM    combined
ORDER BY activity_score DESC NULLS LAST,
         "repo_name"
LIMIT 1;