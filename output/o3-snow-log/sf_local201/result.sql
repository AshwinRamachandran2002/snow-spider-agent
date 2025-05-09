WITH words_filtered AS (
    SELECT 
        "words",
        ARRAY_TO_STRING(ARRAY_SORT(SPLIT("words", '')), '')      AS signature,
        LENGTH("words")                                          AS len
    FROM MODERN_DATA.MODERN_DATA.WORD_LIST
    WHERE LEFT("words", 1) = 'r'           -- starts with lowercase r
      AND LENGTH("words") BETWEEN 4 AND 5  -- 4- to 5-character words
), group_sizes AS (
    SELECT 
        signature,
        len,
        COUNT(*) AS anagram_count
    FROM words_filtered
    GROUP BY signature, len
    HAVING COUNT(*) > 1                    -- must have at least one anagram
)
SELECT 
    wf."words"       AS word,
    gs.anagram_count
FROM words_filtered wf
JOIN group_sizes gs
  ON wf.signature = gs.signature
 AND wf.len       = gs.len
ORDER BY wf."words"
FETCH FIRST 10 ROWS;