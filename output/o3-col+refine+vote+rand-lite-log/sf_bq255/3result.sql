SELECT
    COUNT(*) AS "commit_message_count"
FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_COMMITS" AS c
JOIN (
    SELECT DISTINCT lic."repo_name"
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."LANGUAGES"  AS lang
    JOIN "GITHUB_REPOS"."GITHUB_REPOS"."LICENSES"   AS lic
          ON lang."repo_name" = lic."repo_name"
    WHERE lang."language"::STRING ILIKE '%Shell%'     -- repositories that use Shell
      AND LOWER(lic."license") = 'apache-2.0'        -- with Apache-2.0 license
) AS r USING ("repo_name")
WHERE LENGTH(c."message") BETWEEN 6 AND 9999          -- message length >5 and <10000
  AND NOT REGEXP_LIKE(LOWER(c."message"), '^(merge|update|test)');  -- exclude prefixes