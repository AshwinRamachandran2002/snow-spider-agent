WITH python_repos AS (
    SELECT DISTINCT
           f."repo_name"
    FROM   "GITHUB_REPOS_DATE"."GITHUB_REPOS"."SAMPLE_FILES"    f
    JOIN   "GITHUB_REPOS_DATE"."GITHUB_REPOS"."SAMPLE_CONTENTS" c
           ON f."id" = c."id"
    WHERE  f."path" ILIKE '%.py'
      AND  c."size" < 15000
      AND  c."content" ILIKE '%def %'
),
watch_counts AS (
    SELECT
           t."repo":"name"::STRING AS "repo_name",
           COUNT(*)                AS "watch_event_count"
    FROM   "GITHUB_REPOS_DATE"."YEAR"."_2017" t
    WHERE  t."type" = 'WatchEvent'
    GROUP  BY t."repo":"name"::STRING
)
SELECT
       w."repo_name"       AS repository,
       w."watch_event_count"
FROM   watch_counts w
JOIN   python_repos p
       ON w."repo_name" = p."repo_name"
ORDER  BY w."watch_event_count" DESC NULLS LAST,
          w."repo_name"          ASC
LIMIT 3;