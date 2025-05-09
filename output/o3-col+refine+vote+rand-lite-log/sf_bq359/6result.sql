WITH flat AS (  -- explode the JSON array of languages for every repo
    SELECT
        l."repo_name",
        f.value:"name"::STRING  AS "language",
        f.value:"bytes"::NUMBER AS "bytes"
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."LANGUAGES" l,
         LATERAL FLATTEN(input => l."language") f
    WHERE l."language" IS NOT NULL
      AND l."language"::STRING <> '[]'
),
primary_lang AS (  -- keep the language with the most bytes per repository
    SELECT
        "repo_name",
        "language" AS "primary_language"
    FROM (
        SELECT
            flat.*,
            ROW_NUMBER() OVER (PARTITION BY "repo_name"
                               ORDER BY "bytes" DESC) AS rn
        FROM flat
    )
    WHERE rn = 1
),
js_repos AS (  -- repositories whose primary language is JavaScript
    SELECT "repo_name"
    FROM primary_lang
    WHERE LOWER("primary_language") = 'javascript'
),
commit_counts AS (  -- total commits per repository
    SELECT
        c."repo_name",
        COUNT(*) AS "commit_count"
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_COMMITS" c
    GROUP BY c."repo_name"
)
SELECT
    js."repo_name",
    cc."commit_count"
FROM js_repos js
JOIN commit_counts cc
  ON js."repo_name" = cc."repo_name"
ORDER BY cc."commit_count" DESC NULLS LAST
LIMIT 2;