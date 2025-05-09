WITH repo_langs AS (   /* one row per repository-language pair */
    SELECT
        l."repo_name",
        fl.value:"name"::STRING AS "language_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES l,
         LATERAL FLATTEN(INPUT => l."language") fl
    WHERE fl.value:"name" IS NOT NULL
), readme_lines AS (   /* one row per non-empty, non-comment line in README.md */
    SELECT
        f."repo_name",
        TRIM(fl.value)::STRING AS "clean_line"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES f
    JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c
          ON f."id" = c."id",
         LATERAL FLATTEN(INPUT => SPLIT(c."content", '\n')) fl
    WHERE f."path" ILIKE '%README.md'            -- only README files
      AND TRIM(fl.value) <> ''                   -- skip empty lines
      AND NOT (TRIM(fl.value) LIKE '#%')         -- skip “# …” markdown comments
      AND NOT (TRIM(fl.value) LIKE '//%')        -- skip “// …” code comments
)
SELECT
    l."clean_line",
    COUNT(*) AS "line_frequency",
    LISTAGG(DISTINCT r."language_name", ',')
        WITHIN GROUP (ORDER BY r."language_name") AS "languages_used"
FROM readme_lines l
LEFT JOIN repo_langs r
       ON l."repo_name" = r."repo_name"
GROUP BY l."clean_line"
ORDER BY "line_frequency" DESC NULLS LAST;