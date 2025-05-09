WITH cleaned_lines AS (                             -- 1. keep useful README lines
    SELECT
        f."repo_name",
        TRIM(fl.value::STRING) AS "line"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES    f
    JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c
      ON f."id" = c."id",
         LATERAL FLATTEN(INPUT => SPLIT(c."content", '\n')) fl
    WHERE f."path" ILIKE '%README.md%'             -- only README files
      AND TRIM(fl.value::STRING) <> ''             -- non-empty lines
      AND NOT REGEXP_LIKE(TRIM(fl.value::STRING), '^(#|//)')  -- exclude comment lines
),
repo_language_pairs AS (                            -- 2. expand JSON languages
    SELECT
        l."repo_name",
        lang.value:"name"::STRING AS "language_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES l,
         LATERAL FLATTEN(INPUT => PARSE_JSON(l."language")) lang
    WHERE lang.value:"name" IS NOT NULL
),
line_repo_lang AS (                                 -- 3. attach languages to lines
    SELECT
        cl."line",
        cl."repo_name",
        rlp."language_name"
    FROM cleaned_lines cl
    LEFT JOIN repo_language_pairs rlp
           ON cl."repo_name" = rlp."repo_name"
)
SELECT                                              -- 4. final aggregation
    "line",
    COUNT(DISTINCT "repo_name") AS "repo_frequency",
    ARRAY_TO_STRING(
        ARRAY_SORT(ARRAY_AGG(DISTINCT "language_name")),
        ','
    ) AS "languages"
FROM line_repo_lang
GROUP BY "line"
ORDER BY "repo_frequency" DESC NULLS LAST;