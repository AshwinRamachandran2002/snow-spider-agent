SELECT 
    "primaryAnatomicStructure_CodeMeaning" AS embedding_medium_code_meaning,
    "illuminationType_CodeMeaning" AS staining_substance_code_meaning,
    COUNT(*) AS occurrences
FROM 
    IDC.IDC_V17."DICOM_METADATA_CURATED_SERIES_LEVEL"
WHERE 
    "Modality" = 'SM'
GROUP BY 
    "primaryAnatomicStructure_CodeMeaning",
    "illuminationType_CodeMeaning"
ORDER BY 
    occurrences DESC NULLS LAST;