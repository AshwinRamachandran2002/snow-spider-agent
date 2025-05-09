WITH candidate_drugs AS (   -- locate the 4 requested drugs by any of their names
    SELECT DISTINCT m."id"
    FROM OPEN_TARGETS_PLATFORM_1.PLATFORM.MOLECULE m
    WHERE LOWER(m."name") IN ('keytruda','vioxx','premarin','humira')

    UNION

    SELECT DISTINCT m."id"
    FROM OPEN_TARGETS_PLATFORM_1.PLATFORM.MOLECULE m,
         LATERAL FLATTEN(INPUT => m."tradeNames":list) tn
    WHERE LOWER(tn.value:"element"::STRING) IN ('keytruda','vioxx','premarin','humira')

    UNION

    SELECT DISTINCT m."id"
    FROM OPEN_TARGETS_PLATFORM_1.PLATFORM.MOLECULE m,
         LATERAL FLATTEN(INPUT => m."synonyms":list) sn
    WHERE LOWER(sn.value:"element"::STRING) IN ('keytruda','vioxx','premarin','humira')
),
black_box_drugs AS (        -- all ChEMBL IDs that carry a Black Box Warning
    SELECT DISTINCT chem.value:"element"::STRING AS chembl_id
    FROM OPEN_TARGETS_PLATFORM_1.PLATFORM.DRUGWARNINGS dw,
         LATERAL FLATTEN(INPUT => dw."chemblIds":list) chem
    WHERE LOWER(dw."warningType") = 'black box warning'
)
SELECT
       m."id"                AS "drug_id",
       m."drugType",
       m."hasBeenWithdrawn"  AS "withdrawal_status"
FROM   OPEN_TARGETS_PLATFORM_1.PLATFORM.MOLECULE m
JOIN   candidate_drugs  c  ON m."id" = c."id"
JOIN   black_box_drugs bb ON m."id" = bb.chembl_id          -- ensure Black Box Warning
WHERE  m."isApproved" = TRUE                                -- approved drugs
  AND  m."drugType"  IS NOT NULL;                           -- known drug type