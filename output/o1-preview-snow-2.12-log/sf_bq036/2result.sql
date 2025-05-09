SELECT 
    ROUND(COUNT(*) / 12.0, 4) AS "Average_Commits_per_Month"
FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_COMMITS" c
JOIN (
    SELECT 
        "repo_name", 
        value
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."LANGUAGES",
         LATERAL FLATTEN(input => "language")
) l
ON c."repo_name" = l."repo_name"
WHERE l.value:"name"::STRING = 'Python'
  AND EXTRACT(YEAR FROM TO_TIMESTAMP_NTZ(c."author"::VARIANT:"date"::NUMBER / 1000000)) = 2016