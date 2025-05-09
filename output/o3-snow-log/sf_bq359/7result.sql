WITH "lang" AS (
    SELECT
        "repo_name",
        LOWER(f.value:"name"::STRING)        AS "language_name",
        COALESCE(f.value:"bytes"::NUMBER,0)  AS "bytes",
        ROW_NUMBER() OVER (PARTITION BY "repo_name"
                           ORDER BY COALESCE(f.value:"bytes"::NUMBER,0) DESC) AS "rn"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES,
         LATERAL FLATTEN(INPUT => "language") f
),
"primary_lang" AS (
    SELECT "repo_name"
    FROM   "lang"
    WHERE  "rn" = 1
      AND  "language_name" = 'javascript'
),
"commit_counts" AS (
    SELECT
        "repo_name",
        COUNT(*) AS "commit_count"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS
    GROUP BY "repo_name"
)
SELECT
    p."repo_name",
    c."commit_count"
FROM   "primary_lang"  p
JOIN   "commit_counts" c
ON     p."repo_name" = c."repo_name"
ORDER BY c."commit_count" DESC NULLS LAST
LIMIT 2;