/* Languages whose repositories accumulated ≥ 100 Pull-Request events
   on 18-Jan-2023 (UTC). */
WITH pull_request_events AS (          -- all PR events that day
    SELECT
        "repo":"name"::STRING AS repo_name
    FROM   "GITHUB_REPOS_DATE"."YEAR"."_2023"
    WHERE  "type" = 'PullRequestEvent'
      AND  "created_at" >= 1674000000000000   -- 2023-01-18 00:00:00 UTC
      AND  "created_at" <  1674086400000000   -- 2023-01-19 00:00:00 UTC
),
repo_primary_language AS (             -- primary language per repository
    SELECT
        lang."repo_name"          AS repo_name,          -- unquoted alias
        f.value:"name"::STRING    AS language,
        ROW_NUMBER() OVER (PARTITION BY lang."repo_name"
                           ORDER BY f.value:"bytes"::INTEGER DESC) AS rn
    FROM   "GITHUB_REPOS_DATE"."GITHUB_REPOS"."LANGUAGES" AS lang,
           LATERAL FLATTEN(input => lang."language")      AS f
    QUALIFY rn = 1                                        -- keep the top one
)
SELECT
    COALESCE(rpl.language, 'Unknown')   AS language,
    COUNT(*)                            AS total_pr_events
FROM   pull_request_events        AS ev
LEFT  JOIN repo_primary_language  AS rpl
       ON ev.repo_name = rpl.repo_name
GROUP  BY COALESCE(rpl.language, 'Unknown')
HAVING COUNT(*) >= 100
ORDER  BY total_pr_events DESC NULLS LAST;