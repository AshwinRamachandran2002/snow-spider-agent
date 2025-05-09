WITH pr_events AS (
    /* pull‑request creation events on 18‑Jan‑2023 */
    SELECT
        ("repo":"name")::STRING AS repo_name
    FROM
        "GITHUB_REPOS_DATE"."YEAR"."_2023"
    WHERE
        "type" = 'PullRequestEvent'
        AND PARSE_JSON("payload"):"action"::STRING = 'opened'          -- creation
        AND TO_DATE(TO_TIMESTAMP_NTZ("created_at")) = '2023-01-18'     -- event date
), js_repos AS (
    /* repositories that include JavaScript among their languages */
    SELECT DISTINCT
        "repo_name" AS repo_name
    FROM
        "GITHUB_REPOS_DATE"."GITHUB_REPOS"."LANGUAGES",
        LATERAL FLATTEN(input => "language") AS lang
    WHERE
        (lang.key::STRING = 'JavaScript')      -- object form { "JavaScript": size }
        OR (lang.value::STRING = 'JavaScript') -- array / value form [ "JavaScript", ... ]
)
SELECT
    COUNT(*) AS pull_request_creation_events
FROM
    pr_events
    JOIN js_repos USING (repo_name);