WITH readme_lines AS (   -- every non‑blank, non‑comment line found in README.md files
    SELECT
        f."repo_name",
        TRIM(l.value::STRING) AS "clean_line"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES     AS f
    JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  AS c
          ON c."id" = f."id"
    ,    LATERAL FLATTEN(input => SPLIT(c."content", '\n')) AS l
    WHERE f."path" ILIKE '%README.md'                    -- only README files
      AND TRIM(l.value::STRING) <> ''                    -- skip blank lines
      AND TRIM(l.value::STRING) NOT ILIKE '#%'           -- skip “# …”
      AND TRIM(l.value::STRING) NOT ILIKE '//%'          -- skip “// …”
),
languages_per_repo AS (   -- one row per (repo, language‑name)
    SELECT
        lang."repo_name",
        COALESCE(                                    -- works for both ARRAY and OBJECT variants
            item.value:"name"::STRING,               -- array element: {"name":"Python", …}
            item.key::STRING,                        -- object: "Python": 12345
            item.value::STRING                       -- simple scalar, fallback
        ) AS "language_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES AS lang,
         LATERAL FLATTEN(input => lang."language") AS item
),
result AS (   -- frequency of each unique line + languages seen in repos that contain it
    SELECT
        rl."clean_line",
        COUNT(DISTINCT rl."repo_name")                                   AS "freq",
        LISTAGG(DISTINCT lp."language_name", ',')
            WITHIN GROUP (ORDER BY lp."language_name")                  AS "languages"
    FROM readme_lines        AS rl
    LEFT JOIN languages_per_repo AS lp
           ON lp."repo_name" = rl."repo_name"
    GROUP BY rl."clean_line"
)
SELECT *
FROM result
ORDER BY "freq" DESC NULLS LAST, "clean_line";