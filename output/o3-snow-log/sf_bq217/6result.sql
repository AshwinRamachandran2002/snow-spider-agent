WITH "JS_REPOS" AS (          -- repositories that list JavaScript as a language
    SELECT DISTINCT "repo_name"
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.LANGUAGES
         ,LATERAL FLATTEN(input => "language") f
    WHERE f.key::string  = 'JavaScript'          -- object-style {"JavaScript":123}
       OR f.value::string = 'JavaScript'         -- array-style ["JavaScript", ...]
),
"EVENTS_2023" AS (            -- pull-request events on 18-Jan-2023
    SELECT
        TO_TIMESTAMP("created_at"/1000000)          AS "event_time",
        "repo":"name"::string                       AS "repo_name",
        PARSE_JSON("payload")                       AS "payload_json"
    FROM GITHUB_REPOS_DATE.YEAR."_2023"
    WHERE "type" = 'PullRequestEvent'
)
SELECT COUNT(*) AS "pull_request_creation_count"
FROM "EVENTS_2023"  e
JOIN "JS_REPOS"     r
  ON e."repo_name" = r."repo_name"
WHERE CAST(e."event_time" AS DATE) = TO_DATE('2023-01-18')
  AND e."payload_json":"action"::string = 'opened';