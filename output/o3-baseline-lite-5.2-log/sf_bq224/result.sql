WITH april_events AS (
    SELECT
        "repo":"name"::STRING                                   AS "REPO_NAME",
        "type"                                                  AS "EVENT_TYPE"
    FROM "GITHUB_REPOS_DATE"."YEAR"."_2022"
    WHERE "type" IN ('ForkEvent','IssuesEvent','WatchEvent')
          -- convert micro‑seconds since epoch to date, keep only April 2022 rows
          AND TO_DATE(TO_TIMESTAMP_NTZ("created_at"/1000000)) BETWEEN '2022-04-01' AND '2022-04-30'
), combined_counts AS (
    SELECT
        "REPO_NAME",
        COUNT(*)                                                AS "TOTAL_FORKS_ISSUES_WATCHES"
    FROM april_events
    GROUP BY "REPO_NAME"
), repos_with_approved_license AS (
    SELECT DISTINCT
        "repo_name"                                             AS "REPO_NAME"
    FROM "GITHUB_REPOS_DATE"."GITHUB_REPOS"."LICENSES"
    WHERE "license" IS NOT NULL   -- assume non‑null licenses are approved
)
SELECT
    c."REPO_NAME"
FROM combined_counts c
JOIN repos_with_approved_license l
  ON c."REPO_NAME" = l."REPO_NAME"
ORDER BY c."TOTAL_FORKS_ISSUES_WATCHES" DESC NULLS LAST
LIMIT 1;