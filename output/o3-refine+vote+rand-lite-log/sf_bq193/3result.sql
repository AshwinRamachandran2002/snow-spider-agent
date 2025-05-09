WITH readme_files AS (                    -- 1. every README.md blob
    SELECT  sf."repo_name",
            sf."id"
    FROM    GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES sf
    WHERE   LOWER(sf."path") LIKE '%readme.md'          -- README, README.md …
),

readme_lines AS (                         -- 2. split into non‑empty, non‑comment lines
    SELECT  rf."repo_name",
            TRIM(t.value)                                   AS line
    FROM    readme_files rf
    JOIN    GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc
           ON sc."id" = rf."id"
          ,LATERAL SPLIT_TO_TABLE(sc."content", '\n') t
    WHERE   TRIM(t.value) <> ''
      AND  NOT REGEXP_LIKE(TRIM(t.value), '^(#|//)')        -- skip comments
),

line_repo_distinct AS (                  -- 3. unique (line, repo) pairs
    SELECT DISTINCT line, "repo_name"
    FROM   readme_lines
),

line_freq AS (                           -- 4. how many repos contain each line
    SELECT  line,
            COUNT(*) AS frequency
    FROM    line_repo_distinct
    GROUP BY line
),

line_languages AS (                      -- 5. languages used by repos that have each line
    SELECT  lrd.line,
            COALESCE(                    -- name comes either from object key or array element
                f.key::STRING,
                f.value:"name"::STRING
            )    AS language
    FROM   line_repo_distinct lrd
    LEFT  JOIN GITHUB_REPOS.GITHUB_REPOS.LANGUAGES lg
           ON lg."repo_name" = lrd."repo_name"
          ,LATERAL FLATTEN(INPUT => lg."language") f
    WHERE  COALESCE(f.key, f.value:"name") IS NOT NULL
),

aggregated AS (                          -- 6. comma‑separated, alphabetically sorted languages
    SELECT  lf.line,
            lf.frequency,
            ARRAY_TO_STRING(
                ARRAY_SORT(
                    ARRAY_AGG(DISTINCT ll.language)
                ),
            ',') AS languages
    FROM    line_freq lf
    LEFT JOIN line_languages ll
           ON ll.line = lf.line
    GROUP BY lf.line, lf.frequency
)

SELECT  line,
        frequency,
        languages
FROM    aggregated
ORDER BY frequency DESC NULLS LAST,       -- most common lines first
         line;