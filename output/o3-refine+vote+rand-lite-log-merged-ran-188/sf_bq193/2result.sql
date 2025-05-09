WITH readme_lines AS (
    SELECT
        c."sample_repo_name"                      AS "repo_name",
        TRIM(t.value::STRING)                     AS "line"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c,
         LATERAL SPLIT_TO_TABLE(c."content", '\n') t
    WHERE c."sample_path" ILIKE '%README%'
),
clean_lines AS (
    SELECT "repo_name", "line"
    FROM readme_lines
    WHERE "line" <> ''
      AND "line" NOT LIKE '#%'
      AND "line" NOT LIKE '//%'
),
line_freq AS (
    SELECT "line", COUNT(*) AS "appearances"
    FROM clean_lines
    GROUP BY "line"
),
line_lang AS (
    SELECT DISTINCT
        cl."line",
        fl.value::STRING AS "language_name"
    FROM clean_lines                               cl
    JOIN GITHUB_REPOS.GITHUB_REPOS.LANGUAGES  lg
          ON lg."repo_name" = cl."repo_name",
         LATERAL FLATTEN(input => lg."language") fl
),
lang_agg AS (
    SELECT
        "line",
        LISTAGG(DISTINCT "language_name", ', ')
            WITHIN GROUP (ORDER BY "language_name") AS "languages"
    FROM line_lang
    GROUP BY "line"
)
SELECT
    lf."line",
    lf."appearances",
    COALESCE(la."languages", '') AS "languages"
FROM line_freq lf
LEFT JOIN lang_agg la USING ("line")
ORDER BY lf."appearances" DESC NULLS LAST;