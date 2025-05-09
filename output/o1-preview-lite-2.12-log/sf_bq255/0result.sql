SELECT COUNT(*) AS Commit_Message_Count
FROM GITHUB_REPOS.GITHUB_REPOS."SAMPLE_COMMITS" c
WHERE c."repo_name" IN (
    SELECT DISTINCT l."repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS."LICENSES" l
    JOIN GITHUB_REPOS.GITHUB_REPOS."LANGUAGES" lang
      ON l."repo_name" = lang."repo_name",
      LATERAL FLATTEN(input => lang."language") f
    WHERE l."license" = 'apache-2.0'
      AND f.value:"name"::STRING = 'Shell'
)
AND LENGTH(c."message") > 5
AND LENGTH(c."message") < 10000
AND LOWER(c."message") NOT LIKE 'merge%'
AND LOWER(c."message") NOT LIKE 'update%'
AND LOWER(c."message") NOT LIKE 'test%';