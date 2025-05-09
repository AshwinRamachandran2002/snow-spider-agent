/* Pull-request activity per primary language on 18-Jan-2023 (UTC).
   Each repository is assigned the language with the most bytes in
   GITHUB_REPOS_DATE.GITHUB_REPOS.LANGUAGES (or “Unknown” if none). */

WITH lang_nonempty AS (               -- repos that list at least one language
    SELECT
        l."repo_name"                               AS "repo_name",
        f.value:"name"::STRING                      AS "language_name",
        ROW_NUMBER() OVER (                         -- pick largest-byte entry
            PARTITION BY l."repo_name"
            ORDER BY f.value:"bytes"::INTEGER DESC
        )                                           AS "rn"
    FROM "GITHUB_REPOS_DATE"."GITHUB_REPOS"."LANGUAGES" l,
         LATERAL FLATTEN(input => l."language") f
),
lang_empty AS (                        -- repos whose language array is empty
    SELECT
        l."repo_name"                               AS "repo_name",
        'Unknown'                                   AS "language_name",
        1                                           AS "rn"
    FROM "GITHUB_REPOS_DATE"."GITHUB_REPOS"."LANGUAGES" l
    WHERE ARRAY_SIZE(l."language") = 0
),
primary_lang AS (                      -- one row per repo with its “primary” language
    SELECT "repo_name", "language_name"
    FROM (
        SELECT * FROM lang_nonempty
        UNION ALL
        SELECT * FROM lang_empty
    )
    WHERE "rn" = 1
),
pr_events AS (                         -- PullRequestEvents on 18-Jan-2023
    SELECT
        e."repo":"name"::STRING AS "repo_full_name"
    FROM "GITHUB_REPOS_DATE"."YEAR"."_2023" e
    WHERE e."type" = 'PullRequestEvent'
      AND e."created_at" BETWEEN 1674000000000000   -- 2023-01-18 00:00:00 UTC
                             AND 1674086399999999   -- 2023-01-18 23:59:59 UTC
)
SELECT
    COALESCE(pl."language_name", 'Unknown') AS "primary_language",
    COUNT(*)                                AS "pull_request_events"
FROM pr_events  pe
LEFT JOIN primary_lang pl
       ON pl."repo_name" = pe."repo_full_name"
GROUP BY
    COALESCE(pl."language_name", 'Unknown')
ORDER BY
    "pull_request_events" DESC NULLS LAST;