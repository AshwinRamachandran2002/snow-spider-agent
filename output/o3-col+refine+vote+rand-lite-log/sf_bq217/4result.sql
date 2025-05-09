WITH pr_events AS (
    /* Pull-request creations on 18-Jan-2023 (UTC) */
    SELECT
        "repo":"name"::STRING AS repo_name
    FROM "GITHUB_REPOS_DATE"."YEAR"."_2023"
    WHERE "type" = 'PullRequestEvent'
      AND "created_at" BETWEEN 1674000000000000 AND 1674086399999999   -- 2023-01-18
      AND TRY_PARSE_JSON("payload"):"action"::STRING = 'opened'        -- creation action
),
repos_with_js AS (
    /* Repositories that include JavaScript among their languages */
    SELECT DISTINCT
           l."repo_name" AS "repo_name"
    FROM "GITHUB_REPOS_DATE"."GITHUB_REPOS"."LANGUAGES" l,
         LATERAL FLATTEN(INPUT => l."language") f
    WHERE f.value:"name"::STRING = 'JavaScript'
)
SELECT COUNT(*) AS pull_request_creation_events
FROM pr_events e
JOIN repos_with_js j
  ON e.repo_name = j."repo_name";