WITH april_events AS (
    SELECT
        /* repository full name (owner/repo) extracted from event JSON */
        COALESCE(
            "repo":"full_name"::string,
            TRY_PARSE_JSON("payload"):"repository":"full_name"::string,
            "repo":"name"::string
        )                                      AS repo_full_name,
        COUNT(*)                               AS ev_cnt
    FROM "GITHUB_REPOS_DATE"."YEAR"."_2022"
    WHERE
        TO_TIMESTAMP_LTZ("created_at" / 1000000) >= '2022-04-01'
        AND TO_TIMESTAMP_LTZ("created_at" / 1000000) <  '2022-05-01'
        AND "type" IN ('ForkEvent','IssuesEvent','WatchEvent')
    GROUP BY repo_full_name
),
licensed_repos AS (
    SELECT "repo_name"
    FROM   "GITHUB_REPOS_DATE"."GITHUB_REPOS"."LICENSES"
    WHERE  "license" IS NOT NULL
)
SELECT  a.repo_full_name
FROM    april_events   AS a
JOIN    licensed_repos AS l
        ON a.repo_full_name = l."repo_name"
ORDER BY a.ev_cnt DESC NULLS LAST, a.repo_full_name
LIMIT 1;