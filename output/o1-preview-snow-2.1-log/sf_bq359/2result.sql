WITH languages_expanded AS (
    SELECT
        t."repo_name",
        f.value:"name"::STRING AS "language_name",
        f.value:"bytes"::NUMBER AS "language_bytes"
    FROM
        GITHUB_REPOS.GITHUB_REPOS."LANGUAGES" t,
        LATERAL FLATTEN(input => t."language") f
),
primary_languages AS (
    SELECT
        "repo_name",
        "language_name" AS "primary_language",
        "language_bytes"
    FROM (
        SELECT
            "repo_name",
            "language_name",
            "language_bytes",
            ROW_NUMBER() OVER (PARTITION BY "repo_name" ORDER BY "language_bytes" DESC) AS rn
        FROM languages_expanded
    )
    WHERE rn = 1
),
javascript_repos AS (
    SELECT "repo_name"
    FROM primary_languages
    WHERE "primary_language" = 'JavaScript'
),
commit_counts AS (
    SELECT "repo_name", COUNT("commit") AS "commit_count"
    FROM GITHUB_REPOS.GITHUB_REPOS."SAMPLE_COMMITS"
    GROUP BY "repo_name"
)
SELECT cc."repo_name", cc."commit_count"
FROM commit_counts cc
JOIN javascript_repos jr ON cc."repo_name" = jr."repo_name"
ORDER BY cc."commit_count" DESC NULLS LAST
LIMIT 2;