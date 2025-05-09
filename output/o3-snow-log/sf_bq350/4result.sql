WITH base AS (  -- approved drugs that carry a boxed warning and have a defined type
    SELECT  
        m."id",
        m."drugType",
        m."hasBeenWithdrawn",
        m."name",
        m."tradeNames",
        m."synonyms"
    FROM OPEN_TARGETS_PLATFORM_1.PLATFORM.MOLECULE m
    WHERE m."isApproved"      = TRUE
      AND m."blackBoxWarning" = TRUE
      AND m."drugType"        IS NOT NULL
),
match_on_name AS (           -- match the four brand names in the main name
    SELECT DISTINCT
           b."id", b."drugType", b."hasBeenWithdrawn"
    FROM   base b
    WHERE  b."name" ILIKE ANY ('%keytruda%','%vioxx%','%premarin%','%humira%')
),
match_on_tradename AS (      -- match inside tradeNames list
    SELECT DISTINCT
           b."id", b."drugType", b."hasBeenWithdrawn"
    FROM   base b,
           LATERAL FLATTEN(INPUT => b."tradeNames":list) t
    WHERE  t.value::string ILIKE ANY ('%keytruda%','%vioxx%','%premarin%','%humira%')
),
match_on_synonym AS (        -- match inside synonyms list
    SELECT DISTINCT
           b."id", b."drugType", b."hasBeenWithdrawn"
    FROM   base b,
           LATERAL FLATTEN(INPUT => b."synonyms":list) s
    WHERE  s.value::string ILIKE ANY ('%keytruda%','%vioxx%','%premarin%','%humira%')
)

SELECT DISTINCT
       "id"               AS drug_id,
       "drugType"         AS drug_type,
       "hasBeenWithdrawn" AS withdrawal_status
FROM (
      SELECT * FROM match_on_name
      UNION
      SELECT * FROM match_on_tradename
      UNION
      SELECT * FROM match_on_synonym
) AS combined
ORDER BY drug_id;