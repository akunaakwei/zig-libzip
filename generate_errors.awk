# implements the logic of cmake/GenerateZipErrorStrings.cmake

BEGIN {
    err_str_count = 0
    err_details_count = 0
}

/#define ZIP_ER_([A-Z0-9_]+) ([0-9]+)[ \t]+\/([-*0-9a-zA-Z, ']*)\// {
    if (match($0, /#define ZIP_ER_[A-Z0-9_]+ [0-9]+[ \t]+\/\*?([-*0-9a-zA-Z, ']*)\*?\//)) {
        comment = substr($0, RSTART + index($0, "/*") + 2)
        comment = substr(comment, 1, index(comment, "*/") - 1)
        
        # Parse type and description from comment
        if (match(comment, /^([L|N|S|Z]+)[ \t]+([-0-9a-zA-Z, ']*)/)) {
            type = substr(comment, match(comment, /[L|N|S|Z]+/), RLENGTH)
            desc = substr(comment, RSTART + RLENGTH + 1)
            gsub(/^[ \t]+/, "", desc)
            gsub(/[ \t]+$/, "", desc)
            
            err_str[err_str_count, 0] = type
            err_str[err_str_count, 1] = desc
            err_str_count++
        }
    }
}

/#define ZIP_ER_([A-Z0-9_]+) ([0-9]+)[ \t]+\/([-*0-9a-zA-Z, ']*)\// {
    if (match($0, /#define ZIP_ER_[A-Z0-9_]+ [0-9]+[ \t]+\/\*?([-*0-9a-zA-Z, ']*)\*?\//)) {
        comment = substr($0, RSTART + index($0, "/*") + 2)
        comment = substr(comment, 1, index(comment, "*/") - 1)
        
        # Parse type and description from comment
        if (match(comment, /^([E|G]+)[ \t]+([-0-9a-zA-Z, ']*)/)) {
            type = substr(comment, match(comment, /[E|G]+/), RLENGTH)
            desc = substr(comment, RSTART + RLENGTH + 1)
            gsub(/^[ \t]+/, "", desc)
            gsub(/[ \t]+$/, "", desc)
            
            err_details[err_details_count, 0] = type
            err_details[err_details_count, 1] = desc
            err_details_count++
        }
    }
}



END {
    output = "/*\n"
    output = output "  This file was generated automatically by awk\n"
    output = output "  from zip.h and zipint.h; make changes there.\n"
    output = output "*/\n"
    output = output "\n"
    output = output "#include \"zipint.h\"\n"
    output = output "\n"
    output = output "#define L ZIP_ET_LIBZIP\n"
    output = output "#define N ZIP_ET_NONE\n"
    output = output "#define S ZIP_ET_SYS\n"
    output = output "#define Z ZIP_ET_ZLIB\n"
    output = output "\n"
    output = output "#define E ZIP_DETAIL_ET_ENTRY\n"
    output = output "#define G ZIP_DETAIL_ET_GLOBAL\n"
    output = output "\n"
    output = output "const struct _zip_err_info _zip_err_str[] = {\n"
    
    for (i = 0; i < err_str_count; i++) {
        output = output sprintf("    { %s, \"%s\" },\n", err_str[i, 0], err_str[i, 1])
    }
    
    output = output "};\n"
    output = output "\n"
    output = output "const int _zip_err_str_count = sizeof(_zip_err_str)/sizeof(_zip_err_str[0]);\n"
    output = output "\n"
    output = output "const struct _zip_err_info _zip_err_details[] = {\n"
    
    for (i = 0; i < err_details_count; i++) {
        output = output sprintf("    { %s, \"%s\" },\n", err_details[i, 0], err_details[i, 1])
    }
    
    output = output "};\n"
    output = output "\n"
    output = output "const int _zip_err_details_count = sizeof(_zip_err_details)/sizeof(_zip_err_details[0]);\n"
    
    print output
}