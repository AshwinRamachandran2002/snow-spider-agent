WITH readme_lines AS (
    /* Extract every non-empty, non-comment line from README.md files */
    SELECT
        f."repo_name",
        TRIM(spl.value)::STRING AS "line_text"
    FROM
        GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES    AS f
    JOIN
        GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS AS c
          ON f."id" = c."id",
        LATERAL SPLIT_TO_TABLE(c."content", '\n') AS spl
    WHERE
        f."path" ILIKE '%/README.md'      -- only README.md files
        AND TRIM(spl.value) <> ''         -- drop blank lines
        AND TRIM(spl.value) NOT ILIKE '#%'   -- skip Markdown comments
        AND TRIM(spl.value) NOT ILIKE '//%'  -- skip code comments
)
SELECT
    rl."line_text"                                                   AS "unique_line",
    COUNT(DISTINCT rl."repo_name")                                   AS "frequency",
    ARRAY_TO_STRING(
        ARRAY_AGG(DISTINCT lang."language") 
            WITHIN GROUP (ORDER BY lang."language"), 
        ','
    )                                                                AS "languages_sorted"
FROM
    readme_lines                           AS rl
LEFT JOIN
    GITHUB_REPOS.GITHUB_REPOS.LANGUAGES    AS lang
      ON rl."repo_name" = lang."repo_name"
GROUP BY
    rl."line_text"
ORDER BY
    "frequency" DESC NULLS LAST;