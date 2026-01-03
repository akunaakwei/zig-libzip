const std = @import("std");
const AutoConfigHeaderStep = @import("autoconfigheader").AutoConfigHeaderStep;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const linkage = b.option(std.builtin.LinkMode, "linkage", "Linkage type for the library") orelse .static;
    const enable_fdopen = b.option(bool, "ENABLE_FDOPEN", "Enable zip_fdopen, which is not allowed in Microsoft CRT secure libraries") orelse true;

    const enable_bzip2 = b.option(bool, "ENABLE_BZIP2", "Enable use of BZip2") orelse true;
    const enable_lzma = b.option(bool, "ENABLE_LZMA", "Enable use of LZMA") orelse true;
    const enable_zstd = b.option(bool, "ENABLE_ZSTD", "Enable use of Zstandard") orelse true;

    const mawk_dep = b.dependency("mawk", .{
        .target = b.graph.host,
        .optimize = .ReleaseFast,
    });
    const mawk = mawk_dep.artifact("mawk");

    const zlib_ng_dep = b.dependency("zlib_ng", .{
        .target = target,
        .optimize = optimize,
        .linkage = .static,
        .ZLIB_COMPAT = true,
        .ZLIB_SYMBOL_PREFIX = "zng_",
    });
    const zlib_ng = zlib_ng_dep.artifact("zlib-ng");

    const bzip2_dep = dep: {
        if (enable_bzip2) {
            break :dep b.lazyDependency("bzip2", .{
                .target = target,
                .optimize = optimize,
            });
        }
        break :dep null;
    };
    const xz_dep = dep: {
        if (enable_lzma) {
            break :dep b.lazyDependency("xz", .{
                .target = target,
                .optimize = optimize,
            });
        }
        break :dep null;
    };
    const zstd_dep = dep: {
        if (enable_zstd) {
            break :dep b.lazyDependency("zstd", .{
                .target = target,
                .optimize = optimize,
            });
        }
        break :dep null;
    };

    const libzip_dep = b.dependency("libzip", .{});

    const generate_errors_cmd = b.addRunArtifact(mawk);
    generate_errors_cmd.addArg("-f");
    generate_errors_cmd.addFileArg(b.path("generate_errors.awk"));
    generate_errors_cmd.addFileArg(libzip_dep.path("lib/zip.h"));
    generate_errors_cmd.addFileArg(libzip_dep.path("lib/zipint.h"));
    const zip_err_str_c = generate_errors_cmd.captureStdOut();

    const config_step = AutoConfigHeaderStep.create(b, target, .{ .style = .{ .cmake = libzip_dep.path("config.h.in") } });
    config_step.config_header.addValues(.{
        .ENABLE_FDOPEN = enable_fdopen,
        .SIZEOF_OFF_T = 4,
        .SIZEOF_SIZE_T = 8,
        .CMAKE_PROJECT_NAME = "libzip",
        .CMAKE_PROJECT_VERSION = "1.11.4",
    });
    if (linkage == .dynamic) {
        config_step.config_header.addValue("HAVE_SHARED", void, {});
    }
    if (enable_bzip2) {
        config_step.config_header.addValue("HAVE_LIBBZ2", void, {});
    }
    if (enable_lzma) {
        config_step.config_header.addValue("HAVE_LIBLZMA", void, {});
    }
    if (enable_zstd) {
        config_step.config_header.addValue("HAVE_LIBZSTD", void, {});
    }

    config_step.addHaveFunction("HAVE___PROGNAME", "__progname", &.{});
    config_step.addHaveFunction("HAVE__CLOSE", "_close()", &.{"io.h"});
    config_step.addHaveFunction("HAVE__DUP", "_dup()", &.{"io.h"});
    config_step.addHaveFunction("HAVE__FDOPEN", "_fdopen(0, NULL)", &.{"stdio.h"});
    config_step.addHaveFunction("HAVE__FILENO", "_fileno(NULL)", &.{"stdio.h"});
    config_step.addHaveFunction("HAVE__FSEEKI64", "_fseeki64(NULL, 0, 0)", &.{"stdio.h"});
    config_step.addHaveFunction("HAVE__FSTAT64", "_fstat64(0, NULL)", &.{"stdio.h"});
    config_step.addHaveFunction("HAVE__FTELLI64", "_ftelli64(NULL)", &.{"stdio.h"});
    config_step.addHaveFunction("HAVE__SETMODE", "_setmode(0, 0)", &.{});
    config_step.addHaveFunction("HAVE__SNPRINTF", "_snprintf(NULL, 0, NULL)", &.{"stdio.h"});
    config_step.addHaveFunction("HAVE__SNPRINTF_S", "_snprintf_s(NULL, 0, 0, NULL)", &.{"stdio.h"});
    config_step.addHaveFunction("HAVE__SNWPRINTF_S", "_snwprintf_s(NULL, 0, 0, NULL)", &.{"stdio.h"});
    config_step.addHaveFunction("HAVE__STAT64", "_stat64(NULL, NULL)", &.{ "sys/types.h", "sys/stat.h" });
    config_step.addHaveFunction("HAVE__STRDUP", "_strdup(NULL)", &.{"string.h"});
    config_step.addHaveFunction("HAVE__STRICMP", "_stricmp(NULL, NULL)", &.{"sting.h"});
    config_step.addHaveFunction("HAVE__STRTOI64", "_strtoi64()", &.{"string.h"});
    config_step.addHaveFunction("HAVE__STRTOUI64", "_strtoui64()", &.{"string.h"});
    config_step.addHaveFunction("HAVE__UNLINK", "_unlink(NULL)", &.{ "io.h", "stdio.h" });
    config_step.addHaveFunction("HAVE_ARC4RANDOM", "arc4random()", &.{"stdlib.h"});
    config_step.addHaveFunction("HAVE_CLONEFILE", "clonefile(NULL, NULL, 0)", &.{ "sys/attr.h", "sys/clonefile.h" });
    config_step.addHaveFunction("HAVE_FICLONERANGE", "FICLONERANGE", &.{"linux/fs.h"});
    config_step.addHaveFunction("HAVE_FILENO", "fileno(NULL)", &.{"stdio.h"});
    config_step.addHaveFunction("HAVE_FCHMOD", "fchmod(0, 0)", &.{"sys/stat.h"});
    config_step.addHaveFunction("HAVE_FSEEKO", "fseeko(NULL, 0, 0)", &.{"stdio.h"});
    config_step.addHaveFunction("HAVE_FTELLO", "ftello(NULL)", &.{"stdio.h"});
    config_step.addHaveFunction("HAVE_GETPROGNAME", "getprogname()", &.{"stdlib.h"});
    config_step.addHaveFunction("HAVE_GETSECURITYINFO", "GetSecurityInfo(NULL, 0, 0)", &.{"aclapi.h"});
    config_step.addHaveFunction("HAVE_LOCALTIME_R", "localtime_r(NULL, NULL)", &.{"time.h"});
    config_step.addHaveFunction("HAVE_LOCALTIME_S", "localtime_s(NULL, NULL)", &.{"time.h"});
    config_step.addHaveFunction("HAVE_MEMCPY_S", "memcpy_s(NULL, 0, NULL, 0)", &.{"memory.h"});
    config_step.addHaveFunction("HAVE_MKSTEMP", "mkstemp(NULL)", &.{"stdlib.h"});
    config_step.addHaveFunction("HAVE_SETMODE", "setmode(NULL)", &.{"unistd.h"});
    config_step.addHaveFunction("HAVE_SNPRINTF", "snprintf(NULL, 0, NULL)", &.{"stdio.h"});
    config_step.addHaveFunction("HAVE_SNPRINTF_S", "snprintf_s(NULL, 0, NULL)", &.{"stdio.h"});
    config_step.addHaveFunction("HAVE_STRCASECMP", "strcasecmp(NULL, NULL)", &.{"strings.h"});
    config_step.addHaveFunction("HAVE_STRDUP", "strdup(NULL)", &.{"string.h"});
    config_step.addHaveFunction("HAVE_STRERROR_S", "strerror_s(NULL, 0, 0)", &.{"string.h"});
    config_step.addHaveFunction("HAVE_STRERRORLEN_S", "strerrorlen_s(NULL)", &.{"string.h"});
    config_step.addHaveFunction("HAVE_STRICMP", "stricmp()", &.{});
    config_step.addHaveFunction("HAVE_STRNCPY_S", "strncpy_s()", &.{});
    config_step.addHaveFunction("HAVE_STRTOLL", "strtoll()", &.{});
    config_step.addHaveFunction("HAVE_STRTOULL", "strtoull()", &.{});
    config_step.addHaveFunction("HAVE_STRUCT_TM_TM_ZONE", "struct_tm_tm_zone()", &.{});
    config_step.addHaveHeader("HAVE_STDBOOL_H", "stdbool.h");
    config_step.addHaveHeader("HAVE_STRINGS_H", "strings.h");
    config_step.addHaveHeader("HAVE_UNISTD_H", "unistd.h");
    config_step.addHaveHeader("HAVE_DIRENT_H", "dirent.h");
    config_step.addHaveHeader("HAVE_FTS_H", "fts.h");
    config_step.addHaveHeader("HAVE_NDIR_H", "ndir.h");
    config_step.addHaveHeader("HAVE_SYS_DIR_H", "sys/dir.h");
    config_step.addHaveHeader("HAVE_SYS_NDIR_H", "sys/ndir.h");
    const config_h = config_step.config_header;

    const zipconf_h = b.addConfigHeader(.{
        .style = .{ .cmake = libzip_dep.path("zipconf.h.in") },
    }, .{
        .libzip_VERSION = .@"1.11.4",
        .libzip_VERSION_MAJOR = 1,
        .libzip_VERSION_MINOR = 11,
        .libzip_VERSION_PATCH = 4,
        .ZIP_STATIC = linkage == .static,
        .LIBZIP_TYPES_INCLUDE = .@"#include <stdint.h>",
        .ZIP_INT8_T = .int8_t,
        .ZIP_UINT8_T = .uint8_t,
        .ZIP_INT16_T = .int16_t,
        .ZIP_UINT16_T = .uint16_t,
        .ZIP_INT32_T = .int32_t,
        .ZIP_UINT32_T = .uint32_t,
        .ZIP_INT64_T = .int64_t,
        .ZIP_UINT64_T = .uint64_t,
    });

    const flags = .{"-DWIN32_LEAN_AND_MEAN"};

    const zip = b.addLibrary(.{
        .name = "zip",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
        .linkage = linkage,
    });
    zip.root_module.addIncludePath(libzip_dep.path("lib"));
    zip.linkLibrary(zlib_ng);
    zip.addConfigHeader(config_h);
    zip.addConfigHeader(zipconf_h);
    zip.addCSourceFiles(.{
        .root = libzip_dep.path("lib"),
        .files = &zip_sources,
        .flags = &flags,
    });
    if (target.result.os.tag == .windows) {
        zip.linkSystemLibrary("advapi32");
        zip.addCSourceFiles(.{
            .root = libzip_dep.path("lib"),
            .files = &.{
                "zip_source_file_win32.c",
                "zip_source_file_win32_named.c",
                "zip_source_file_win32_utf16.c",
                "zip_source_file_win32_utf8.c",
                "zip_source_file_win32_ansi.c",
                "zip_random_win32.c",
            },
            .flags = &flags,
        });
    } else {
        zip.addCSourceFiles(.{
            .root = libzip_dep.path("lib"),
            .files = &.{
                "zip_source_file_stdio_named.c",
                "zip_random_unix.c",
            },
            .flags = &flags,
        });
    }
    zip.addCSourceFile(.{ .file = zip_err_str_c, .language = .c });
    if (bzip2_dep) |dep| {
        zip.linkLibrary(dep.artifact("bz2"));
        zip.addCSourceFiles(.{
            .root = libzip_dep.path("lib"),
            .files = &.{
                "zip_algorithm_bzip2.c",
            },
            .flags = &flags,
        });
    }
    if (xz_dep) |dep| {
        zip.linkLibrary(dep.artifact("lzma"));
        zip.addCSourceFiles(.{
            .root = libzip_dep.path("lib"),
            .files = &.{
                "zip_algorithm_xz.c",
            },
            .flags = &flags,
        });
    }
    if (zstd_dep) |dep| {
        zip.linkLibrary(dep.artifact("zstd"));
        zip.addCSourceFiles(.{
            .root = libzip_dep.path("lib"),
            .files = &.{
                "zip_algorithm_zstd.c",
            },
            .flags = &flags,
        });
    }

    b.installArtifact(zip);

    const zipcmp = b.addExecutable(.{
        .name = "zipcmp",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    zipcmp.root_module.linkLibrary(zip);
    zipcmp.root_module.linkLibrary(zlib_ng);
    zipcmp.root_module.addConfigHeader(config_h);
    zipcmp.root_module.addConfigHeader(zipconf_h);
    zipcmp.root_module.addIncludePath(libzip_dep.path("lib"));
    zipcmp.addCSourceFiles(.{
        .root = libzip_dep.path("src"),
        .files = &zipcmp_sources,
        .flags = &flags,
    });
    b.installArtifact(zipcmp);

    const zipmerge = b.addExecutable(.{
        .name = "zipmerge",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    zipmerge.root_module.linkLibrary(zip);
    zipmerge.root_module.linkLibrary(zlib_ng);
    zipmerge.root_module.addConfigHeader(config_h);
    zipmerge.root_module.addConfigHeader(zipconf_h);
    zipmerge.root_module.addIncludePath(libzip_dep.path("lib"));
    zipmerge.addCSourceFiles(.{
        .root = libzip_dep.path("src"),
        .files = &zipmerge_sources,
        .flags = &(flags ++ .{"-includeinttypes.h"}),
    });
    b.installArtifact(zipmerge);

    const ziptool = b.addExecutable(.{
        .name = "ziptool",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    ziptool.root_module.linkLibrary(zip);
    ziptool.root_module.linkLibrary(zlib_ng);
    ziptool.root_module.addConfigHeader(config_h);
    ziptool.root_module.addConfigHeader(zipconf_h);
    ziptool.root_module.addIncludePath(libzip_dep.path("lib"));
    ziptool.addCSourceFiles(.{
        .root = libzip_dep.path("src"),
        .files = &ziptool_sources,
        .flags = &(flags ++ .{"-includeinttypes.h"}),
    });
    b.installArtifact(ziptool);
}

const zip_sources = .{
    "zip_add.c",
    "zip_add_dir.c",
    "zip_add_entry.c",
    "zip_algorithm_deflate.c",
    "zip_buffer.c",
    "zip_close.c",
    "zip_delete.c",
    "zip_dir_add.c",
    "zip_dirent.c",
    "zip_discard.c",
    "zip_entry.c",
    "zip_error.c",
    "zip_error_clear.c",
    "zip_error_get.c",
    "zip_error_get_sys_type.c",
    "zip_error_strerror.c",
    "zip_error_to_str.c",
    "zip_extra_field.c",
    "zip_extra_field_api.c",
    "zip_fclose.c",
    "zip_fdopen.c",
    "zip_file_add.c",
    "zip_file_error_clear.c",
    "zip_file_error_get.c",
    "zip_file_get_comment.c",
    "zip_file_get_external_attributes.c",
    "zip_file_get_offset.c",
    "zip_file_rename.c",
    "zip_file_replace.c",
    "zip_file_set_comment.c",
    "zip_file_set_encryption.c",
    "zip_file_set_external_attributes.c",
    "zip_file_set_mtime.c",
    "zip_file_strerror.c",
    "zip_fopen.c",
    "zip_fopen_encrypted.c",
    "zip_fopen_index.c",
    "zip_fopen_index_encrypted.c",
    "zip_fread.c",
    "zip_fseek.c",
    "zip_ftell.c",
    "zip_get_archive_comment.c",
    "zip_get_archive_flag.c",
    "zip_get_encryption_implementation.c",
    "zip_get_file_comment.c",
    "zip_get_name.c",
    "zip_get_num_entries.c",
    "zip_get_num_files.c",
    "zip_hash.c",
    "zip_io_util.c",
    "zip_libzip_version.c",
    "zip_memdup.c",
    "zip_name_locate.c",
    "zip_new.c",
    "zip_open.c",
    "zip_pkware.c",
    "zip_progress.c",
    "zip_realloc.c",
    "zip_rename.c",
    "zip_replace.c",
    "zip_set_archive_comment.c",
    "zip_set_archive_flag.c",
    "zip_set_default_password.c",
    "zip_set_file_comment.c",
    "zip_set_file_compression.c",
    "zip_set_name.c",
    "zip_source_accept_empty.c",
    "zip_source_begin_write.c",
    "zip_source_begin_write_cloning.c",
    "zip_source_buffer.c",
    "zip_source_call.c",
    "zip_source_close.c",
    "zip_source_commit_write.c",
    "zip_source_compress.c",
    "zip_source_crc.c",
    "zip_source_error.c",
    "zip_source_file_common.c",
    "zip_source_file_stdio.c",
    "zip_source_free.c",
    "zip_source_function.c",
    "zip_source_get_dostime.c",
    "zip_source_get_file_attributes.c",
    "zip_source_is_deleted.c",
    "zip_source_layered.c",
    "zip_source_open.c",
    "zip_source_pass_to_lower_layer.c",
    "zip_source_pkware_decode.c",
    "zip_source_pkware_encode.c",
    "zip_source_read.c",
    "zip_source_remove.c",
    "zip_source_rollback_write.c",
    "zip_source_seek.c",
    "zip_source_seek_write.c",
    "zip_source_stat.c",
    "zip_source_supports.c",
    "zip_source_tell.c",
    "zip_source_tell_write.c",
    "zip_source_window.c",
    "zip_source_write.c",
    "zip_source_zip.c",
    "zip_source_zip_new.c",
    "zip_stat.c",
    "zip_stat_index.c",
    "zip_stat_init.c",
    "zip_strerror.c",
    "zip_string.c",
    "zip_unchange.c",
    "zip_unchange_all.c",
    "zip_unchange_archive.c",
    "zip_unchange_data.c",
    "zip_utf-8.c",
};

const zipcmp_sources = .{
    "zipcmp.c",
    "diff_output.c",
};

const zipmerge_sources = .{
    "zipmerge.c",
};

const ziptool_sources = .{
    "ziptool.c",
};
