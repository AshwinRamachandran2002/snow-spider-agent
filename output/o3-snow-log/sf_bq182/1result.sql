WITH pull_events AS (  -- Pull-request events that occurred on 2023-01-18
    SELECT
        "repo":"name"::STRING AS "repo_name"
    FROM GITHUB_REPOS_DATE.YEAR."_2023"
    WHERE "type" = 'PullRequestEvent'
      AND TO_DATE(TO_TIMESTAMP_LTZ("created_at" / 1000000)) = '2023-01-18'
),
lang_expanded AS (     -- expand the JSON array of languages
    SELECT
        "repo_name",
        f.value:"name"::STRING  AS "language",
        f.value:"bytes"::NUMBER AS "bytes"
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.LANGUAGES,
         LATERAL FLATTEN(input => "language") f
),
primary_lang AS (      -- keep the language with the most bytes per repo
    SELECT "repo_name", "language"
    FROM (
        SELECT
            "repo_name",
            "language",
            ROW_NUMBER() OVER (PARTITION BY "repo_name"
                               ORDER BY "bytes" DESC NULLS LAST) AS rn
        FROM lang_expanded
    )
    WHERE rn = 1
)
SELECT
    COALESCE(pl."language", 'UNKNOWN') AS "primary_language",
    COUNT(*)                          AS "pull_request_event_count"
FROM   pull_events      pe
LEFT   JOIN primary_lang pl
       ON pe."repo_name" = pl."repo_name"
GROUP  BY COALESCE(pl."language", 'UNKNOWN')
HAVING COUNT(*) >= 100
ORDER  BY "primary_language";