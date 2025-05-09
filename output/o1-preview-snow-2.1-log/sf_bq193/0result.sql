WITH lines AS (
    SELECT
        TRIM(l.value) AS "Line",
        files."repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES AS files
    JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS AS contents
        ON files."id" = contents."id",
    LATERAL FLATTEN(input => SPLIT(contents."content", '\n')) AS l
    WHERE files."path" ILIKE '%readme.md'
        AND contents."binary" = FALSE
        AND TRIM(l.value) NOT LIKE '#%'
        AND TRIM(l.value) NOT LIKE '//%'
        AND TRIM(l.value) != ''
),
repo_languages AS (
    SELECT
        l."repo_name",
        lf.value:"name"::STRING AS "language"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES AS l,
    LATERAL FLATTEN(input => l."language") AS lf
),
line_languages AS (
    SELECT
        lines."Line",
        repo_languages."language"
    FROM lines
    LEFT JOIN repo_languages ON lines."repo_name" = repo_languages."repo_name"
)
SELECT
    "Line",
    COUNT(*) AS "Frequency",
    ARRAY_TO_STRING(
        ARRAY_SORT(ARRAY_AGG(DISTINCT "language")),
        ', '
    ) AS "Languages"
FROM line_languages
GROUP BY "Line"
ORDER BY "Frequency" DESC NULLS LAST;