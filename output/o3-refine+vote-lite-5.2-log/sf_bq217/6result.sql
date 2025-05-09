WITH pr_events AS (
    SELECT
        PARSE_JSON("payload")                AS payload_json ,
        "repo":"name"::string               AS repo_name
    FROM   GITHUB_REPOS_DATE.YEAR._2023
    WHERE  "type" = 'PullRequestEvent'
      AND  DATE_TRUNC('day' ,
             TO_TIMESTAMP_NTZ("created_at" / 1000000)   -- convert µs epoch to timestamp
           ) = '2023-01-18'
)
SELECT COUNT(*) AS pull_request_creations
FROM   pr_events            e
JOIN   GITHUB_REPOS_DATE.GITHUB_REPOS.LANGUAGES  l
       ON l."repo_name" = e.repo_name
WHERE  LOWER(l."language"::string) LIKE '%javascript%'
  AND  e.payload_json:"action"::string = 'opened';