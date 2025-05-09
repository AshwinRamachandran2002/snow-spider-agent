WITH lang_expanded AS (
    SELECT
        l."repo_name",
        f.value:"name"::string  AS "language",
        f.value:"bytes"::number AS "bytes"
    FROM
        GITHUB_REPOS.GITHUB_REPOS.LANGUAGES l,
        LATERAL FLATTEN(input => l."language") f
),
primary_language AS (
    SELECT
        "repo_name",
        "language",
        ROW_NUMBER() OVER (
            PARTITION BY "repo_name"
            ORDER BY "bytes" DESC NULLS LAST
        ) AS rn
    FROM
        lang_expanded
),
javascript_repos AS (
    SELECT
        "repo_name"
    FROM
        primary_language
    WHERE
        rn = 1
        AND "language" = 'JavaScript'
),
commit_totals AS (
    SELECT
        c."repo_name",
        COUNT(*) AS commit_count
    FROM
        GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS c
        JOIN javascript_repos j
          ON c."repo_name" = j."repo_name"
    GROUP BY
        c."repo_name"
)
SELECT
    "repo_name",
    commit_count
FROM
    commit_totals
ORDER BY
    commit_count DESC NULLS LAST,
    "repo_name"
LIMIT 2;