SELECT
    COUNT(*)                                                        AS "total_readme_files",
    COUNT_IF(LOWER("content") LIKE '%copyright (c)%')               AS "readme_with_copyright",
    ROUND(
        COUNT_IF(LOWER("content") LIKE '%copyright (c)%')
        / NULLIF(COUNT(*), 0)::FLOAT , 4)                           AS "proportion"
FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
WHERE  LOWER("sample_path") LIKE '%readme.md%'
  AND  "sample_repo_name" IN (
        SELECT DISTINCT "repo_name"
        FROM   GITHUB_REPOS.GITHUB_REPOS.LANGUAGES
        WHERE  "language"::STRING NOT ILIKE '%python%'
      );