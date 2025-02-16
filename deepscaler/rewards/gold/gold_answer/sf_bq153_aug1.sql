-- Task: Calculate the average of the per-patient average log10(normalized_count + 1) expression levels of the IGF2 gene among LGG patients with valid IGF2 expression data.
WITH
    table1 AS (
        SELECT 
            "Symbol" AS "symbol", 
            AVG(LOG(10, "normalized_count" + 1)) AS "data", 
            "ParticipantBarcode"
        FROM 
            PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED
        WHERE 
            "Study" = 'LGG' 
            AND "Symbol" = 'IGF2' 
            AND "normalized_count" IS NOT NULL
        GROUP BY 
            "ParticipantBarcode", "symbol"
    )
SELECT
    AVG("data") AS "Average_Log_Expression"
FROM
    table1;