/* Top‑10 most frequently imported Java packages */
WITH java_files AS (          -- keep only Java source files
    SELECT
        "sample_repo_name",
        "id",
        "sample_path",
        "content"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE LOWER("sample_path") LIKE '%.java'
),

lines AS (                    -- split each file into individual lines
    SELECT
        jf."sample_repo_name",
        jf."id",
        f.value::string AS line_text
    FROM java_files jf,
         LATERAL FLATTEN(input => SPLIT(jf."content", '\n')) f
),

imports AS (                  -- extract imported package names
    SELECT
        /* 1) pull fully‑qualified import with REGEXP_SUBSTR (group 2)
           2) strip final identifier so we keep only the package part   */
        REGEXP_REPLACE(
            REGEXP_SUBSTR(
                line_text,
                '\\bimport\\s+(static\\s+)?([A-Za-z_][A-Za-z0-9_]*(\\.[A-Za-z_][A-Za-z0-9_]*)*)',
                1,           -- start position
                1,           -- first occurrence
                'i',         -- case‑insensitive
                2            -- return capture group 2
            ),
            '\\.[^.]+$'      -- drop the last element (class or *)
        ) AS package_name
    FROM lines
    WHERE line_text ILIKE 'import %'
),

package_counts AS (           -- count occurrences
    SELECT
        package_name,
        COUNT(*) AS import_count
    FROM imports
    WHERE package_name IS NOT NULL AND package_name <> ''
    GROUP BY package_name
)

SELECT
    package_name,
    import_count
FROM package_counts
ORDER BY import_count DESC NULLS LAST, package_name
LIMIT 10;