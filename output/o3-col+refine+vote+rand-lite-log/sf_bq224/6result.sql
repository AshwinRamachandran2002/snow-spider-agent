WITH april_2022_activity AS (
    SELECT
        "repo":name::STRING                                      AS "repo_name",
        SUM(CASE WHEN "type" = 'ForkEvent'   THEN 1 ELSE 0 END)  AS "forks",
        SUM(CASE WHEN "type" = 'IssuesEvent' THEN 1 ELSE 0 END)  AS "issues",
        SUM(CASE WHEN "type" = 'WatchEvent'  THEN 1 ELSE 0 END)  AS "watches"
    FROM "GITHUB_REPOS_DATE"."YEAR"."_2022"
    WHERE "created_at" >= 1648771200000000   -- 2022-04-01 00:00:00 UTC
      AND "created_at" <  1651363200000000   -- 2022-05-01 00:00:00 UTC
    GROUP BY "repo":name::STRING
),
approved_license_repos AS (
    SELECT DISTINCT l."repo_name"
    FROM "GITHUB_REPOS_DATE"."GITHUB_REPOS"."LICENSES"      l
    JOIN "GITHUB_REPOS_DATE"."GITHUB_REPOS"."SAMPLE_FILES"  f
          ON l."repo_name" = f."repo_name"
    WHERE LOWER(f."path") LIKE '%license%'
)
SELECT
    a."repo_name",
    a."forks",
    a."issues",
    a."watches",
    (a."forks" + a."issues" + a."watches") AS "total_activity"
FROM april_2022_activity  a
JOIN approved_license_repos b
  ON a."repo_name" = b."repo_name"
ORDER BY "total_activity" DESC NULLS LAST
LIMIT 1;