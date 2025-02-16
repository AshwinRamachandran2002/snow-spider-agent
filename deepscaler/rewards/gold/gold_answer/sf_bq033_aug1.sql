-- Task: List the application number, filing date, and abstract for U.S. publications where the abstract includes 'internet of things'.
WITH Patent_Matches AS (
    SELECT
      TO_DATE(CAST(ANY_VALUE(patentsdb."filing_date") AS STRING), 'YYYYMMDD') AS Patent_Filing_Date,
      patentsdb."application_number" AS Patent_Application_Number,
      MAX(abstract_info.value:"text") AS Patent_Abstract,
      MAX(abstract_info.value:"language") AS Patent_Abstract_Language
    FROM
      PATENTS.PATENTS.PUBLICATIONS AS patentsdb,
      LATERAL FLATTEN(input => patentsdb."abstract_localized") AS abstract_info
    WHERE
      LOWER(abstract_info.value:"text") LIKE '%internet of things%'
      AND patentsdb."country_code" = 'US'
    GROUP BY
      Patent_Application_Number
)
SELECT
    Patent_Application_Number,
    Patent_Filing_Date,
    Patent_Abstract
FROM
    Patent_Matches;