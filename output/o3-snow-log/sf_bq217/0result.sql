SELECT COUNT(*) AS "pull_request_count"
FROM (
        SELECT
               PARSE_JSON("repo"):"name"::STRING AS "repo_name"
        FROM   GITHUB_REPOS_DATE.YEAR."_2023"
        WHERE  "type" = 'PullRequestEvent'
          AND  PARSE_JSON("payload"):"action"::STRING = 'opened'
          AND  TO_DATE(TO_TIMESTAMP("created_at" / 1000000)) = '2023-01-18'
     ) AS evt
JOIN   GITHUB_REPOS_DATE.GITHUB_REPOS.LANGUAGES AS lang
       ON evt."repo_name" = lang."repo_name"
WHERE  LOWER(lang."language"::STRING) LIKE '%javascript%';