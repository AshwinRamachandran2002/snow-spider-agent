-- Task: Identify the first 10 words, sorted alphabetically, that start with 'r' and are 4 to 5 characters long, providing the sorted sequence of letters in each word.
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
)
SELECT
  word,
  sorted_letters
FROM words_with_sorted_letters
ORDER BY word
LIMIT 10;