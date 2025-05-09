WITH lines AS (
    SELECT
        f."repo_name",
        TRIM(l.value) AS "Line"
    FROM
        "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES" f
    JOIN
        "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS" c
        ON f."id" = c."id"
    CROSS JOIN LATERAL
        FLATTEN(input => SPLIT(c."content", '\n')) l
    WHERE
        LOWER(f."path") LIKE '%readme.md'
        AND c."binary" = FALSE
        AND l.value IS NOT NULL
        AND TRIM(l.value) != ''
        AND NOT (TRIM(l.value) LIKE '#%' OR TRIM(l.value) LIKE '//%')
),
languages AS (
    SELECT
        "repo_name",
        f.value:"name"::STRING AS "language_name"
    FROM
        "GITHUB_REPOS"."GITHUB_REPOS"."LANGUAGES",
        LATERAL FLATTEN(input => "language") f
)
SELECT
    l."Line",
    COUNT(*) AS "Frequency",
    LISTAGG(DISTINCT lg."language_name", ',') WITHIN GROUP (ORDER BY lg."language_name") AS "Languages"
FROM
    lines l
LEFT JOIN languages lg ON l."repo_name" = lg."repo_name"
GROUP BY
    l."Line"
ORDER BY
    "Frequency" DESC NULLS LAST, l."Line";