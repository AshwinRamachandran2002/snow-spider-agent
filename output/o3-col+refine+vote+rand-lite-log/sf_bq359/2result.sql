WITH primary_lang AS (
    SELECT
        l."repo_name",
        f.value:"name"::STRING   AS "lang_name",
        ROW_NUMBER() OVER (
            PARTITION BY l."repo_name"
            ORDER BY f.value:"bytes"::NUMBER DESC
        )                       AS "rn"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES l,
         LATERAL FLATTEN(input => l."language") f
),
js_primary_repos AS (
    SELECT "repo_name"
    FROM primary_lang
    WHERE "rn" = 1
      AND "lang_name" ILIKE 'javascript'
),
commit_counts AS (
    SELECT
        c."repo_name",
        COUNT(*) AS "commit_cnt"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS c
    JOIN js_primary_repos j
      ON j."repo_name" = c."repo_name"
    GROUP BY c."repo_name"
)
SELECT
    "repo_name",
    "commit_cnt"
FROM commit_counts
ORDER BY "commit_cnt" DESC NULLS LAST
LIMIT 2;