SELECT
    COUNT(*) AS "commit_message_count"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS          AS c
JOIN (
        /* repositories that list Shell as one of their languages */
        SELECT DISTINCT l."repo_name"
        FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES l,
             LATERAL FLATTEN(input => l."language") f
        WHERE LOWER(f.value:"name"::STRING) = 'shell'
     )                                                AS sh
  ON c."repo_name" = sh."repo_name"
JOIN GITHUB_REPOS.GITHUB_REPOS.LICENSES               AS lic
  ON c."repo_name" = lic."repo_name"
WHERE LOWER(lic."license") = 'apache-2.0'
  AND LENGTH(c."message") > 5
  AND LENGTH(c."message") < 10000
  AND NOT (
        LOWER(c."subject") LIKE 'merge %'
     OR LOWER(c."subject") LIKE 'update %'
     OR LOWER(c."subject") LIKE 'test %'
  );