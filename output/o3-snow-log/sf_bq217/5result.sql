WITH events_2023 AS (
    SELECT
        TO_DATE(TO_TIMESTAMP_LTZ("created_at" / 1000000))              AS "event_date",
        PARSE_JSON("payload")                                          AS "payload_json",
        "repo":"name"::STRING                                          AS "repo_full_name",
        "type"
    FROM GITHUB_REPOS_DATE.YEAR."_2023"
)
SELECT COUNT(*) AS "pull_request_creation_events"
FROM events_2023   e
JOIN GITHUB_REPOS_DATE.GITHUB_REPOS."LANGUAGES"  l
      ON l."repo_name" = e."repo_full_name"
WHERE e."type" = 'PullRequestEvent'
  AND e."event_date" = '2023-01-18'         -- only 18 Jan 2023
  AND LOWER(l."language"::STRING) LIKE '%javascript%'   -- repos that list JavaScript
  AND e."payload_json":"action"::STRING = 'opened';     -- PR creation events