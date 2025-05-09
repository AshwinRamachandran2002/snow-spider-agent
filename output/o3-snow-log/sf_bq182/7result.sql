WITH pr_events AS (
    -- All pull-request events that occurred on 18-Jan-2023
    SELECT
        LOWER("repo":"name"::STRING) AS repo_name
    FROM "GITHUB_REPOS_DATE"."YEAR"."_2023"
    WHERE "type" = 'PullRequestEvent'
      AND TO_DATE(TO_TIMESTAMP_LTZ("created_at" / 1000000)) = '2023-01-18'
),
primary_lang AS (
    -- Primary language = the one with the largest byte count for each repo
    SELECT
        LOWER(l."repo_name")      AS repo_name,
        f.value:"name"::STRING    AS language
    FROM "GITHUB_REPOS_DATE"."GITHUB_REPOS"."LANGUAGES" AS l,
         LATERAL FLATTEN(input => l."language")          AS f
    QUALIFY ROW_NUMBER() OVER (
               PARTITION BY l."repo_name"
               ORDER BY f.value:"bytes"::NUMBER DESC
           ) = 1
)
SELECT
    COALESCE(pl.language, 'Unknown')        AS language,
    COUNT(*)                                AS pullrequest_events
FROM pr_events            AS pe
LEFT JOIN primary_lang    AS pl
  ON pe.repo_name = pl.repo_name
GROUP BY COALESCE(pl.language, 'Unknown')
HAVING COUNT(*) >= 100
ORDER BY pullrequest_events DESC NULLS LAST;