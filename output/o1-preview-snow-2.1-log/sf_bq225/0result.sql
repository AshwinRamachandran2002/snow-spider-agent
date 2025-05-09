WITH MAPPING("language", "key") AS (
    SELECT * FROM VALUES
        ('assembly', '.asm'),
        ('assembly', '.nasm'),
        ('c', '.c'),
        ('c', '.h'),
        ('c#', '.cs'),
        ('c++', '.cpp'),
        ('c++', '.c++'),
        ('c++', '.hpp'),
        ('c++', '.h++'),
        ('css', '.css'),
        ('clojure', '.clj'),
        ('common lisp', '.lisp'),
        ('d', '.d'),
        ('dart', '.dart'),
        ('dockerfile', 'dockerfile'),
        ('dockerfile', '.dockerfile'),
        ('elixir', '.ex'),
        ('elixir', '.exs'),
        ('erlang', '.erl'),
        ('go', '.go'),
        ('groovy', '.groovy'),
        ('html', '.html'),
        ('html', '.htm'),
        ('haskell', '.hs'),
        ('haxe', '.hx'),
        ('json', '.json'),
        ('java', '.java'),
        ('javascript', '.js'),
        ('javascript', '.cjs'),
        ('julia', '.jl'),
        ('kotlin', '.kt'),
        ('kotlin', '.ktm'),
        ('kotlin', '.kts'),
        ('lua', '.lua'),
        ('matlab', '.matlab'),
        ('matlab', '.m'),
        ('markdown', '.md'),
        ('markdown', '.markdown'),
        ('markdown', '.mdown'),
        ('php', '.php'),
        ('powershell', '.ps1'),
        ('powershell', '.psd1'),
        ('powershell', '.psm1'),
        ('python', '.py'),
        ('r', '.r'),
        ('ruby', '.rb'),
        ('rust', '.rs'),
        ('scss', '.scss'),
        ('sql', '.sql'),
        ('sass', '.sass'),
        ('scala', '.scala'),
        ('shell', '.sh'),
        ('shell', '.bash'),
        ('swift', '.swift'),
        ('typescript', '.ts'),
        ('vue', '.vue'),
        ('xml', '.xml'),
        ('yaml', '.yml'),
        ('yaml', '.yaml')
),
FILES AS (
    SELECT
        CASE
            WHEN POSITION('.', LOWER(SPLIT_PART("path", '/', -1))) > 0 THEN
                SUBSTRING(LOWER(SPLIT_PART("path", '/', -1)), POSITION('.', LOWER(SPLIT_PART("path", '/', -1))))
            ELSE
                LOWER(SPLIT_PART("path", '/', -1))
        END AS "key"
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES"
),
MATCHED_FILES AS (
    SELECT
        F."key",
        M."language"
    FROM FILES F
    JOIN MAPPING M ON F."key" = M."key"
)
SELECT
    M."language" AS "Language",
    COUNT(*) AS "File_Count"
FROM MATCHED_FILES M
GROUP BY M."language"
ORDER BY "File_Count" DESC NULLS LAST
LIMIT 10;