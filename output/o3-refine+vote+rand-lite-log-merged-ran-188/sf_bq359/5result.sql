WITH "PRIMARY_JS_REPOS" AS (
    /* Repositories whose primary (largest‑bytes) language is JavaScript */
    SELECT
        sub."repo_name"
    FROM (
        SELECT
            l."repo_name",
            LOWER(f.value:"name"::string)       AS "language_name",
            f.value:"bytes"::number            AS "bytes",
            ROW_NUMBER() OVER (PARTITION BY l."repo_name"
                               ORDER BY f.value:"bytes"::number DESC) AS rn
        FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES l,
             LATERAL FLATTEN(input => l."language") f
    ) sub
    WHERE sub.rn = 1
      AND sub."language_name" = 'javascript'
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
JOIN "PRIMARY_JS_REPOS" p
  ON c."repo_name" = p."repo_name"
ORDER BY c."commit_count" DESC NULLS LAST,
         c."repo_name"
LIMIT 2;