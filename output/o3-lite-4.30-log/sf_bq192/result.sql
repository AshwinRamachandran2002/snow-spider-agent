WITH allowed_repos_license AS (
    SELECT DISTINCT "repo_name"
    FROM "GITHUB_REPOS_DATE"."GITHUB_REPOS"."LICENSES"
    WHERE LOWER("license") IN ('artistic-2.0','isc','mit','apache-2.0')
),
py_master_repos AS (
    SELECT DISTINCT "repo_name"
    FROM "GITHUB_REPOS_DATE"."GITHUB_REPOS"."SAMPLE_FILES"
    WHERE "ref" = 'refs/heads/master'
      AND LOWER("path") LIKE '%.py'
),
april22_events AS (
    SELECT
        t."repo":"name"::STRING  AS "repo_name",
        t."type"                 AS "event_type",
        t."actor":"id"::STRING   AS "actor_id"
    FROM "GITHUB_REPOS_DATE"."YEAR"."_2022" t
    WHERE t."created_at" BETWEEN 1648771200000000 AND 1651363199000000   -- 1‑30 Apr 2022 (µs)
),
aggregated AS (
    SELECT
        "repo_name",
        SUM(CASE WHEN "event_type" = 'ForkEvent' THEN 1 ELSE 0 END)                                                AS forks,
        SUM(CASE WHEN "event_type" IN ('IssuesEvent','IssueCommentEvent') THEN 1 ELSE 0 END)                       AS issues,
        COUNT(DISTINCT CASE WHEN "event_type" = 'WatchEvent' THEN "actor_id" END)                                   AS watches
    FROM april22_events
    GROUP BY "repo_name"
)
SELECT
    a."repo_name"                           AS repository,
    (a.forks + a.issues + a.watches)        AS combined_activity_score
FROM          aggregated            a
JOIN          allowed_repos_license l  ON a."repo_name" = l."repo_name"
JOIN          py_master_repos       p  ON a."repo_name" = p."repo_name"
ORDER BY combined_activity_score DESC, repository
LIMIT 1;