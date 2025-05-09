WITH readme_lines AS (                       -- 1️⃣ split every README.md into individual lines
    SELECT
        c."sample_repo_name"                       AS "repo",
        TRIM(f.value::STRING)                      AS "line"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS AS c
         ,LATERAL FLATTEN( INPUT => SPLIT(c."content", '\n') ) AS f
    WHERE c."sample_path" ILIKE '%README.md'                  -- only README.md files
),
cleaned AS (                                   -- 2️⃣ keep only non-empty, non-comment lines
    SELECT DISTINCT
        "repo",
        "line"
    FROM readme_lines
    WHERE "line" <> ''                              -- drop empty lines
      AND "line" NOT ILIKE '#%'                     -- skip markdown comments/headings
      AND "line" NOT ILIKE '//%'                    -- skip code-style comments
),
lines_with_lang AS (                           -- 3️⃣ attach programming languages of each repo
    SELECT
        cl."line",
        cl."repo",
        l."language"::STRING AS "lang"
    FROM cleaned                                   AS cl
    JOIN GITHUB_REPOS.GITHUB_REPOS.LANGUAGES      AS l
          ON l."repo_name" = cl."repo"
    WHERE l."language" IS NOT NULL
),
agg AS (                                        -- 4️⃣ aggregate frequency and language list
    SELECT
        "line",
        COUNT(DISTINCT "repo")                                 AS "frequency",
        ARRAY_TO_STRING(                                       -- comma-separated, sorted list
            ARRAY_SORT(
                ARRAY_DISTINCT( ARRAY_AGG("lang") )
            ),
        ',')                                                   AS "languages"
    FROM lines_with_lang
    GROUP BY "line"
)
SELECT                                          -- 5️⃣ final result ordered by frequency
    "line",
    "frequency",
    "languages"
FROM agg
ORDER BY "frequency" DESC NULLS LAST, "line";