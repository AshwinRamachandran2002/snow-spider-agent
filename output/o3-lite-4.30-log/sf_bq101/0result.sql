WITH java_files AS (
    SELECT  f."id",
            c."content"
    FROM    "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES"   f
    JOIN    "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS" c
          ON f."id" = c."id"
    WHERE   f."path" ILIKE '%.java'                      -- only Java source files
),
import_lines AS (
    SELECT
        REGEXP_SUBSTR(
            l.value::STRING,
            '^[[:space:]]*import[[:space:]]+(static[[:space:]]+)?([A-Za-z0-9_.]+)\\.[A-Za-z0-9_*]+',
            1,                                           -- start position
            1,                                           -- first match
            'i',                                         -- case‑insensitive
            2                                            -- return 2nd capture group (package)
        ) AS "package_name"
    FROM java_files jf,
         LATERAL FLATTEN(INPUT => SPLIT(jf."content", '\n')) l
),
package_counts AS (
    SELECT  "package_name",
            COUNT(*) AS "total_imports"
    FROM    import_lines
    WHERE   "package_name" IS NOT NULL
    GROUP BY "package_name"
)
SELECT  "package_name",
        "total_imports"
FROM    package_counts
ORDER BY "total_imports" DESC NULLS LAST,
         "package_name"
LIMIT 10;