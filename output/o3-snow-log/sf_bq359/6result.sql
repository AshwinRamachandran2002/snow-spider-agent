WITH "LANG_ELEMENTS" AS (
    SELECT
        "repo_name",
        f.value:"name"::STRING   AS "language",
        f.value:"bytes"::NUMBER  AS "bytes"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES,
         LATERAL FLATTEN(input => "language") f
),
"PRIMARY_JS" AS (        -- repositories whose largest language slice is JavaScript
    SELECT DISTINCT "repo_name"
    FROM "LANG_ELEMENTS"
    WHERE "language" ILIKE 'javascript'
      AND "bytes" IS NOT NULL
    QUALIFY "bytes" = MAX("bytes") OVER (PARTITION BY "repo_name")
),
"COMMIT_COUNTS" AS (
    SELECT
        "repo_name",
        COUNT(*) AS "commit_count"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS
    GROUP BY "repo_name"
)
SELECT
    c."repo_name",
    c."commit_count"
FROM "COMMIT_COUNTS" c
JOIN "PRIMARY_JS" p
  ON p."repo_name" = c."repo_name"
ORDER BY c."commit_count" DESC NULLS LAST
LIMIT 2;