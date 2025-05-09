WITH anagrams AS (
    SELECT
        ARRAY_TO_STRING(ARRAY_SORT(SPLIT(LOWER("words"), '')), '') AS "sorted_letters",
        COUNT(*) AS "anagram_count"
    FROM "MODERN_DATA"."MODERN_DATA"."WORD_LIST"
    GROUP BY "sorted_letters"
    HAVING COUNT(*) > 1
)
SELECT DISTINCT w."words",
       a."anagram_count"
FROM "MODERN_DATA"."MODERN_DATA"."WORD_LIST" w
JOIN anagrams a
    ON ARRAY_TO_STRING(ARRAY_SORT(SPLIT(LOWER(w."words"), '')), '') = a."sorted_letters"
WHERE LENGTH(w."words") BETWEEN 4 AND 5
  AND LOWER(w."words") LIKE 'r%'
ORDER BY w."words" ASC
LIMIT 10;