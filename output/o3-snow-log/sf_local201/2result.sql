WITH base AS (
    SELECT
        "words"                                        AS word,
        ARRAY_TO_STRING(ARRAY_SORT(SPLIT("words", '')), '') AS signature
    FROM MODERN_DATA.MODERN_DATA.WORD_LIST
    WHERE "words" LIKE 'r%'          -- starts with lowercase r
      AND LENGTH("words") BETWEEN 4 AND 5   -- 4- or 5-letter words
),
anagrams AS (
    SELECT
        signature,
        COUNT(*) AS anagram_count
    FROM base
    GROUP BY signature
    HAVING COUNT(*) > 1              -- must have at least one anagram
)
SELECT
    b.word,
    a.anagram_count
FROM base      b
JOIN anagrams  a  ON b.signature = a.signature
ORDER BY b.word ASC
LIMIT 10;