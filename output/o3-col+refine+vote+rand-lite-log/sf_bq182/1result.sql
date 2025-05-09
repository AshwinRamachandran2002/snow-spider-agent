WITH pr_events AS (   -- Pull-request events on 18-Jan-2023
    SELECT PARSE_JSON("repo"):name::STRING AS "repo_name"
    FROM   GITHUB_REPOS_DATE.YEAR."_2023"
    WHERE  "type" = 'PullRequestEvent'
      AND  "created_at" >= 1674000000000000   -- 2023-01-18 00:00:00 UTC
      AND  "created_at" <  1674086400000000   -- 2023-01-19 00:00:00 UTC
),
primary_language AS (  -- Primary (largest-byte) language per repository
    SELECT  l."repo_name",
            f.value:name::STRING  AS "language"
    FROM    GITHUB_REPOS_DATE.GITHUB_REPOS.LANGUAGES l,
            LATERAL FLATTEN(input => PARSE_JSON(l."language")) f
    QUALIFY ROW_NUMBER() OVER (PARTITION BY l."repo_name"
                               ORDER BY f.value:bytes::NUMBER DESC) = 1
),
lang_counts AS (       -- PR counts per primary language
    SELECT  pl."language",
            COUNT(*) AS "pull_request_events"
    FROM    pr_events e
    JOIN    primary_language pl USING ("repo_name")
    GROUP BY pl."language"
)
-- Return languages with ≥100 PR events; if none, return an informative row
SELECT  "language",
        "pull_request_events"
FROM    lang_counts
WHERE   "pull_request_events" >= 100

UNION ALL

SELECT  'NO_LANGUAGE_HAS_100_OR_MORE' AS "language",
        0                             AS "pull_request_events"
WHERE   NOT EXISTS (SELECT 1
                    FROM   lang_counts
                    WHERE  "pull_request_events" >= 100)

ORDER BY "pull_request_events" DESC NULLS LAST, "language";