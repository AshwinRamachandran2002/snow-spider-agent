WITH readme_files AS (
    SELECT
        sf."repo_name",
        sf."id"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES sf
    WHERE sf."path" ILIKE '%README.md'
),
readme_lines AS (
    SELECT
        rf."repo_name",
        TRIM(line.value) AS line_text
    FROM readme_files rf
    JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc
      ON sc."id" = rf."id",
    LATERAL SPLIT_TO_TABLE(sc."content", '\n') line
    WHERE TRIM(line.value) <> ''
      AND TRIM(line.value) NOT ILIKE '#%'
      AND TRIM(line.value) NOT ILIKE '//%'
),
languages_flat AS (
    SELECT
        l."repo_name",
        lf.value:"name"::STRING AS language_name
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES l,
    LATERAL FLATTEN(INPUT => l."language") lf
    WHERE lf.value:"name" IS NOT NULL
)
SELECT
    rl.line_text AS line,
    COUNT(DISTINCT rl."repo_name") AS occurrences,
    LISTAGG(DISTINCT languages_flat.language_name, ',')
        WITHIN GROUP (ORDER BY languages_flat.language_name) AS languages
FROM readme_lines rl
LEFT JOIN languages_flat
       ON languages_flat."repo_name" = rl."repo_name"
GROUP BY rl.line_text
ORDER BY occurrences DESC NULLS LAST, line;