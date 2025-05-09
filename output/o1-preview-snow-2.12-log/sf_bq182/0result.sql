SELECT
   pl."language" AS "primary_language",
   SUM(pr."pull_request_count") AS "total_pull_requests"
FROM (
   SELECT
     "repo_name",
     "language"
   FROM (
     SELECT
       "repo_name",
       f.value:"name"::STRING AS "language",
       f.value:"bytes"::NUMBER AS "bytes",
       ROW_NUMBER() OVER (
          PARTITION BY "repo_name"
          ORDER BY f.value:"bytes"::NUMBER DESC NULLS LAST
       ) AS rn
     FROM "GITHUB_REPOS_DATE"."GITHUB_REPOS"."LANGUAGES"
     , LATERAL FLATTEN(input => "language") f
   ) sub
   WHERE rn = 1
) pl
JOIN (
   SELECT
     "repo"::VARIANT:"name"::STRING AS "repo_name",
     COUNT(*) AS "pull_request_count"
   FROM "GITHUB_REPOS_DATE"."YEAR"."_2023"
   WHERE "type" = 'PullRequestEvent'
     AND TRY_TO_NUMBER("created_at") IS NOT NULL
     AND DATE(TO_TIMESTAMP(TRY_TO_NUMBER("created_at") / 1e6)) = '2023-01-18'
   GROUP BY "repo_name"
) pr ON pr."repo_name" = pl."repo_name"
GROUP BY pl."language"
HAVING SUM(pr."pull_request_count") > 5;