SELECT COUNT(*) AS "total_qualified_commit_messages"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS AS c
JOIN (
        SELECT l."repo_name"
        FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES AS l
        JOIN GITHUB_REPOS.GITHUB_REPOS.LICENSES AS lic
          ON l."repo_name" = lic."repo_name"
        WHERE l."language" ILIKE '%Shell%'
          AND lic."license" = 'apache-2.0'
     ) AS r
  ON c."repo_name" = r."repo_name"
WHERE LENGTH(c."message") > 5
  AND LENGTH(c."message") < 10000
  AND LOWER(c."message") NOT LIKE 'merge%'
  AND LOWER(c."message") NOT LIKE 'update%'
  AND LOWER(c."message") NOT LIKE 'test%';