/*  Top‑10 most frequently imported Java packages                       */
WITH import_lines AS (                     -- examine every file line‑by‑line
    SELECT
        TRIM(f.value::string) AS import_line
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  c
         ,LATERAL FLATTEN(INPUT => SPLIT(c."content", CHR(10))) f
    -- Java import statement:  starts with "import ", may have "static ",
    -- consists of identifiers/dots, and ends with a semicolon
    WHERE REGEXP_LIKE(
              TRIM(f.value::string),
              '^import\\s+(static\\s+)?[A-Za-z0-9_\\.]+\\s*;$',
              'i'
          )
),
clean_imports AS (                         -- strip leading/trailing keywords
    SELECT
        REGEXP_REPLACE(
            REGEXP_REPLACE(import_line,
                            '^import\\s+(static\\s+)?',      -- drop "import" (+optional "static")
                            '',
                            1, 0, 'i'),
            ';',                                  -- drop ending semicolon
            ''
        ) AS full_path
    FROM import_lines
),
packages AS (                              -- keep only the package portion
    SELECT
        REGEXP_REPLACE(full_path, '(\\.\\*|\\.[^.]+)$') AS package_name
    FROM clean_imports
    WHERE package_name IS NOT NULL AND package_name <> ''
)
SELECT
    package_name,
    COUNT(*) AS import_count
FROM packages
GROUP BY package_name
ORDER BY import_count DESC NULLS LAST, package_name
LIMIT 10;