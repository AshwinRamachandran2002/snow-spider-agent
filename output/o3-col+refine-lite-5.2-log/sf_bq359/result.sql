WITH "commit_counts" AS (
    SELECT 
        "repo_name",
        COUNT(*) AS "commit_cnt"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS
    GROUP BY "repo_name"
),
"primary_language" AS (
    SELECT
        "repo_name",
        "lang_name"
    FROM (
        SELECT
            l."repo_name",
            f.value:"name"::STRING  AS "lang_name",
            f.value:"bytes"::NUMBER AS "bytes_of_code",
            ROW_NUMBER() OVER (
                PARTITION BY l."repo_name"
                ORDER BY f.value:"bytes"::NUMBER DESC
            ) AS "rn"
        FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES l,
             LATERAL FLATTEN(input => l."language") f
    )
    WHERE "rn" = 1        -- keep only the primary language (largest byte count per repo)
)
SELECT
    c."repo_name",
    c."commit_cnt"
FROM "commit_counts" c
JOIN "primary_language" p
  ON c."repo_name" = p."repo_name"
WHERE p."lang_name" ILIKE 'javascript'  -- repositories whose primary language is JavaScript
ORDER BY 
    c."commit_cnt" DESC NULLS LAST,
    c."repo_name"  ASC
LIMIT 2;