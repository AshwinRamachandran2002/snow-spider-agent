WITH lang_flat AS (
    SELECT
        "repo_name",
        LOWER(
            COALESCE(
                NULLIF(f.key::string, ''),
                f.value:"name"::string
            )
        )                                                     AS "lang_name",
        CASE
            WHEN TYPEOF(f.value) = 'OBJECT'
                 THEN COALESCE(f.value:"bytes"::NUMBER, 0)
            WHEN TYPEOF(f.value) IN ('INTEGER', 'FLOAT')
                 THEN f.value::NUMBER
            ELSE 0
        END                                                   AS "bytes"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES,
         LATERAL FLATTEN(input => "language") f
),
ranked_lang AS (
    SELECT
        "repo_name",
        "lang_name",
        "bytes",
        ROW_NUMBER() OVER (PARTITION BY "repo_name"
                           ORDER BY "bytes" DESC)             AS rn
    FROM lang_flat
),
primary_js_repos AS (
    SELECT "repo_name"
    FROM ranked_lang
    WHERE rn = 1
      AND "lang_name" = 'javascript'
),
commit_counts AS (
    SELECT
        "repo_name",
        COUNT(*) AS "commit_count"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS
    WHERE "repo_name" IN (SELECT "repo_name" FROM primary_js_repos)
    GROUP BY "repo_name"
)
SELECT
    "repo_name",
    "commit_count"
FROM commit_counts
ORDER BY "commit_count" DESC NULLS LAST
LIMIT 2;