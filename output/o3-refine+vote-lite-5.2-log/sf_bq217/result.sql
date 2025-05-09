WITH events AS (
    SELECT
        /* repository full name, e.g. "owner/repo" */
        "repo":"name"::string                                           AS repo_name,

        /* convert epoch (sec or msec) to DATE */
        TO_DATE(
            TO_TIMESTAMP_NTZ(
                CASE
                    WHEN "created_at" > 9999999999      /* milliseconds */
                        THEN "created_at" / 1000
                    ELSE "created_at"                   /* seconds */
                END
            )
        )                                                               AS event_date,

        /* payload as JSON */
        TRY_PARSE_JSON("payload")                                       AS payload_json
    FROM GITHUB_REPOS_DATE.YEAR."_2023"
    WHERE "type" = 'PullRequestEvent'
),

/* pull‑request events whose action is "opened" on 18‑Jan‑2023 */
pr_opened AS (
    SELECT repo_name
    FROM events
    WHERE event_date = '2023-01-18'
      AND payload_json:"action"::string = 'opened'
),

/* repositories that include JavaScript among their languages */
js_repos AS (
    SELECT "repo_name" AS repo_name
    FROM   GITHUB_REPOS_DATE.GITHUB_REPOS.LANGUAGES
    WHERE  "language":"JavaScript" IS NOT NULL
)

/* final result */
SELECT COUNT(*) AS pull_request_creation_count
FROM   pr_opened po
JOIN   js_repos  jr
       ON po.repo_name = jr.repo_name;