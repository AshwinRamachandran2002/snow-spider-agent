SELECT COUNT(*) AS "PULL_REQUEST_CREATION_EVENTS"
FROM (
        /* pull-request events that occurred on 2023-01-18 */
        SELECT
               PARSE_JSON("payload")               AS "pl",
               "repo":"name"::STRING               AS "repo_name"
        FROM   GITHUB_REPOS_DATE.YEAR."_2023"
        WHERE  "type" = 'PullRequestEvent'
          AND  TO_DATE(TO_TIMESTAMP("created_at" / 1000000)) = '2023-01-18'
     ) e
JOIN   GITHUB_REPOS_DATE.GITHUB_REPOS.LANGUAGES  l
       ON l."repo_name" = e."repo_name"
WHERE  e."pl":"action"::STRING = 'opened'          -- PR creation
  AND   l."language":"JavaScript" IS NOT NULL;     -- repository uses JavaScript