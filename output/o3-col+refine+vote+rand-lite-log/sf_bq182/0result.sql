/*  Primary languages with ≥ 100 Pull-Request events on 18-Jan-2023  */
WITH pr_per_repo AS (          -- 1) PR events per repository on 2023-01-18
    SELECT
        t."repo":"name"::STRING               AS "repo_name",
        COUNT(*)                              AS "pr_events"
    FROM   "GITHUB_REPOS_DATE"."YEAR"."_2023" t
    WHERE  t."type" = 'PullRequestEvent'
      AND  t."created_at" BETWEEN 1674000000000000      -- 2023-01-18 00:00 UTC
                             AND 1674086400000000      -- 2023-01-19 00:00 UTC
    GROUP BY 1
),
primary_lang AS (              -- 2) repository → primary language (largest byte count)
    SELECT
        p.* 
    FROM (
        SELECT
            l."repo_name",
            f.value:"name"::STRING   AS "language",
            f.value:"bytes"::NUMBER  AS "bytes",
            ROW_NUMBER() OVER (PARTITION BY l."repo_name"
                               ORDER BY f.value:"bytes"::NUMBER DESC) AS rn
        FROM   "GITHUB_REPOS_DATE"."GITHUB_REPOS"."LANGUAGES" l,
               LATERAL FLATTEN(input => l."language") f
    ) p
    WHERE p.rn = 1                       -- keep only largest-byte language
),
pr_by_language AS (            -- 3) aggregate PR events per language
    SELECT
        COALESCE(pl."language", 'Unknown')  AS "primary_language",
        SUM(r."pr_events")                  AS "total_pr_events"
    FROM   pr_per_repo r
    LEFT JOIN primary_lang pl
           ON r."repo_name" = pl."repo_name"
    GROUP BY 1
    HAVING SUM(r."pr_events") >= 100       -- language threshold
)
SELECT
    "primary_language",
    "total_pr_events"
FROM   pr_by_language
ORDER BY "total_pr_events" DESC NULLS LAST;