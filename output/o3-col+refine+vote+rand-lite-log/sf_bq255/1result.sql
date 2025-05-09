SELECT COUNT(*) AS "num_valid_commit_messages"
FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_COMMITS"  AS c
JOIN (
        /* repositories that use Shell */
        SELECT DISTINCT l."repo_name"
        FROM "GITHUB_REPOS"."GITHUB_REPOS"."LANGUAGES" l,
             LATERAL FLATTEN(input => l."language") f
        WHERE f.value:"name"::STRING = 'Shell'
     )                                                 AS shell_repos
  ON c."repo_name" = shell_repos."repo_name"
JOIN "GITHUB_REPOS"."GITHUB_REPOS"."LICENSES"         AS lic
  ON c."repo_name" = lic."repo_name"
WHERE lic."license" = 'apache-2.0'
  AND LENGTH(c."message") > 5
  AND LENGTH(c."message") < 10000
  AND NOT (
        c."message" ILIKE 'merge%' 
     OR c."message" ILIKE 'update%' 
     OR c."message" ILIKE 'test%'
  );