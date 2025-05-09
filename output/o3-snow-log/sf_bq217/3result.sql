SELECT COUNT(*) AS "pr_opened_event_count"
FROM   GITHUB_REPOS_DATE.YEAR."_2023"                 AS ev
JOIN   GITHUB_REPOS_DATE.GITHUB_REPOS.LANGUAGES       AS lang
       ON  LOWER(lang."repo_name") = LOWER(ev."repo":name::string)
WHERE  ev."type" = 'PullRequestEvent'
  AND  TO_TIMESTAMP(ev."created_at", 6) >= '2023-01-18'::timestamp
  AND  TO_TIMESTAMP(ev."created_at", 6) <  '2023-01-19'::timestamp
  AND  LOWER(lang."language"::string) LIKE '%javascript%'
  AND  PARSE_JSON(ev."payload"):action::string = 'opened';