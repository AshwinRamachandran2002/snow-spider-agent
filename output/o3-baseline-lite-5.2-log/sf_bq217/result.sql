SELECT
    COUNT(*) AS "pull_request_creation_events"
FROM GITHUB_REPOS_DATE.YEAR._2023 AS e
JOIN GITHUB_REPOS_DATE.GITHUB_REPOS.LANGUAGES AS l
      ON l."repo_name" = e."repo":"name"::string
WHERE e."type" = 'PullRequestEvent'                           -- only PR‑related events
  AND TO_DATE(TO_TIMESTAMP_LTZ(e."created_at" / 1000000)) = '2023-01-18'  -- events on 18‑Jan‑2023
  AND PARSE_JSON(e."payload"):action::string = 'opened'       -- creation (opened) events
  AND REGEXP_LIKE(l."language"::string, 'JavaScript', 'i');   -- repositories that list JavaScript