WITH lang_rank AS (
    SELECT 
        l."repo_name",
        f.value:"name"::string   AS language_name,
        f.value:"bytes"::integer AS language_bytes,
        ROW_NUMBER() OVER (
            PARTITION BY l."repo_name"
            ORDER BY f.value:"bytes"::integer DESC
        ) AS rn
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."LANGUAGES" l,
         LATERAL FLATTEN(input => l."language") f
),
js_primary AS (
    SELECT "repo_name"
    FROM lang_rank
    WHERE rn = 1
      AND LOWER(language_name) = 'javascript'
)
SELECT j."repo_name"              AS "repository_name",
       COUNT(DISTINCT c."commit") AS "commit_count"
FROM js_primary j
JOIN "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_COMMITS" c
  ON j."repo_name" = c."repo_name"
GROUP BY j."repo_name"
ORDER BY "commit_count" DESC NULLS LAST, "repository_name"
LIMIT 2;