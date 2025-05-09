WITH base AS (  --  all BRCA patients with histology and CDH1‑mutation status
    SELECT
        c."bcr_patient_barcode",
        c."histological_type",
        CASE
            WHEN m."ParticipantBarcode" IS NULL THEN 'No_Mutation'
            ELSE 'Mutation_Present'
        END                                               AS "CDH1_status"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED" c
    LEFT JOIN (
        SELECT DISTINCT "ParticipantBarcode"
        FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
        WHERE "Study" = 'BRCA'
          AND "Hugo_Symbol" = 'CDH1'
          AND "FILTER" = 'PASS'
    ) m
      ON c."bcr_patient_barcode" = m."ParticipantBarcode"
    WHERE c."acronym" = 'BRCA'
      AND c."histological_type" IS NOT NULL
      AND TRIM(c."histological_type") <> ''
),
row_totals AS (      -- keep histological groups with >10 cases
    SELECT "histological_type", COUNT(*) AS row_total
    FROM base
    GROUP BY "histological_type"
    HAVING COUNT(*) > 10
),
col_totals AS (      -- keep mutation‑status groups with >10 cases
    SELECT "CDH1_status", COUNT(*) AS col_total
    FROM base
    GROUP BY "CDH1_status"
    HAVING COUNT(*) > 10
),
filtered_base AS (   -- data restricted to rows/cols that pass marginal cut‑offs
    SELECT b.*
    FROM base b
    JOIN row_totals r ON b."histological_type" = r."histological_type"
    JOIN col_totals c ON b."CDH1_status"      = c."CDH1_status"
),
observed AS (        -- contingency‑table cell counts
    SELECT
        "histological_type",
        "CDH1_status",
        COUNT(*) AS O
    FROM filtered_base
    GROUP BY "histological_type", "CDH1_status"
),
grand_total AS (SELECT SUM(O) AS G FROM observed),
expected AS (        -- expected counts for each cell
    SELECT
        o."histological_type",
        o."CDH1_status",
        o.O,
        r.row_total,
        c.col_total,
        g.G,
        (r.row_total * c.col_total * 1.0) / g.G AS E
    FROM observed     o
    JOIN row_totals   r ON o."histological_type" = r."histological_type"
    JOIN col_totals   c ON o."CDH1_status"       = c."CDH1_status"
    CROSS JOIN grand_total g
),
chi_calc AS (        -- χ² contribution of each cell
    SELECT SUM(POWER(O - E, 2) / E) AS chi_square_value
    FROM expected
)
SELECT ROUND(chi_square_value,4) AS "chi_square_value"
FROM chi_calc;