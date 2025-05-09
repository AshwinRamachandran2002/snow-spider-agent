SELECT
    PARSE_JSON(e."payload"):"pull_request":"base":"repo":"language"::STRING AS "Primary_Programming_Language",
    COUNT(*) AS "PullRequestEvents"
FROM "GITHUB_REPOS_DATE"."DAY"."_20230118" e
WHERE e."type" = 'PullRequestEvent'
GROUP BY "Primary_Programming_Language"
HAVING COUNT(*) >= 100
ORDER BY "PullRequestEvents" DESC NULLS LAST;