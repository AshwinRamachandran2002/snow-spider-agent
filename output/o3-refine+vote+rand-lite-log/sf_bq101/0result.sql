WITH java_files AS (
    SELECT
        "sample_repo_name",
        "sample_path",
        "content"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE LOWER("sample_path") LIKE '%.java'            -- only Java source files
),
lines AS (
    -- split each file into individual lines
    SELECT
        "sample_repo_name",
        "sample_path",
        TRIM(f.value::string) AS line
    FROM java_files,
         LATERAL FLATTEN(INPUT => SPLIT("content", '\n')) f
),
imports AS (
    -- keep only import statements and capture the package portion
    SELECT
        REGEXP_SUBSTR(
            line,
            'import\\s+(static\\s+)?([A-Za-z_][A-Za-z0-9_]*(\\.[A-Za-z_][A-Za-z0-9_]*)*)\\.[A-Za-z_][A-Za-z0-9_\\*]*\\s*;',
            1,       -- start position
            1,       -- first occurrence
            'i',     -- case‑insensitive
            2        -- return the 2nd capture group → the package name
        ) AS package_name
    FROM lines
    WHERE line ILIKE 'import %'
),
clean AS (
    -- discard rows where regex did not match
    SELECT package_name
    FROM imports
    WHERE package_name IS NOT NULL
)
SELECT
    package_name,
    COUNT(*) AS import_count
FROM clean
GROUP BY package_name
ORDER BY import_count DESC NULLS LAST, package_name
LIMIT 10;