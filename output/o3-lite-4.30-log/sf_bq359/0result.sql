WITH lang_rows AS (
    SELECT
        l."repo_name"           AS repo_name,
        f.value:"name"::STRING  AS lang_name,
        f.value:"bytes"::NUMBER AS lang_bytes
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."LANGUAGES" l,
         LATERAL FLATTEN(input => l."language") f
),
primary_lang AS (
    SELECT
        repo_name
    FROM (
        SELECT
            repo_name,
            lang_name,
            ROW_NUMBER() OVER (PARTITION BY repo_name
                               ORDER BY lang_bytes DESC) AS rn
        FROM lang_rows
    )
    WHERE rn = 1
      AND LOWER(lang_name) = 'javascript'
),
commit_counts AS (
    SELECT
        c."repo_name" AS repository_name,
        COUNT(*)      AS commit_count
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_COMMITS" c
    JOIN primary_lang p
      ON c."repo_name" = p.repo_name
    GROUP BY repository_name
)
SELECT
    repository_name,
    commit_count
FROM commit_counts
ORDER BY commit_count DESC NULLS LAST,
         repository_name
LIMIT 2;