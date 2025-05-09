SELECT
  race,
  ROUND(google_percentage - bls_percentage, 4) AS "Percentage_Difference"
FROM (
  SELECT
    'Asian' AS race,
    (
      SELECT "race_asian"
      FROM "GOOGLE_DEI"."GOOGLE_DEI"."DAR_NON_INTERSECTIONAL_HIRING"
      WHERE "report_year" = 2021 AND LOWER("workforce") = 'overall'
    ) AS google_percentage,
    (
      SELECT "percent_asian"
      FROM "GOOGLE_DEI"."BLS"."CPSAAT18"
      WHERE "year" = 2021 AND (
        "industry_group" = 'Computer systems design and related services' OR
        "industry" IN (
          'Internet publishing and broadcasting and web search portals',
          'Software publishers',
          'Data processing, hosting, and related services'
        )
      )
    ) AS bls_percentage
  UNION ALL
  SELECT
    'Black' AS race,
    (
      SELECT "race_black"
      FROM "GOOGLE_DEI"."GOOGLE_DEI"."DAR_NON_INTERSECTIONAL_HIRING"
      WHERE "report_year" = 2021 AND LOWER("workforce") = 'overall'
    ),
    (
      SELECT "percent_black_or_african_american"
      FROM "GOOGLE_DEI"."BLS"."CPSAAT18"
      WHERE "year" = 2021 AND (
        "industry_group" = 'Computer systems design and related services' OR
        "industry" IN (
          'Internet publishing and broadcasting and web search portals',
          'Software publishers',
          'Data processing, hosting, and related services'
        )
      )
    )
  UNION ALL
  SELECT
    'White' AS race,
    (
      SELECT "race_white"
      FROM "GOOGLE_DEI"."GOOGLE_DEI"."DAR_NON_INTERSECTIONAL_HIRING"
      WHERE "report_year" = 2021 AND LOWER("workforce") = 'overall'
    ),
    (
      SELECT "percent_white"
      FROM "GOOGLE_DEI"."BLS"."CPSAAT18"
      WHERE "year" = 2021 AND (
        "industry_group" = 'Computer systems design and related services' OR
        "industry" IN (
          'Internet publishing and broadcasting and web search portals',
          'Software publishers',
          'Data processing, hosting, and related services'
        )
      )
    )
  UNION ALL
  SELECT
    'Hispanic/Latinx' AS race,
    (
      SELECT "race_hispanic_latinx"
      FROM "GOOGLE_DEI"."GOOGLE_DEI"."DAR_NON_INTERSECTIONAL_HIRING"
      WHERE "report_year" = 2021 AND LOWER("workforce") = 'overall'
    ),
    (
      SELECT "percent_hispanic_or_latino"
      FROM "GOOGLE_DEI"."BLS"."CPSAAT18"
      WHERE "year" = 2021 AND (
        "industry_group" = 'Computer systems design and related services' OR
        "industry" IN (
          'Internet publishing and broadcasting and web search portals',
          'Software publishers',
          'Data processing, hosting, and related services'
        )
      )
    )
) AS t
ORDER BY ABS("Percentage_Difference") DESC NULLS LAST
LIMIT 3;