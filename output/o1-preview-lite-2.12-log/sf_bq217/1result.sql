SELECT COUNT(*) AS "Number_of_Pull_Requests"
FROM (
  SELECT DISTINCT t."id"
  FROM "GITHUB_REPOS_DATE"."DAY"."_20230118" t
  JOIN (
    SELECT l."repo_name"
    FROM "GITHUB_REPOS_DATE"."GITHUB_REPOS"."LANGUAGES" l,
         LATERAL FLATTEN(INPUT => l."language") k
    WHERE k.VALUE:"name"::STRING = 'JavaScript'
    GROUP BY l."repo_name"
  ) l
    ON PARSE_JSON(t."repo"):"name"::STRING = l."repo_name"
  WHERE t."type" = 'PullRequestEvent'
    AND PARSE_JSON(t."payload"):"action"::STRING = 'opened'
) sub;