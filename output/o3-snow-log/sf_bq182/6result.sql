WITH pr_events AS (   -- Pull-request events on 18 Jan 2023
    SELECT  t."repo":"name"::STRING  AS repo_name,
            COUNT(*)                AS pr_cnt
    FROM    "GITHUB_REPOS_DATE"."YEAR"."_2023" t
    WHERE   t."type" = 'PullRequestEvent'
      AND   t."created_at" >= 1674000000000000   -- 2023-01-18 00:00 UTC
      AND   t."created_at" <  1674086400000000   -- 2023-01-19 00:00 UTC
    GROUP BY repo_name
),
primary_lang AS (     -- repository’s primary language (or 'Unknown')
    SELECT  l."repo_name",
            COALESCE(f.value:"name"::STRING, 'Unknown') AS language
    FROM    "GITHUB_REPOS_DATE"."GITHUB_REPOS"."LANGUAGES" l,
            LATERAL FLATTEN(OUTER => TRUE, input => l."language") f
    QUALIFY ROW_NUMBER() OVER (PARTITION BY l."repo_name"
                               ORDER BY f.value:"bytes"::NUMBER DESC NULLS LAST) = 1
)
SELECT  COALESCE(p.language, 'Unknown')              AS language,
        SUM(e.pr_cnt)                               AS total_pull_request_events
FROM    pr_events             e
LEFT JOIN primary_lang        p  ON e.repo_name = p."repo_name"
GROUP BY COALESCE(p.language, 'Unknown')
HAVING  SUM(e.pr_cnt) >= 100
ORDER BY total_pull_request_events DESC NULLS LAST;