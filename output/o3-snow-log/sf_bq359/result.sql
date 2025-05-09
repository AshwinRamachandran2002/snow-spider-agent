WITH "lang_primary" AS (
    SELECT
        "repo_name",
        LOWER(f.value:"name"::string)  AS "language",
        f.value:"bytes"::number        AS "bytes",
        ROW_NUMBER() OVER (PARTITION BY "repo_name"
                           ORDER BY f.value:"bytes"::number DESC NULLS LAST) AS "rn"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES,
         LATERAL FLATTEN(input => "language") f
    WHERE f.value:"name" IS NOT NULL
), 
"js_repos" AS (
    SELECT "repo_name"
    FROM   "lang_primary"
    WHERE  "rn" = 1
       AND "language" = 'javascript'
), 
"commit_counts" AS (
    SELECT "repo_name",
           COUNT(*) AS "commit_count"
    FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS
    GROUP  BY "repo_name"
)
SELECT c."repo_name",
       c."commit_count"
FROM   "commit_counts" c
JOIN   "js_repos"      j
       ON c."repo_name" = j."repo_name"
ORDER  BY c."commit_count" DESC NULLS LAST
LIMIT  2;