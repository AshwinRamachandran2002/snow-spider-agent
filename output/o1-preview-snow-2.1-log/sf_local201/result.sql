WITH words_filtered AS (
  SELECT
    "words" AS word,
    LOWER("words") AS word_lower,
    LENGTH("words") AS word_length
  FROM MODERN_DATA.MODERN_DATA.WORD_LIST
  WHERE "words" ILIKE 'r%' AND LENGTH("words") BETWEEN 4 AND 5
),
words_with_sorted_letters AS (
  SELECT
    word,
    CASE WHEN word_length = 4 THEN
      ARRAY_TO_STRING(ARRAY_SORT(ARRAY_CONSTRUCT(
        SUBSTRING(word_lower, 1, 1),
        SUBSTRING(word_lower, 2, 1),
        SUBSTRING(word_lower, 3, 1),
        SUBSTRING(word_lower, 4, 1)
      )), '')
    ELSE
      ARRAY_TO_STRING(ARRAY_SORT(ARRAY_CONSTRUCT(
        SUBSTRING(word_lower, 1, 1),
        SUBSTRING(word_lower, 2, 1),
        SUBSTRING(word_lower, 3, 1),
        SUBSTRING(word_lower, 4, 1),
        SUBSTRING(word_lower, 5, 1)
      )), '')
    END AS sorted_letters
  FROM words_filtered
),
all_words_filtered AS (
  SELECT
    "words" AS word,
    LOWER("words") AS word_lower,
    LENGTH("words") AS word_length
  FROM MODERN_DATA.MODERN_DATA.WORD_LIST
  WHERE LENGTH("words") BETWEEN 4 AND 5
),
all_words_with_sorted_letters AS (
  SELECT
    word,
    CASE WHEN word_length = 4 THEN
      ARRAY_TO_STRING(ARRAY_SORT(ARRAY_CONSTRUCT(
        SUBSTRING(word_lower, 1, 1),
        SUBSTRING(word_lower, 2, 1),
        SUBSTRING(word_lower, 3, 1),
        SUBSTRING(word_lower, 4, 1)
      )), '')
    ELSE
      ARRAY_TO_STRING(ARRAY_SORT(ARRAY_CONSTRUCT(
        SUBSTRING(word_lower, 1, 1),
        SUBSTRING(word_lower, 2, 1),
        SUBSTRING(word_lower, 3, 1),
        SUBSTRING(word_lower, 4, 1),
        SUBSTRING(word_lower, 5, 1)
      )), '')
    END AS sorted_letters
  FROM all_words_filtered
),
anagram_counts AS (
  SELECT
    w.word,
    COUNT(DISTINCT aw.word) AS anagram_count
  FROM words_with_sorted_letters w
  JOIN all_words_with_sorted_letters aw
    ON w.sorted_letters = aw.sorted_letters AND w.word <> aw.word
  GROUP BY w.word
)
SELECT
  word,
  anagram_count
FROM anagram_counts
WHERE anagram_count >= 1
ORDER BY word
LIMIT 10;