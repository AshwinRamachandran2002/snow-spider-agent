WITH clinical AS (
    SELECT
        "bcr_patient_barcode"      AS "ParticipantBarcode",
        "histological_type"        AS "HistType"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
    WHERE "acronym" = 'BRCA'
      AND "histological_type" IS NOT NULL
      AND TRIM("histological_type") NOT IN ('', '[Not Applicable]', '[Not Available]', '[Discrepancy]', '[Pending]')
),  

cdh1_mutated_patients AS (
    SELECT DISTINCT
        "ParticipantBarcode"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study"        = 'BRCA'
      AND "Hugo_Symbol"  = 'CDH1'
      AND "FILTER"       = 'PASS'
),  

patient_status AS (
    SELECT
        c."HistType",
        CASE WHEN m."ParticipantBarcode" IS NOT NULL THEN 'Mutated' ELSE 'Wildtype' END AS "MutStatus"
    FROM clinical c
    LEFT JOIN cdh1_mutated_patients m
           ON c."ParticipantBarcode" = m."ParticipantBarcode"
),  

-- keep only histological types and mutation-status columns with marginal totals > 10
valid_hist AS (
    SELECT "HistType"
    FROM patient_status
    GROUP BY "HistType"
    HAVING COUNT(*) > 10
),  
valid_status AS (
    SELECT "MutStatus"
    FROM patient_status
    GROUP BY "MutStatus"
    HAVING COUNT(*) > 10
),  

filtered_data AS (
    SELECT ps."HistType", ps."MutStatus"
    FROM patient_status ps
    JOIN valid_hist   vh ON ps."HistType"  = vh."HistType"
    JOIN valid_status vs ON ps."MutStatus" = vs."MutStatus"
),  

observed_counts AS (
    SELECT
        "HistType",
        "MutStatus",
        COUNT(*) AS "Observed"
    FROM filtered_data
    GROUP BY "HistType", "MutStatus"
),  

row_totals AS (
    SELECT "HistType",
           SUM("Observed") AS "RowTotal"
    FROM observed_counts
    GROUP BY "HistType"
),  
col_totals AS (
    SELECT "MutStatus",
           SUM("Observed") AS "ColTotal"
    FROM observed_counts
    GROUP BY "MutStatus"
),  
grand_total AS (
    SELECT SUM("Observed") AS "N"
    FROM observed_counts
),  

expected_vals AS (
    SELECT
        o."HistType",
        o."MutStatus",
        o."Observed",
        (r."RowTotal" * c."ColTotal") / g."N"  AS "Expected"
    FROM observed_counts o
    JOIN row_totals r   ON o."HistType"  = r."HistType"
    JOIN col_totals c   ON o."MutStatus" = c."MutStatus"
    CROSS JOIN grand_total g
),  

chi_square_calc AS (
    SELECT
        SUM( POWER(("Observed" - "Expected"), 2) / "Expected" ) AS "Chi_Square_Value"
    FROM expected_vals
)

SELECT "Chi_Square_Value"
FROM chi_square_calc;