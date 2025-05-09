WITH source_lines AS (
    -- retain only *.py and *.r files, then split each file content into lines
    SELECT
        CASE
            WHEN LOWER(f."path") LIKE '%.py' THEN 'Python'
            ELSE 'R'
        END                               AS "LANGUAGE",
        line_tbl.value                    AS "LINE"
    FROM  GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES     f
    JOIN  GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  c
          ON f."id" = c."id",
          LATERAL SPLIT_TO_TABLE(c."content", '\n')  line_tbl
    WHERE LOWER(f."path") LIKE '%.py'
       OR LOWER(f."path") LIKE '%.r'
),
extracted_modules AS (
    -- extract module / library names
    SELECT
        "LANGUAGE",
        CASE
            /* Python:  import xxx   |   from xxx import yyy  */
            WHEN "LANGUAGE" = 'Python' THEN
                 REGEXP_SUBSTR(
                     "LINE",
                     '^\\s*(import|from)\\s+([A-Za-z0-9_.]+)',
                     1, 1, 'i', 2
                 )

            /* R:  library(xxx)  |  require(xxx) */
            ELSE
                 REGEXP_SUBSTR(
                     "LINE",
                     '\\b(library|require)\\s*\\(\\s*([A-Za-z0-9_.]+)',
                     1, 1, 'i', 2
                 )
        END                           AS "MODULE"
    FROM source_lines
)
SELECT
    "LANGUAGE",
    "MODULE",
    COUNT(*) AS "OCCURRENCES"
FROM extracted_modules
WHERE "MODULE" IS NOT NULL
GROUP BY "LANGUAGE", "MODULE"
ORDER BY "LANGUAGE", "OCCURRENCES" DESC NULLS LAST;