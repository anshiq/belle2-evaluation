#!/usr/bin/env python3
"""
Belle II Evaluation Task - Comprehensive Test Suite
Tests that Python was built correctly with all dependencies
"""

import sys
import os

def test_header(msg):
    """Print a test section header"""
    print(f"\n{'='*60}")
    print(f"  {msg}")
    print('='*60)

def test_result(test_name, passed):
    """Print test result"""
    status = "✅ PASS" if passed else "❌ FAIL"
    print(f"{status} - {test_name}")
    return passed

def main():
    """Run all tests"""
    all_passed = True
    
    print("\n🧪 Belle II Build System - Comprehensive Test Suite\n")
    
    # Test 1: Python version
    test_header("Python Installation")
    version_info = f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}"
    print(f"Python version: {version_info}")
    all_passed &= test_result("Python installed", sys.version_info >= (3, 11))
    
    # Test 2: SQLite module
    test_header("SQLite Support")
    try:
        import sqlite3
        conn = sqlite3.connect(":memory:")
        cursor = conn.cursor()
        cursor.execute("CREATE TABLE test (id INTEGER, name TEXT)")
        cursor.execute("INSERT INTO test VALUES (1, 'Belle II')")
        result = cursor.execute("SELECT * FROM test").fetchone()
        conn.close()
        
        print(f"SQLite version: {sqlite3.sqlite_version}")
        print(f"Test query result: {result}")
        all_passed &= test_result("sqlite3 module", result == (1, 'Belle II'))
    except Exception as e:
        print(f"Error: {e}")
        all_passed &= test_result("sqlite3 module", False)
    
    # Test 3: LZMA/XZ support
    test_header("LZMA/XZ Compression Support")
    try:
        import lzma
        
        # Test compression
        original = b"Belle II is a particle physics experiment at KEK in Japan!"
        compressed = lzma.compress(original)
        decompressed = lzma.decompress(compressed)
        
        compression_ratio = len(original) / len(compressed)
        print(f"Original size: {len(original)} bytes")
        print(f"Compressed size: {len(compressed)} bytes")
        print(f"Compression ratio: {compression_ratio:.2f}x")
        print(f"Decompression successful: {decompressed == original}")
        
        all_passed &= test_result("lzma module", decompressed == original)
    except Exception as e:
        print(f"Error: {e}")
        all_passed &= test_result("lzma module", False)
    
    # Test 4: ctypes/libffi support
    test_header("FFI/ctypes Support")
    try:
        import ctypes
        
        # Test basic ctypes functionality
        libc = ctypes.CDLL(None)
        strlen = libc.strlen
        strlen.argtypes = [ctypes.c_char_p]
        strlen.restype = ctypes.c_size_t
        
        test_string = b"Hello Belle II"
        result = strlen(test_string)
        
        print(f"Test string: {test_string}")
        print(f"strlen result: {result}")
        print(f"Expected: {len(test_string)}")
        
        all_passed &= test_result("ctypes module", result == len(test_string))
    except Exception as e:
        print(f"Error: {e}")
        all_passed &= test_result("ctypes module", False)
    
    # Test 5: pip installation
    test_header("Package Manager (pip)")
    try:
        import pip
        print(f"pip version: {pip.__version__}")
        all_passed &= test_result("pip installed", True)
    except Exception as e:
        print(f"Error: {e}")
        all_passed &= test_result("pip installed", False)
    
    # Test 6: Standard library modules
    test_header("Standard Library Modules")
    critical_modules = [
        'json', 'os', 'sys', 'math', 'collections',
        'itertools', 'functools', 'pathlib', 'subprocess'
    ]
    
    for module in critical_modules:
        try:
            __import__(module)
            all_passed &= test_result(f"Module: {module}", True)
        except ImportError:
            all_passed &= test_result(f"Module: {module}", False)
    
    # Test 7: Library paths
    test_header("Library Path Configuration")
    prefix = os.path.dirname(os.path.dirname(sys.executable))
    print(f"Installation prefix: {prefix}")
    print(f"Python executable: {sys.executable}")
    print(f"Library paths:")
    
    import sysconfig
    lib_path = sysconfig.get_config_var('LIBDIR')
    print(f"  LIBDIR: {lib_path}")
    
    expected_in_prefix = prefix in str(lib_path)
    all_passed &= test_result("Libraries in prefix", expected_in_prefix)
    
    # Final summary
    test_header("Test Summary")
    if all_passed:
        print("\n🎉 ALL TESTS PASSED! 🎉")
        print("\nYour build system is working correctly.")
        print("Python is properly linked against:")
        print("  ✓ libffi (for ctypes)")
        print("  ✓ SQLite (for database support)")
        print("  ✓ XZ Utils (for LZMA compression)")
        print("\nThis demonstrates a successful prefix-based build!")
        return 0
    else:
        print("\n⚠️  SOME TESTS FAILED")
        print("\nPlease check the build process and ensure all dependencies")
        print("were correctly compiled and installed to the prefix.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
