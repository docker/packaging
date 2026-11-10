// Copyright 2026 Docker Packaging authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Checks that Windows and macOS binaries only link libraries shipped with the
// OS. xx-verify --static only checks ELF binaries.
package main

import (
	"debug/macho"
	"debug/pe"
	"errors"
	"fmt"
	"os"
	"strings"
)

func main() {
	failed := false
	for _, name := range os.Args[1:] {
		libs, err := importedLibraries(name)
		if err != nil {
			fmt.Fprintf(os.Stderr, "%s: %v\n", name, err)
			os.Exit(1)
		}
		for _, lib := range libs {
			if !isSystemLibrary(lib) {
				fmt.Fprintf(os.Stderr, "%s: links non-system library %s\n", name, lib)
				failed = true
			}
		}
	}
	if failed {
		os.Exit(1)
	}
}

func importedLibraries(name string) ([]string, error) {
	if f, err := pe.Open(name); err == nil {
		defer f.Close()
		// pe.File.ImportedLibraries is unimplemented; symbols are "func:dll".
		syms, err := f.ImportedSymbols()
		if err != nil {
			return nil, err
		}
		var libs []string
		seen := map[string]bool{}
		for _, sym := range syms {
			lib := strings.ToLower(sym[strings.LastIndex(sym, ":")+1:])
			if !seen[lib] {
				seen[lib] = true
				libs = append(libs, lib)
			}
		}
		return libs, nil
	}
	if f, err := macho.Open(name); err == nil {
		defer f.Close()
		return f.ImportedLibraries()
	}
	return nil, errors.New("not a PE or Mach-O binary")
}

func isSystemLibrary(lib string) bool {
	if strings.HasPrefix(lib, "/") {
		return strings.HasPrefix(lib, "/usr/lib/") || strings.HasPrefix(lib, "/System/Library/")
	}
	switch lib {
	case "kernel32.dll", "ntdll.dll", "advapi32.dll", "ws2_32.dll", "msvcrt.dll", "ucrtbase.dll":
		return true
	}
	return strings.HasPrefix(lib, "api-ms-win-")
}
