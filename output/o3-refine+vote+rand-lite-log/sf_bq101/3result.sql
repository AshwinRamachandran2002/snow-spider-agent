WITH "JAVA_FILES" AS (
    /* grab contents of files whose paths end with .java */
    SELECT c."content"
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS"  c
    JOIN "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES"     f
      ON c."id" = f."id"
    WHERE f."path" ILIKE '%.java'
),
"LINES" AS (
    /* split every file into individual lines */
    SELECT TRIM(value::string) AS "line"
    FROM "JAVA_FILES",
         LATERAL FLATTEN(input => SPLIT("content", '\n'))
),
"IMPORT_LINES" AS (
    /* keep only lines that look like Java import statements */
    SELECT "line"
    FROM "LINES"
    WHERE REGEXP_LIKE("line", '^\\s*import\\s+.*;\\s*$')
),
"IMPORT_PATHS" AS (
    /* strip leading 'import' (and optional 'static') and the trailing semicolon */
    SELECT TRIM(
             REPLACE(
               REGEXP_REPLACE("line", '^\\s*import\\s+(static\\s+)?', ''),
               ';',
               ''
             )
           ) AS "full_path"
    FROM "IMPORT_LINES"
),
"PACKAGES" AS (
    /* drop the final token (class name or *) to keep only the package part */
    SELECT REGEXP_REPLACE("full_path", '\\.[^\\.]+$', '') AS "package_name"
    FROM "IMPORT_PATHS"
    WHERE "full_path" IS NOT NULL
          AND "full_path" <> ''
),
"PKG_COUNTS" AS (
    SELECT "package_name",
           COUNT(*) AS "occurrences"
    FROM "PACKAGES"
    GROUP BY "package_name"
)
SELECT "package_name",
       "occurrences"
FROM "PKG_COUNTS"
ORDER BY "occurrences" DESC NULLS LAST,
         "package_name"
LIMIT 10;