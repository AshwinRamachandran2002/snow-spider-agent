/*  Most active Python repo in April-2022 based on forks + issues + distinct watchers,
    limited to repos that
      • have at least one *.py file on the master branch
      • use an approved open-source licence (Artistic-2.0, ISC, MIT, Apache-2.0)
*/
WITH allowed_licenses AS (
    SELECT "repo_name"
    FROM "GITHUB_REPOS_DATE"."GITHUB_REPOS"."LICENSES"
    WHERE "license" ILIKE ANY ('%artistic-2.0%','%isc%','%mit%','%apache-2.0%')
),
python_repos AS (
    SELECT DISTINCT "repo_name"
    FROM "GITHUB_REPOS_DATE"."GITHUB_REPOS"."SAMPLE_FILES"
    WHERE "ref" = 'refs/heads/master'
      AND LOWER("path") LIKE '%.py'
),
event_window AS (
    SELECT
        "repo":"name"::STRING  AS "repo_name",
        "type"                 AS "event_type",
        "actor":"id"::STRING   AS "actor_id"
    FROM "GITHUB_REPOS_DATE"."YEAR"."_2022"
    WHERE "created_at" BETWEEN 1648771200000000 AND 1651363199000000   -- 2022-04-01 … 2022-04-30
),
aggregated AS (
    SELECT
        "repo_name",
        SUM(CASE WHEN "event_type" = 'ForkEvent'
                 THEN 1 ELSE 0 END)                                      AS "forks",
        SUM(CASE WHEN "event_type" IN ('IssuesEvent','IssueCommentEvent')
                 THEN 1 ELSE 0 END)                                      AS "issues",
        COUNT(DISTINCT CASE WHEN "event_type" = 'WatchEvent'
                            THEN "actor_id" END)                         AS "watchers"
    FROM event_window
    GROUP BY "repo_name"
),
candidate_repos AS (
    SELECT
        a."repo_name",
        a."forks",
        a."issues",
        a."watchers",
        a."forks" + a."issues" + a."watchers"                            AS "activity_score"
    FROM aggregated a
    JOIN allowed_licenses l ON a."repo_name" = l."repo_name"
    JOIN python_repos      p ON a."repo_name" = p."repo_name"
)
SELECT
    "repo_name",
    "activity_score"
FROM candidate_repos
ORDER BY "activity_score" DESC NULLS LAST
LIMIT 1;