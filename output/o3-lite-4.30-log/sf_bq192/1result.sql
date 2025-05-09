WITH accepted_repos AS (   -- repos with an accepted licence **and** at least one .py file on master
    SELECT DISTINCT l."repo_name"
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.LICENSES      l
    JOIN GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES  f
           ON l."repo_name" = f."repo_name"
    WHERE l."license" IN ('artistic-2.0', 'isc', 'mit', 'apache-2.0')
      AND f."ref"  = 'refs/heads/master'
      AND f."path" ILIKE '%.py'
),
issue_cnt AS (           -- public IssuesEvent counts for April‑2022
    SELECT  "repo":"name"::STRING AS "repo_name",
            COUNT(*)              AS issue_cnt
    FROM    GITHUB_REPOS_DATE.YEAR._2022
    WHERE   "public" = TRUE
      AND   "type"   = 'IssuesEvent'
      AND   TO_TIMESTAMP("created_at"/1000000)
                BETWEEN '2022-04-01' AND '2022-05-01'
    GROUP BY "repo":"name"::STRING
),
fork_cnt AS (            -- public ForkEvent counts for April‑2022
    SELECT  "repo":"name"::STRING AS "repo_name",
            COUNT(*)              AS fork_cnt
    FROM    GITHUB_REPOS_DATE.YEAR._2022
    WHERE   "public" = TRUE
      AND   "type"   = 'ForkEvent'
      AND   TO_TIMESTAMP("created_at"/1000000)
                BETWEEN '2022-04-01' AND '2022-05-01'
    GROUP BY "repo":"name"::STRING
),
combined AS (            -- merge everything and build the activity score
    SELECT
        a."repo_name",
        COALESCE(r."watch_count",0)       AS watchers,
        COALESCE(i.issue_cnt,0)           AS issues,
        COALESCE(f.fork_cnt,0)            AS forks,
        COALESCE(f.fork_cnt,0)*10
        + COALESCE(i.issue_cnt,0)*5
        + COALESCE(r."watch_count",0)     AS combined_activity_score
    FROM accepted_repos                                   a
    LEFT JOIN GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_REPOS r
           ON a."repo_name" = r."repo_name"
    LEFT JOIN issue_cnt                                  i
           ON a."repo_name" = i."repo_name"
    LEFT JOIN fork_cnt                                   f
           ON a."repo_name" = f."repo_name"
)
SELECT
    "repo_name"                        AS repository,
    combined_activity_score
FROM combined
ORDER BY combined_activity_score DESC NULLS LAST, "repo_name"
LIMIT 1;