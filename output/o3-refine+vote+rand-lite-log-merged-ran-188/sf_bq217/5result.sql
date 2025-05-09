WITH js_repos AS (
    /* Repositories whose language list contains the key "JavaScript" */
    SELECT "repo_name"
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.LANGUAGES
    WHERE EXISTS (
        SELECT 1
        FROM TABLE(FLATTEN(INPUT => "language")) f
        WHERE f.KEY ILIKE 'JavaScript'
    )
)
SELECT COUNT(*) AS "pull_request_creations"
FROM GITHUB_REPOS_DATE.YEAR."_2023" AS e
JOIN js_repos r
  ON e."repo":"name"::string = r."repo_name"
WHERE e."type" = 'PullRequestEvent'                               -- pull‑request events
  AND DATE_TRUNC('DAY', TO_TIMESTAMP_LTZ(e."created_at" / 1000)) = '2023-01-18'  -- events on 18‑Jan‑2023
  AND TRY_PARSE_JSON(e."payload"):"action"::string = 'opened';    -- creation (opened) action