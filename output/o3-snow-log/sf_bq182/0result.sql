WITH jan18_prs AS (           -- all PullRequestEvents on 18-Jan-2023 (UTC)
    SELECT
        t."repo":"name"::STRING AS "repo_name"
    FROM GITHUB_REPOS_DATE.YEAR."_2023" AS t
    WHERE t."type" = 'PullRequestEvent'
      AND t."created_at" BETWEEN 1674009600000000     -- 2023-01-18 00:00:00 UTC
                           AND 1674096000000000       -- 2023-01-19 00:00:00 UTC
),
primary_lang AS (             -- primary language of each repo (largest-byte entry)
    SELECT
        l."repo_name",
        f.value:"name"::STRING AS "primary_language"
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS."LANGUAGES" AS l,
         LATERAL FLATTEN(input => l."language") AS f
    QUALIFY ROW_NUMBER() OVER (
               PARTITION BY l."repo_name"
               ORDER BY f.value:"bytes"::NUMBER DESC
           ) = 1
)
SELECT
    COALESCE(pl."primary_language", 'Unknown') AS "primary_language",
    COUNT(*)                                   AS "pull_request_events"
FROM   jan18_prs       AS p
LEFT   JOIN primary_lang AS pl
       ON p."repo_name" = pl."repo_name"
GROUP  BY 1
HAVING COUNT(*) >= 100
ORDER  BY "pull_request_events" DESC NULLS LAST;