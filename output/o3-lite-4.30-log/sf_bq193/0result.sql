WITH readme_lines AS (              -- all distinct, non‑comment lines from any README.md
    SELECT DISTINCT
           sf."repo_name",
           TRIM(f.value::STRING) AS "line"
    FROM  "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES"     sf
    JOIN  "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS"  sc
          ON sf."id" = sc."id",
          LATERAL FLATTEN(INPUT => SPLIT(sc."content", '\n')) f
    WHERE sf."path" ILIKE '%README.md'          -- README files only
      AND sc."binary" = FALSE                   -- exclude binary blobs
      AND TRIM(f.value::STRING) <> ''           -- omit blank lines
      AND NOT TRIM(f.value::STRING) ILIKE '#%'  -- skip Markdown comment/heading
      AND NOT TRIM(f.value::STRING) ILIKE '//%' -- skip code comments
),
repo_langs AS (                   -- explode language arrays to one row per language
    SELECT
        lg."repo_name",
        COALESCE(fl.value:"name"::STRING, fl.value::STRING) AS "language"
    FROM  "GITHUB_REPOS"."GITHUB_REPOS"."LANGUAGES" lg,
          LATERAL FLATTEN(INPUT => lg."language") fl
    WHERE COALESCE(fl.value:"name"::STRING, fl.value::STRING) IS NOT NULL
)
SELECT
    rl."line"                                            AS line,
    COUNT(DISTINCT rl."repo_name")                       AS occurrences,
    LISTAGG(DISTINCT rl_lang."language", ',')
        WITHIN GROUP (ORDER BY rl_lang."language")       AS languages
FROM readme_lines rl
LEFT JOIN repo_langs rl_lang
       ON rl."repo_name" = rl_lang."repo_name"
GROUP BY rl."line"
ORDER BY occurrences DESC NULLS LAST, line;