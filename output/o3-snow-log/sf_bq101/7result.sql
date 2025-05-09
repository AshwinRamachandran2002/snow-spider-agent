WITH import_packages AS (
    SELECT
        /* extract the fully-qualified name being imported                */
        /* then drop the class name (last dot segment)                    */
        REGEXP_REPLACE(
            REGEXP_SUBSTR(
                line.value::STRING,
                'import\\s+(static\\s+)?([a-zA-Z0-9_\\.]+)',  -- capture FQCN in group 2
                1,                                            -- start position
                1,                                            -- 1st occurrence
                'e',                                          -- enable sub-expression capture
                2                                             -- return group 2 (the FQCN)
            ),
            '\\.[^.]+$',
            ''
        ) AS import_package
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc,
         LATERAL FLATTEN(input => SPLIT(sc."content", '\n')) line
    WHERE sc."sample_path" ILIKE '%.java'      -- only Java source files
      AND line.value::STRING ILIKE 'import %'  -- lines starting with “import ”
)

SELECT
    import_package,
    COUNT(*) AS occurrences
FROM import_packages
WHERE import_package IS NOT NULL
GROUP BY import_package
ORDER BY occurrences DESC NULLS LAST
LIMIT 10;