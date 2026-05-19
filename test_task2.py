import subprocess
import os
import shutil
import stat

SANDBOX_DIR = "test_sandbox"
BINARY_NAME = "task2"

def rebuild():
    """Compiles the task2 binary using the Makefile."""
    print("[*] Rebuilding binary...")
    cmd = ['/bin/sh', '-c', 'make clean && make']
    process = subprocess.run(cmd, capture_output=True, text=True)
    if process.returncode != 0:
        print(f"[-] Compilation failed:\n{process.stderr}")
        return False
    if not os.path.exists(BINARY_NAME):
        print(f"[-] Compiled successfully, but '{BINARY_NAME}' binary was not found.")
        return False
    return True

def setup_sandbox():
    """Creates a pristine test directory populated with controlled target files."""
    if os.path.exists(SANDBOX_DIR):
        shutil.rmtree(SANDBOX_DIR)
    os.makedirs(SANDBOX_DIR)
    
    # Copy compiled binary into sandbox
    shutil.copy(BINARY_NAME, os.path.join(SANDBOX_DIR, BINARY_NAME))
    
    # Create target files with explicit content to track sizing differences later
    # Target files for 'v' prefix
    with open(os.path.join(SANDBOX_DIR, "v_target1.txt"), "wb") as f:
        f.write(b"Initial content of target 1\n")
    with open(os.path.join(SANDBOX_DIR, "v_target2.txt"), "wb") as f:
        f.write(b"Initial content of target 2\n")
        
    # Safe control files (should NOT be infected when using '-av')
    with open(os.path.join(SANDBOX_DIR, "safe_file.txt"), "wb") as f:
        f.write(b"This file should remain completely safe and untouched.\n")

def run_sandbox_binary(args):
    """Executes the binary inside the sandbox directory context."""
    cmd = ["./" + BINARY_NAME] + args
    process = subprocess.run(
        cmd,
        cwd=SANDBOX_DIR,
        capture_output=True,
        text=False # Keep raw bytes output
    )
    return process.stdout, process.stderr, process.returncode

def test_task2a_directory_listing():
    """Tests basic directory listing without flags (Task 2.A)."""
    print("\n--- Testing Task 2.A: Directory Listing ---")
    setup_sandbox()
    
    stdout, stderr, code = run_sandbox_binary([])
    output_str = stdout.decode('utf-8', errors='ignore')
    
    # Check if all files in the current sandbox directory are printed
    expected_files = ["v_target1.txt", "v_target2.txt", "safe_file.txt", BINARY_NAME]
    
    passed = True
    for filename in expected_files:
        if filename in output_str:
            print(f" [PASS] Found expected file in listing: {filename}")
        else:
            print(f" [FAIL] Missing file from listing: {filename}")
            passed = False
            
    if b"VIRUS ATTACHED" in stdout:
        print(" [FAIL] 'VIRUS ATTACHED' shown even when -a flag wasn't supplied.")
        passed = False
        
    return passed

def test_task2b_virus_attachment():
    """Tests infection criteria, printing updates, and sizing differences (Task 2.B)."""
    print("\n--- Testing Task 2.B: Virus Infection Mechanics ---")
    setup_sandbox()
    
    target1_path = os.path.join(SANDBOX_DIR, "v_target1.txt")
    target2_path = os.path.join(SANDBOX_DIR, "v_target2.txt")
    safe_path = os.path.join(SANDBOX_DIR, "safe_file.txt")
    
    # Capture initial file sizes
    size_t1_before = os.path.getsize(target1_path)
    size_t2_before = os.path.getsize(target2_path)
    size_safe_before = os.path.getsize(safe_path)
    
    # Execute the virus payload targeting files starting with 'v'
    stdout, stderr, code = run_sandbox_binary(["-av"])
    output_str = stdout.decode('utf-8', errors='ignore')
    
    passed = True
    
    # 1. Check outputs for confirmation messages
    if "v_target1.txt" in output_str and "VIRUS ATTACHED" in output_str:
        print(" [PASS] stdout correctly flagged 'v_target1.txt' with VIRUS ATTACHED.")
    else:
        print(" [FAIL] Failed to print 'VIRUS ATTACHED' warning side-by-side with 'v_target1.txt'.")
        passed = False

    # 2. Verify targeted file size expanded
    size_t1_after = os.path.getsize(target1_path)
    size_t2_after = os.path.getsize(target2_path)
    
    if size_t1_after > size_t1_before and size_t2_after > size_t2_before:
        print(f" [PASS] Targeted files grew in size. (v_target1: {size_t1_before} -> {size_t1_after} bytes)")
        
        # Verify both grew by the exact same size (size of code_start to code_end block)
        growth_t1 = size_t1_after - size_t1_before
        growth_t2 = size_t2_after - size_t2_before
        if growth_t1 == growth_t2:
            print(f" [PASS] Consistent virus injection size confirmed ({growth_t1} bytes attached).")
        else:
            print(f" [FAIL] Inconsistent growth detected! Target 1 grew by {growth_t1}, Target 2 by {growth_t2}.")
            passed = False
    else:
        print(" [FAIL] Targeted files did not grow. Assembly infector logic failed.")
        passed = False
        
    # 3. Verify control file remained un-mutated
    size_safe_after = os.path.getsize(safe_path)
    if size_safe_before == size_safe_after:
        print(" [PASS] Control file 'safe_file.txt' was successfully ignored.")
    else:
        print(" [FAIL] Virus spilled over! 'safe_file.txt' size was altered.")
        passed = False
        
    return passed

def test_error_termination_code():
    """Validates fallback mechanisms drop explicit exit statuses (0x55 / 85) on errors."""
    print("\n--- Testing Error Exit Codes (0x55) ---")
    setup_sandbox()
    
    # Remove all read/write permissions from the sandbox directory to force a sys_getdents/sys_open error
    os.chmod(SANDBOX_DIR, 0o000)
    
    try:
        # Run binary; expecting it to crash gracefully or fail accessing files
        cmd = ["./" + BINARY_NAME]
        process = subprocess.run(cmd, cwd=SANDBOX_DIR, capture_output=True, timeout=2)
        exit_code = process.returncode
    except Exception:
        exit_code = -1
    finally:
        # Instantly restore sandbox permissions to allow cleanup
        os.chmod(SANDBOX_DIR, 0o755)
        
    # 0x55 in decimal is 85
    if exit_code == 85 or exit_code == 0x55:
        print(" [PASS] Program terminated with expected exit code 0x55 (85) during an operational failure.")
        return True
    else:
        print(f" [FAIL] Expected exit code 85 (0x55), but got: {exit_code}")
        return False

def cleanup():
    """Removes temporary test frames."""
    if os.path.exists(SANDBOX_DIR):
        shutil.rmtree(SANDBOX_DIR)

if __name__ == "__main__":
    if rebuild():
        try:
            t2a = test_task2a_directory_listing()
            t2b = test_task2b_virus_attachment()
            err_code = test_error_termination_code()
            
            print("\n=== Final Test Summary ===")
            print(f"Task 2.A Directory Listing: {'PASSED' if t2a else 'FAILED'}")
            print(f"Task 2.B Virus Attachment : {'PASSED' if t2b else 'FAILED'}")
            print(f"Error Code Framework (0x55): {'PASSED' if err_code else 'FAILED'}")
            
        finally:
            cleanup()