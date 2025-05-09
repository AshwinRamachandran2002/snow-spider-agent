SELECT COUNT(*) AS "commit_message_count"
FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_COMMITS"     c
JOIN "GITHUB_REPOS"."GITHUB_REPOS"."LANGUAGES"          l ON c."repo_name" = l."repo_name"
JOIN "GITHUB_REPOS"."GITHUB_REPOS"."LICENSES"           s ON c."repo_name" = s."repo_name"
WHERE l."language" ILIKE '%Shell%'
  AND s."license"  ILIKE 'apache-2.0'
  AND LENGTH(c."message") > 5
  AND LENGTH(c."message") < 10000
  AND c."message" NOT ILIKE 'merge%'
  AND c."message" NOT ILIKE 'update%'
  AND c."message" NOT ILIKE 'test%';