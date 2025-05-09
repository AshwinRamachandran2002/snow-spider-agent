SELECT COUNT(c."message") AS "Commit_Message_Count"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS c
JOIN GITHUB_REPOS.GITHUB_REPOS.LICENSES l
  ON c."repo_name" = l."repo_name"
JOIN GITHUB_REPOS.GITHUB_REPOS.LANGUAGES lang
  ON c."repo_name" = lang."repo_name"
CROSS JOIN LATERAL FLATTEN(input => lang."language") f
WHERE l."license" = 'apache-2.0'
  AND f.value:"name"::STRING = 'Shell'
  AND LENGTH(c."message") BETWEEN 6 AND 9999
  AND LOWER(c."message") NOT LIKE 'merge%'
  AND LOWER(c."message") NOT LIKE 'update%'
  AND LOWER(c."message") NOT LIKE 'test%';