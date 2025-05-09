/* pull‑request creation events (action = 'opened') on 18‑Jan‑2023
   for repositories that list JavaScript among their languages         */
SELECT COUNT(*) AS "pull_request_creation_events"
FROM (
        /* all PullRequestEvent rows created on 2023‑01‑18 UTC, action = opened */
        SELECT
               TRY_PARSE_JSON("payload"):action::string  AS action,
               "repo":"name"::string                     AS repo_name
        FROM   GITHUB_REPOS_DATE.YEAR."_2023"
        WHERE  "type" = 'PullRequestEvent'
          AND  TO_DATE( TO_TIMESTAMP_LTZ( "created_at" / 1000000 ) ) = '2023-01-18'
          AND  TRY_PARSE_JSON("payload"):action::string = 'opened'
     ) pr
JOIN   GITHUB_REPOS_DATE.GITHUB_REPOS.LANGUAGES lg
       ON lg."repo_name" = pr.repo_name
/* repository must include JavaScript among its recorded languages */
WHERE  lg."language"::string ILIKE '%JavaScript%';