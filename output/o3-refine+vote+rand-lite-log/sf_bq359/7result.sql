WITH "LANG_RANK" AS (
    SELECT
        l."repo_name",
        f.value:"name"::STRING  AS "language",
        f.value:"bytes"::NUMBER AS "bytes",
        ROW_NUMBER() OVER (
            PARTITION BY l."repo_name"
            ORDER BY f.value:"bytes"::NUMBER DESC NULLS LAST
        ) AS "rn"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES l,
         LATERAL FLATTEN(input => l."language") f
    WHERE f.value:"name" IS NOT NULL
),
"JS_PRIMARY" AS (
    SELECT "repo_name"
    FROM "LANG_RANK"
    WHERE "rn" = 1
      AND "language" = 'JavaScript'
),
"COMMITS_PER_REPO" AS (
    SELECT
        "repo_name",
        COUNT(*) AS "commit_count"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS
    GROUP BY "repo_name"
)
SELECT
    c."repo_name",
    c."commit_count"
FROM "COMMITS_PER_REPO" c
JOIN "JS_PRIMARY" j
  ON c."repo_name" = j."repo_name"
ORDER BY c."commit_count" DESC NULLS LAST,
         c."repo_name"
LIMIT 2;