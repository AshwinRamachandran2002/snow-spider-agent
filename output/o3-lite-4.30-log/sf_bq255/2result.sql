SELECT COUNT(*) AS "commit_message_count"
FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_COMMITS"      sc
JOIN "GITHUB_REPOS"."GITHUB_REPOS"."LANGUAGES"           l
      ON sc."repo_name" = l."repo_name"
JOIN "GITHUB_REPOS"."GITHUB_REPOS"."LICENSES"            lic
      ON sc."repo_name" = lic."repo_name"
WHERE LOWER(CAST(l."language" AS STRING)) LIKE '%shell%'
  AND LOWER(lic."license") LIKE '%apache-2.0%'
  AND LENGTH(sc."message") > 5
  AND LENGTH(sc."message") < 10000
  AND NOT (
        LOWER(sc."message") LIKE 'merge%'  OR
        LOWER(sc."message") LIKE 'update%' OR
        LOWER(sc."message") LIKE 'test%'
      );