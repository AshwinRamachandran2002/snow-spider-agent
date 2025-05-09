/* Consolidate spatial-transcriptomics (Visium-Level-1) and scRNA-seq
   (Levels 2 & 4) metadata together with auxiliary provenance records
   for the specific run “HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test”.            */

SELECT
       t."Filename",
       t."HTAN Parent Biospecimen ID",
       t."Component",
       t."File_Format",
       t."Entity ID",
       t."Run ID"
FROM (
        /* ----------  scRNA-seq  Level-2  ---------- */
        SELECT DISTINCT
               m."Filename",
               m."HTAN_Parent_Data_File_ID"        AS "HTAN Parent Biospecimen ID",
               m."Component",
               m."File_Format",
               m."entityId"                        AS "Entity ID",
               'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test' AS "Run ID"
        FROM   HTAN_2.HTAN."SCRNASEQ_LEVEL2_METADATA_CURRENT"  m
        WHERE  m."Filename" ILIKE '%HT264P1%'

        UNION ALL

        /* ----------  scRNA-seq  Level-4  ---------- */
        SELECT DISTINCT
               l4."Filename",
               l4."HTAN_Parent_Data_File_ID"       AS "HTAN Parent Biospecimen ID",
               l4."Component",
               l4."File_Format",
               l4."entityId"                       AS "Entity ID",
               'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test' AS "Run ID"
        FROM   HTAN_2.HTAN."SCRNASEQ_LEVEL4_METADATA_CURRENT"  l4
        WHERE  l4."Filename" ILIKE '%HT264P1%'

        UNION ALL

        /* ----------  Spatial-Tx  Level-1  &  auxiliary provenance  ---------- */
        SELECT DISTINCT
               p."Filename",
               p."HTAN_Parent_Data_File_ID"        AS "HTAN Parent Biospecimen ID",
               p."Component",
               NULL                                 AS "File_Format",
               p."entityId"                        AS "Entity ID",
               'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test' AS "Run ID"
        FROM   HTAN_2.HTAN."ID_PROVENANCE_CURRENT" p
        WHERE  p."Filename" ILIKE '%HT264P1%'
) t
ORDER BY t."Filename" NULLS LAST;