SELECT
    "library_name"
FROM (
    SELECT
        "library_name",
        ROW_NUMBER() OVER (ORDER BY "total_count" DESC NULLS LAST) AS rn
    FROM (
        SELECT
            "library_name",
            COUNT(*) AS "total_count"
        FROM (
            -- Python imports
            SELECT
                LOWER(
                    REGEXP_SUBSTR(c."content", '\\bimport\\s+([\\w\\.]+)', 1, 1, 'i', 1)
                ) AS "library_name"
            FROM
                "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES" AS f
            JOIN
                "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS" AS c
            ON
                f."id" = c."id"
            WHERE
                LOWER(f."path") LIKE '%.py'
                AND c."binary" = FALSE
                AND c."content" IS NOT NULL

            UNION ALL

            -- R library imports
            SELECT
                LOWER(
                    REGEXP_SUBSTR(c."content", '\\blibrary\\s*\\(\\s*["\']?([\\w\\.]+)["\']?', 1, 1, 'i', 1)
                ) AS "library_name"
            FROM
                "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES" AS f
            JOIN
                "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS" AS c
            ON
                f."id" = c."id"
            WHERE
                (
                    LOWER(f."path") LIKE '%.r'
                    OR LOWER(f."path") LIKE '%.rmd'
                    OR LOWER(f."path") LIKE '%.R'
                    OR LOWER(f."path") LIKE '%.Rmd'
                )
                AND c."binary" = FALSE
                AND c."content" IS NOT NULL

            UNION ALL

            -- IPython notebook imports
            SELECT
                LOWER(
                    REGEXP_SUBSTR(
                        source_line.VALUE::STRING,
                        '\\bimport\\s+([\\w\\.]+)',
                        1, 1, 'i', 1
                    )
                ) AS "library_name"
            FROM
                "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES" AS f
            JOIN
                "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS" AS c
            ON
                f."id" = c."id",
                LATERAL FLATTEN(INPUT => PARSE_JSON(c."content"):"cells") AS cell,
                LATERAL FLATTEN(INPUT => cell.VALUE:"source") AS source_line
            WHERE
                LOWER(f."path") LIKE '%.ipynb'
                AND c."binary" = FALSE
                AND c."content" IS NOT NULL
                AND cell.VALUE:"cell_type"::STRING = 'code'
        ) AS all_imports
        WHERE
            "library_name" IS NOT NULL
        GROUP BY
            "library_name"
    ) AS import_counts
)
WHERE
    rn = 2;