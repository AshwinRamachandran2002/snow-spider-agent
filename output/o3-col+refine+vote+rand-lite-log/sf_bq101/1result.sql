WITH java_imports AS (
    SELECT
        /* 1. grab the token that follows the keyword “import”                 */
        /* 2. drop any trailing ".*" from wildcard imports                     */
        /* 3. if the final path segment starts with a capital letter (class),  */
        /*    strip that segment off, leaving only the package name            */
        REGEXP_REPLACE(
            REGEXP_REPLACE(
                REGEXP_SUBSTR( TRIM(f.value::STRING),
                                'import\\s+([A-Za-z0-9_\\.\\*]+)', 1, 1, 'e'),
                '\\.\\*$',                              -- remove  .*
                ''
            ),
            '\\.[A-Z][A-Za-z0-9_]*$'                    -- remove .ClassName
        )             AS "import_package"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc,
         LATERAL FLATTEN( INPUT => SPLIT(sc."content", '\n') ) f
    WHERE sc."sample_path" ILIKE '%.java'                -- only Java sources
      AND TRIM(f.value::STRING) ILIKE 'import %'         -- keep import lines
)
SELECT   "import_package",
         COUNT(*) AS "pkg_occurrences"
FROM     java_imports
WHERE    "import_package" IS NOT NULL
  AND    "import_package" <> ''
GROUP BY "import_package"
ORDER BY "pkg_occurrences" DESC NULLS LAST
LIMIT    10;