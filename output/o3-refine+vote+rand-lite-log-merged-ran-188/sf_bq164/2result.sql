/* Consolidated metadata (Levels 1–4 + Auxiliary) for run 
   'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test' */
SELECT  "Filename",
        "HTAN_Parent_Biospecimen_ID",
        "Component",
        "File_Format",
        "entityId",
        "Run_ID"
FROM    HTAN_2.HTAN."_10XVISIUM_SPATIALTRANSCRIPTOMICS_SCRNASEQ_LEVEL1_METADATA_CURRENT"
WHERE   "Run_ID" = 'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test'

UNION ALL
SELECT  "Filename",
        "HTAN_Parent_Biospecimen_ID",
        "Component",
        "File_Format",
        "entityId",
        "Run_ID"
FROM    HTAN_2.HTAN."_10XVISIUM_SPATIALTRANSCRIPTOMICS_SCRNASEQ_LEVEL2_METADATA_CURRENT"
WHERE   "Run_ID" = 'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test'

UNION ALL
SELECT  "Filename",
        "HTAN_Parent_Biospecimen_ID",
        "Component",
        "File_Format",
        "entityId",
        "Run_ID"
FROM    HTAN_2.HTAN."_10XVISIUM_SPATIALTRANSCRIPTOMICS_SCRNASEQ_LEVEL3_METADATA_CURRENT"
WHERE   "Run_ID" = 'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test'

UNION ALL
SELECT  "Filename",
        "HTAN_Parent_Biospecimen_ID",
        "Component",
        "File_Format",
        "entityId",
        "Run_ID"
FROM    HTAN_2.HTAN."_10XVISIUM_SPATIALTRANSCRIPTOMICS_SCRNASEQ_LEVEL4_METADATA_CURRENT"
WHERE   "Run_ID" = 'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test'

UNION ALL
SELECT  "Filename",
        "HTAN_Parent_Biospecimen_ID",
        "Component",
        "File_Format",
        "entityId",
        "Run_ID"
FROM    HTAN_2.HTAN."_10XVISIUM_SPATIALTRANSCRIPTOMICS_AUXILIARYFILES_METADATA_CURRENT"
WHERE   "Run_ID" = 'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test'

ORDER BY "Component", "Filename";