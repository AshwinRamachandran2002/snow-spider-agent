WITH valid_licenses AS (
    SELECT "repo_name"
    FROM "GITHUB_REPOS_DATE"."GITHUB_REPOS"."LICENSES"
    WHERE UPPER("license") IN ('ARTISTIC-2.0','ISC','MIT','APACHE-2.0')
),
python_repos AS (
    SELECT DISTINCT "repo_name"
    FROM "GITHUB_REPOS_DATE"."GITHUB_REPOS"."SAMPLE_FILES"
    WHERE "ref" = 'refs/heads/master'
      AND "path" ILIKE '%.py'
),
issues_apr_2022 AS (
    SELECT "repo":"name"::STRING AS repo_name,
           COUNT(DISTINCT "id") AS issue_cnt
    FROM "GITHUB_REPOS_DATE"."YEAR"."_2022"
    WHERE "type" = 'IssuesEvent'
      AND "created_at" >= 1648771200000000  -- 2022‑04‑01 00:00:00 UTC
      AND "created_at" <  1651363200000000  -- 2022‑05‑01 00:00:00 UTC
    GROUP BY repo_name
),
forks_apr_2022 AS (
    SELECT "repo":"name"::STRING AS repo_name,
           COUNT(DISTINCT "id") AS fork_cnt
    FROM "GITHUB_REPOS_DATE"."YEAR"."_2022"
    WHERE "type" = 'ForkEvent'
      AND "created_at" >= 1648771200000000
      AND "created_at" <  1651363200000000
    GROUP BY repo_name
),
combined AS (
    SELECT sr."repo_name",
           sr."watch_count"                                   AS watches,
           COALESCE(ia.issue_cnt, 0)                          AS issues,
           COALESCE(fa.fork_cnt, 0)                           AS forks,
           sr."watch_count" + COALESCE(ia.issue_cnt,0) +
           COALESCE(fa.fork_cnt,0)                            AS combined_activity_score
    FROM "GITHUB_REPOS_DATE"."GITHUB_REPOS"."SAMPLE_REPOS" sr
    JOIN valid_licenses vl   ON sr."repo_name" = vl."repo_name"
    JOIN python_repos  pr    ON sr."repo_name" = pr."repo_name"
    LEFT JOIN issues_apr_2022 ia ON sr."repo_name" = ia.repo_name
    LEFT JOIN forks_apr_2022  fa ON sr."repo_name" = fa.repo_name
)
SELECT
       "repo_name"                  AS repository,
       combined_activity_score
FROM combined
ORDER BY combined_activity_score DESC NULLS LAST, "repo_name"
LIMIT 1;