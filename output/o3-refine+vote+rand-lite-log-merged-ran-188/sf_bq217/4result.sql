WITH pr_events_2023 AS (
    /* pull‑request OPEN events on 2023‑01‑18 (UTC)                      */
    SELECT
        /* repository full name, e.g. "owner/repo"                      */
        e."repo":"name"::STRING AS "repo_name"
    FROM GITHUB_REPOS_DATE.YEAR."_2023" AS e
    WHERE  e."type" = 'PullRequestEvent'
       AND PARSE_JSON(e."payload"):"action"::STRING = 'opened'
       /* convert micro‑second epoch to DATE in UTC                     */
       AND TO_DATE( TO_TIMESTAMP_LTZ( e."created_at" / 1000000 ) ) = '2023-01-18'
), js_repos AS (
    /* repositories whose language list mentions JavaScript             */
    SELECT DISTINCT "repo_name"
    FROM   GITHUB_REPOS_DATE.GITHUB_REPOS.LANGUAGES
    WHERE  LOWER( CAST("language" AS STRING) ) LIKE '%javascript%'
)
SELECT COUNT(*) AS "pull_request_creations_js_repos_2023_01_18"
FROM   pr_events_2023     AS pe
JOIN   js_repos           AS jr
       ON pe."repo_name" = jr."repo_name";